Lifecycle of a Balancer V3 Pool
This document explains the lifecycle of registering, initializing, swapping, depositing, and withdrawing from a pool in the Balancer V3 protocol, based on the provided VaultExtension contract and related components. It details when hook and pool functions are called and how hooks and pools can interact with the Vault to take or provide tokens for custom operations.

1. Pool Registration
Process

Function: registerPool in VaultExtension
Caller: Typically a factory contract via the Router
Steps:
Validation:
Checks if the pool is not already registered.
Ensures token count is between _MIN_TOKENS and _MAX_TOKENS.
Validates token addresses (non-zero, not the pool address) and ensures they are sorted and unique.


Token Configuration:
Configures each token’s TokenInfo (type, rate provider, yield fee flag).
Calculates decimal differences for scaling (stored as diffs from _MAX_TOKEN_DECIMALS).


Role Accounts:
Stores role accounts (e.g., pause manager, pool creator) in _poolRoleAccounts.


Configuration:
Sets initial PoolConfigBits, including swap fee, pause window, and liquidity management flags.
If a hook contract is provided, validates and configures it.


Fee Setup:
Sets the static swap fee percentage within bounds.


Event Emission:
Emits PoolRegistered with pool details.





Hook Functions Called

onRegister (on the hook contract, if provided):
Called during registration to validate the pool setup.
Can reject registration by returning false.



Pool Functions Called

None directly; the pool is only configured and validated.

Token Interactions

No token movements occur during registration; balances are initialized to zero.


2. Pool Initialization
Process

Function: initialize in VaultExtension
Caller: Typically the Router
Steps:
Validation:
Ensures the pool is registered, not paused, and not already initialized.


Before Hook:
Calls onBeforeInitialize if enabled.


Token Balances:
Takes debt for exact amounts in via _takeDebt.
Sets initial raw and live balances in _poolTokenBalances.


Configuration Update:
Marks the pool as initialized in PoolConfigBits.


Invariant Calculation:
Calls computeInvariant on the pool to calculate the initial invariant.


BPT Minting:
Mints BPT tokens (minimum supply enforced), sending them to the specified recipient.


After Hook:
Calls onAfterInitialize if enabled.


Event Emission:
Emits LiquidityAdded and PoolInitialized.





Hook Functions Called

onBeforeInitialize (if shouldCallBeforeInitialize is true):
Validates or modifies input amounts before initialization.


onAfterInitialize (if shouldCallAfterInitialize is true):
Performs post-initialization actions or validations.



Pool Functions Called

computeInvariant:
Called on the pool to compute the initial invariant based on scaled balances.



Token Interactions

Tokens are taken from the Vault via _takeDebt to set initial pool balances.
No custom token provision occurs unless hooks use sendTo/settle (e.g., to convert tokens externally).


3. Swapping
Process

Function: swap in Vault (not directly in VaultExtension, but part of the lifecycle)
Caller: Typically the Router
Steps:
Validation:
Ensures the Vault is unlocked and the pool isn’t paused.
Validates non-zero amounts and distinct tokens.


Before Hook:
Calls onBeforeSwap if enabled.


Fee Calculation:
Calls onComputeDynamicSwapFeePercentage if dynamic fees are enabled.


Swap Execution



