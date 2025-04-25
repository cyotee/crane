# Lifecycle of a Balancer V3 Pool

This document explains the lifecycle of registering, initializing, swapping, depositing, and withdrawing from a pool in the Balancer V3 protocol, based on the provided VaultExtension contract and related components. It details when hook and pool functions are called and how hooks and pools can interact with the Vault to take or provide tokens for custom operations.

## 1. Pool Registration

### Process

**Function:** `registerPool` in VaultExtension  
**Caller:** Typically a factory contract via the Router

#### Steps:

##### Validation:
- Checks if the pool is not already registered
- Ensures token count is between `_MIN_TOKENS` and `_MAX_TOKENS`
- Validates token addresses (non-zero, not the pool address) and ensures they are sorted and unique

##### Token Configuration:
- Configures each token's `TokenInfo` (type, rate provider, yield fee flag)
- Calculates decimal differences for scaling (stored as diffs from `_MAX_TOKEN_DECIMALS`)

##### Role Accounts:
- Stores role accounts (e.g., pause manager, pool creator) in `_poolRoleAccounts`

##### Configuration:
- Sets initial `PoolConfigBits`, including swap fee, pause window, and liquidity management flags
- If a hook contract is provided, validates and configures it

##### Fee Setup:
- Sets the static swap fee percentage within bounds

##### Event Emission:
- Emits `PoolRegistered` with pool details

### Hook Functions Called

**`onRegister`** (on the hook contract, if provided):
- Called during registration to validate the pool setup
- Can reject registration by returning false

### Pool Functions Called
None directly; the pool is only configured and validated.

### Token Interactions
No token movements occur during registration; balances are initialized to zero.

## 2. Pool Initialization

### Process

**Function:** `initialize` in VaultExtension  
**Caller:** Typically the Router

#### Steps:

##### Validation:
- Ensures the pool is registered, not paused, and not already initialized

##### Before Hook:
- Calls `onBeforeInitialize` if enabled

##### Token Balances:
- Takes debt for exact amounts in via `_takeDebt`
- Sets initial raw and live balances in `_poolTokenBalances`

##### Configuration Update:
- Marks the pool as initialized in `PoolConfigBits`

##### Invariant Calculation:
- Calls `computeInvariant` on the pool to calculate the initial invariant

##### BPT Minting:
- Mints BPT tokens (minimum supply enforced), sending them to the specified recipient

##### After Hook:
- Calls `onAfterInitialize` if enabled

##### Event Emission:
- Emits `LiquidityAdded` and `PoolInitialized`

### Hook Functions Called

**`onBeforeInitialize`** (if `shouldCallBeforeInitialize` is true):
- Validates or modifies input amounts before initialization

**`onAfterInitialize`** (if `shouldCallAfterInitialize` is true):
- Performs post-initialization actions or validations

### Pool Functions Called

**`computeInvariant`**:
- Called on the pool to compute the initial invariant based on scaled balances

### Token Interactions
- Tokens are taken from the Vault via `_takeDebt` to set initial pool balances
- No custom token provision occurs unless hooks use `sendTo`/`settle` (e.g., to convert tokens externally)

## 3. Swapping

### Process

**Function:** `swap` in Vault (not directly in VaultExtension, but part of the lifecycle)  
**Caller:** Typically the Router

#### Steps:

##### Validation:
- Ensures the Vault is unlocked and the pool isn't paused
- Validates non-zero amounts and distinct tokens

##### Before Hook:
- Calls `onBeforeSwap` if enabled

##### Fee Calculation:
- Calls `onComputeDynamicSwapFeePercentage` if dynamic fees are enabled

##### Swap Execution:
- Calls `onSwap` on the pool to compute the output amount
- Updates token deltas (debt/credit) and pool balances
- Charges and records fees

##### After Hook:
- Calls `onAfterSwap` if enabled, allowing result adjustments

##### Event Emission:
- Emits `Swap` with trade details

### Hook Functions Called

**`onBeforeSwap`** (if `shouldCallBeforeSwap` is true):
- Validates or modifies swap parameters

**`onComputeDynamicSwapFeePercentage`** (if `shouldCallComputeDynamicSwapFee` is true):
- Computes a dynamic swap fee percentage

**`onAfterSwap`** (if `shouldCallAfterSwap` is true):
- Adjusts the swap result (e.g., for fees or custom logic)

### Pool Functions Called

**`onSwap`**:
- Called on the pool to compute the swap output based on its logic

### Token Interactions
- **Taking Tokens:** Hooks can use `sendTo` to transfer tokens from the Vault to external contracts (e.g., for routing swaps through another protocol)
- **Providing Tokens:** Hooks can use `settle` to credit different tokens back to the Vault after external operations
- **Example:** A hook could send token A to a DEX, swap it for token B, and settle token B back to the Vault

## 4. Depositing (Adding Liquidity)

### Process

**Function:** `addLiquidity` in Vault (not directly in VaultExtension, but part of the lifecycle)  
**Caller:** Typically the Router

#### Steps:

##### Validation:
- Ensures the Vault is unlocked and the pool isn't paused

##### Before Hook:
- Calls `onBeforeAddLiquidity` if enabled

##### Liquidity Calculation:
- Computes amounts in and BPT out (proportional or unbalanced)
- Calls `onAddLiquidityCustom` for custom kinds

##### Token Handling:
- Takes debt for input tokens via `_takeDebt`
- Updates pool balances

##### BPT Minting:
- Mints BPT tokens to the recipient

##### After Hook:
- Calls `onAfterAddLiquidity` if enabled, allowing adjustments

##### Event Emission:
- Emits `LiquidityAdded`

### Hook Functions Called

**`onBeforeAddLiquidity`** (if `shouldCallBeforeAddLiquidity` is true):
- Validates or modifies input amounts

**`onAfterAddLiquidity`** (if `shouldCallAfterAddLiquidity` is true):
- Adjusts final amounts in (e.g., for fees or incentives)

### Pool Functions Called

**`onAddLiquidityCustom`** (if `enableAddLiquidityCustom` is true):
- Computes amounts in and BPT out for custom liquidity kinds

### Token Interactions
- **Taking Tokens:** Hooks can use `sendTo` to transfer input tokens to external contracts (e.g., to convert them before depositing)
- **Providing Tokens:** Hooks can use `settle` to credit different tokens back to the Vault
- **Example:** A hook could convert an input token to an LP token and settle it into the pool

## 5. Withdrawing (Removing Liquidity)

### Process

**Function:** `removeLiquidity` in Vault (not directly in VaultExtension, but part of the lifecycle)  
**Caller:** Typically the Router

#### Steps:

##### Validation:
- Ensures the Vault is unlocked and the pool isn't paused

##### Before Hook:
- Calls `onBeforeRemoveLiquidity` if enabled

##### Liquidity Calculation:
- Computes BPT in and amounts out
- Calls `onRemoveLiquidityCustom` for custom kinds

##### Token Handling:
- Supplies credit for output tokens via `_supplyCredit`
- Updates pool balances

##### BPT Burning:
- Burns BPT tokens from the sender

##### After Hook:
- Calls `onAfterRemoveLiquidity` if enabled, allowing adjustments

##### Event Emission:
- Emits `LiquidityRemoved`

### Hook Functions Called

**`onBeforeRemoveLiquidity`** (if `shouldCallBeforeRemoveLiquidity` is true):
- Validates or modifies inputs

**`onAfterRemoveLiquidity`** (if `shouldCallAfterRemoveLiquidity` is true):
- Adjusts final amounts out

### Pool Functions Called

**`onRemoveLiquidityCustom`** (if `enableRemoveLiquidityCustom` is true):
- Computes BPT in and amounts out for custom kinds

### Token Interactions
- **Taking Tokens:** Hooks can use `sendTo` to transfer output tokens to external contracts (e.g., to convert them after withdrawal)
- **Providing Tokens:** Hooks can use `settle` to credit different tokens back to the Vault
- **Example:** A hook could convert withdrawn tokens to another asset and settle it for the user

## Hook and Pool Token Interactions

Hooks and pools can interact with the Vault to support custom operations:

- **Taking Tokens:** Via `sendTo`, transferring tokens from the Vault to external contracts for operations like swapping or converting
- **Providing Tokens:** Via `settle`, crediting tokens back to the Vault after external processing
- **Adjusting Operations:** Hooks can modify amounts in `onAfter*` functions to implement fees, incentives, or custom logic

### Example Scenarios

- **Swap Routing:** A hook sends a token to an external DEX via `sendTo`, swaps it, and settles the output token back
- **Liquidity Conversion:** A pool's `onAddLiquidityCustom` converts input tokens to LP tokens before settling them into the pool

This mechanism ensures flexibility while keeping token handling secure within the Vault.

## Summary

1. **Registration:** Configures the pool with hook validation (`onRegister`)
2. **Initialization:** Sets initial liquidity with hooks (`onBeforeInitialize`, `onAfterInitialize`) and pool invariant calculation (`computeInvariant`)
3. **Swapping:** Executes trades with hooks (`onBeforeSwap`, `onComputeDynamicSwapFeePercentage`, `onAfterSwap`) and pool logic (`onSwap`), supporting custom token routing
4. **Depositing:** Adds liquidity with hooks (`onBeforeAddLiquidity`, `onAfterAddLiquidity`) and custom pool logic (`onAddLiquidityCustom`), enabling token conversion
5. **Withdrawing:** Removes liquidity with hooks (`onBeforeRemoveLiquidity`, `onAfterRemoveLiquidity`) and custom pool logic (`onRemoveLiquidityCustom`), allowing token adjustments

The Balancer V3 protocol leverages hooks and pool functions to provide a secure, extensible framework for pool operations. 🔄
