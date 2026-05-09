# Euler V1 Lifecycle In Crane

This note explains the main lifecycle surfaces in the Euler v1 code attached in this tree, with emphasis on:

- how the core lending vault works
- where tokens actually move
- how EVC frames and validates execution
- how Euler Earn and Euler Swap extend the system
- how liquidation and unhealthy-path settlement work

The attached directory contains several distinct systems. The word "vault" is overloaded, so this note names the layer explicitly each time:

- `EVault` is the core lending vault
- `EVC` is the Ethereum Vault Connector that authenticates and defers checks
- `Euler Earn` is an allocator vault-of-vaults
- `Euler Swap` is a swap/liquidity surface backed by Euler vaults

The main code paths are:

- `contracts/protocols/lending/euler/v1/vault/EVault/EVault.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/Dispatch.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/modules/Vault.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/modules/Borrowing.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/modules/Liquidation.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/modules/RiskManager.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/shared/Base.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/shared/AssetTransfers.sol`
- `contracts/protocols/lending/euler/v1/vault/EVault/shared/LiquidityUtils.sol`
- `contracts/protocols/lending/euler/v1/evc/EthereumVaultConnector.sol`
- `contracts/protocols/lending/euler/v1/evc/TransientStorage.sol`
- `contracts/protocols/lending/euler/v1/euler-earn/EulerEarn.sol`
- `contracts/protocols/lending/euler/v1/euler-swap/EulerSwap.sol`
- `contracts/protocols/lending/euler/v1/euler-swap/EulerSwapPeriphery.sol`
- `contracts/protocols/lending/euler/v1/euler-swap/libraries/SwapLib.sol`
- `contracts/protocols/lending/euler/v1/euler-swap/libraries/FundsLib.sol`
- `contracts/protocols/lending/euler/v1/euler-swap/UniswapHook.sol`
- `contracts/protocols/lending/euler/v1/oracle/EulerRouter.sol`

## 1. Core Mental Model

Euler v1 here is not one monolithic contract. It is a composition of:

1. a lending vault system that owns cash, shares, and debt accounting
2. an execution connector that authenticates callers and defers health checks
3. optional allocator and swap layers that route assets into other vaults

The most important distinction is:

- ERC20 custody and balance changes happen in the lending vault, allocator vault, or swap surface
- authentication, `onBehalfOf` execution, deferred account checks, and deferred vault checks happen in EVC

So the system is best understood as:

1. perform an operation against a vault or swap surface
2. update local accounting and move tokens where necessary
3. let EVC run the deferred account and vault validations before the execution frame closes

Unlike the Balancer v3 and Uniswap v4 notes, this system is not primarily a transient token-delta engine. The transient part here is the execution and validation frame maintained by EVC.

## 2. EVault: The Core Lending Lifecycle

### 2.1 EVault is a router over modules

`EVault.sol` is mostly an entry surface. `Dispatch.sol` wires the public methods to module contracts with `use(MODULE_...)`, and the state-changing methods that require status checks are wrapped with `callThroughEVC()`.

That means a call such as:

- `deposit`
- `withdraw`
- `borrow`
- `repay`
- `liquidate`

is normally forced through EVC first, then routed to the corresponding module by delegatecall.

This is the core healthy-path pattern:

1. user calls EVault
2. EVault forwards through EVC when required
3. module logic executes
4. EVC restores context and runs deferred checks

### 2.2 Every core operation starts with `initOperation`

The EVault modules rely on `Base.initOperation(...)`.

That function does several important things up front:

- updates the vault cache and interest state
- authenticates through EVC
- optionally calls a configured hook
- queues account or vault status checks in EVC
- captures a snapshot when cap enforcement needs one

So `initOperation` is the operational boundary between:

- local vault accounting and token movement
- deferred system-wide health validation

### 2.3 Deposit and mint lifecycle

The healthy-path supply entrypoints are in `Vault.sol`:

- `deposit(uint256 amount, address receiver)`
- `mint(uint256 amount, address receiver)`

The lifecycle is:

1. `initOperation(OP_DEPOSIT, CHECKACCOUNT_NONE)` or `initOperation(OP_MINT, CHECKACCOUNT_NONE)`
2. compute asset and share amounts using the current vault cache
3. reject zero-share outcomes
4. `finalizeDeposit(...)`
5. `pullAssets(...)` transfers the underlying token into the EVault
6. vault cash increases and the receiver's share balance increases

Real token movement happens in `AssetTransfers.pullAssets(...)`:

- `safeTransferFrom(from, address(this), amount, permit2)`
- increment `vaultStorage.cash`

So deposits are not abstract accounting only. The asset is actually transferred into EVault custody at deposit time.

### 2.4 Withdraw and redeem lifecycle

The healthy-path withdrawal entrypoints are:

- `withdraw(uint256 amount, address receiver, address owner)`
- `redeem(uint256 amount, address receiver, address owner)`

The lifecycle is:

1. `initOperation(OP_WITHDRAW, owner)` or `initOperation(OP_REDEEM, owner)`
2. compute the share burn and asset output
3. require sufficient cash
4. consume allowance if caller is not owner
5. decrease user share balance
6. `pushAssets(...)` sends the underlying token to the receiver

Real token movement happens in `AssetTransfers.pushAssets(...)`:

- validate the receiver
- decrement `vaultStorage.cash`
- `safeTransfer(to, amount)`

So on the supply side, EVault is a conventional custody vault: real assets come in on deposit and go out on withdrawal.

### 2.5 Borrow lifecycle

The borrow path is in `Borrowing.sol`:

- `borrow(uint256 amount, address receiver)`

The lifecycle is:

1. `initOperation(OP_BORROW, CHECKACCOUNT_CALLER)`
2. bound the borrow amount by current `cash`
3. require enough available cash
4. increase the caller's borrow state
5. `pushAssets(...)` transfers the underlying token to the receiver

This is an important pattern: debt accounting is updated before the user receives assets, but the final delivery is still a real ERC20 transfer out of the vault.

### 2.6 Repay lifecycle

The repay path is also in `Borrowing.sol`:

- `repay(uint256 amount, address receiver)`
- `repayWithShares(uint256 amount, address receiver)`

`repay(...)` does:

1. `initOperation(OP_REPAY, CHECKACCOUNT_NONE)`
2. compute current owed amount
3. `pullAssets(...)` transfers underlying tokens into the vault
4. decrease borrow state for `receiver`

`repayWithShares(...)` is different:

- it burns eToken-side balance
- decreases dToken-side debt
- no underlying ERC20 transfer is required because the repayment is internalized against the account's vault shares

### 2.7 Flash loan lifecycle

The flash loan path is simpler and self-contained:

- authenticate caller
- optionally call the configured hook for flash loans
- record the original asset balance
- transfer assets to borrower
- call `onFlashLoan(data)` on the borrower
- require the post-callback balance to be at least the original balance

So flash loans are not framed by the same deferred debt lifecycle as borrow/repay. They are enforced by a direct post-balance check.

## 3. EVC: Execution Framing And Deferred Checks

### 3.1 What EVC actually does

`EthereumVaultConnector.sol` is not the custody vault. It is the authenticated execution layer.

Its main jobs are:

- authenticate owners, operators, and `onBehalfOf` accounts
- manage enabled controllers and collaterals
- defer account and vault checks during a controlled execution frame
- restore context and run those checks afterward

The most important implication is:

- EVault moves tokens and updates cash / shares / debt
- EVC decides whether the operation is allowed to complete once all deferred checks are evaluated

### 3.2 Deferred checks are transaction-scoped

`TransientStorage.sol` exposes the best mental model for EVC internals.

It stores transaction-scoped working sets such as:

- `executionContext`
- pending account status checks
- pending vault status checks

This is the real transient layer in Euler v1.

The pattern is:

1. EVault operation begins
2. EVC marks checks as deferred
3. the operation updates balances, debt, or collateral state
4. EVC restores execution context and runs the queued validations

### 3.3 What gets checked after the operation

The core validation surfaces are:

- account status checks through `RiskManager.checkAccountStatus`
- vault status checks through `RiskManager.checkVaultStatus`

`checkVaultStatus` is where:

- interest accrual is refreshed
- vault status is logged
- supply and borrow caps are enforced using the snapshot captured during `initOperation`
- an optional vault-status hook may run

So a successful state-changing EVault operation means more than "the token transfer worked." It also means the EVC-framed validation pipeline accepted the new post-operation state.

### 3.4 Hook behavior in EVault

EVault hooks are configured through `hookedOps` and `hookTarget`.

`Base.callHook(...)` and `Base.callHookWithLock(...)`:

- append the authenticated caller to the calldata
- call the configured hook target
- revert if the operation is hooked but the target is zero address

That means a hook can do one of three things for an operation:

- extend it
- constrain it
- disable it entirely by leaving the target unset while the op flag is enabled

## 4. Where Euler Uses Oracle Data

The oracle resolver is separate from the vault and from EVC. The key resolver surface is `oracle/EulerRouter.sol`, while actual price sources come from configured adapters.

Within the lifecycle, oracle values matter mainly during health and liquidation logic.

`LiquidityUtils.sol` is the important local surface. It uses oracle quotes to compute:

- collateral value
- liability value
- account liquidity
- liquidation eligibility

This is an important boundary:

- oracle resolution is an input into risk checks
- it is not the mechanism that moves or settles tokens

## 5. Euler Earn Lifecycle

### 5.1 Euler Earn is not the core lending vault

`EulerEarn.sol` is a separate ERC4626 vault that allocates its assets across other strategy vaults. It is better thought of as a vault-of-vaults or allocator vault.

Its lifecycle is driven by:

- `supplyQueue`
- `withdrawQueue`
- per-market caps
- `reallocate(...)`

### 5.2 Deposit and mint lifecycle in Euler Earn

Public entrypoints are:

- `deposit(uint256 assets, address receiver)`
- `mint(uint256 shares, address receiver)`

The lifecycle is:

1. accrue fees and interest accounting
2. convert assets and shares using current totals
3. transfer the underlying token from caller into Euler Earn
4. mint Euler Earn shares to the receiver
5. distribute supplied assets into downstream strategy vaults through the configured queue

Real token movement into Euler Earn happens in `_deposit(...)`:

- `safeTransferFromWithPermit2(caller, address(this), assets, permit2Address)`

After that, Euler Earn fans capital out to downstream strategy vaults by calling their `deposit(...)` entrypoints.

### 5.3 Withdraw and redeem lifecycle in Euler Earn

Public entrypoints are:

- `withdraw(uint256 assets, address receiver, address owner)`
- `redeem(uint256 shares, address receiver, address owner)`

The lifecycle is:

1. accrue fees and interest accounting
2. compute shares and assets
3. optimistically attempt withdrawal
4. if necessary, unwind downstream positions according to the withdraw queue
5. burn Euler Earn shares
6. transfer underlying assets to the receiver

So Euler Earn has two custody layers:

- direct custody in the allocator vault itself
- indirect exposure through balances held in downstream ERC4626 strategy vaults

### 5.4 Reallocation lifecycle

`reallocate(...)` is the key allocator operation.

For each target market allocation, Euler Earn may:

- withdraw assets from one strategy vault
- update internal recorded balance for that market
- deposit assets into another strategy vault
- require total withdrawn assets to match total supplied assets

So `reallocate` is the canonical internal portfolio-management path rather than a user deposit or borrow path.

## 6. Euler Swap Lifecycle

### 6.1 Euler Swap is backed by Euler vaults

`EulerSwap` is not just a local AMM with raw idle reserves.

Its static params point at:

- supply vaults for each side
- borrow vaults for each side
- a shared `eulerAccount`

This matters because swap settlement is allowed to source output liquidity from supplied positions and, if needed, from borrow capacity in Euler vaults.

### 6.2 User-facing swap entrypoints

The user-facing surface is split between:

- `EulerSwap.sol` pool-side `swap(...)`
- `EulerSwapPeriphery.sol` exact-in and exact-out convenience routing

The periphery performs the user token pull first. That means the initial ERC20 move from the trader into the swap system happens before the pool-side reserve settlement logic runs.

### 6.3 Swap accounting lifecycle

`SwapLib` is the core lifecycle engine.

The high-level flow is:

1. initialize a `SwapContext`
2. compute amounts in and out
3. optionally invoke a before-swap hook
4. perform withdrawals for the output side
5. perform deposits for the input side
6. verify the post-swap curve invariant
7. store new reserves
8. emit `Swap`
9. optionally invoke an after-swap hook

The settlement edges are split deliberately:

- `doWithdraws(...)` handles the output leg
- `doDeposits(...)` handles the input leg
- `finish(...)` commits the new reserves only after curve verification passes

### 6.4 Where output tokens actually come from

`SwapLib.doWithdraw(...)` calls `FundsLib.withdrawAssets(...)`.

That function first tries to source output tokens by withdrawing from the relevant supply vault on behalf of the configured Euler account.

If that is not enough, it can:

- enable the borrow controller on the Euler account
- borrow the remaining amount from the configured borrow vault

So Euler Swap liquidity is compositional:

- first from supplied assets
- then from borrow capacity

That is a meaningful lifecycle distinction from a simple reserve-only AMM.

### 6.5 Where input tokens actually go

`SwapLib.doDeposit(...)` handles the input side.

It:

- slices out protocol fees and optional LP-recipient fees
- deposits the remaining amount through `FundsLib.depositAssets(...)`

`FundsLib.depositAssets(...)` first tries to repay existing debt on the Euler account. Any remainder is then deposited into the configured supply vault.

So the input leg is not merely stored as free idle reserve. It is used to rebalance the Euler-backed position:

- repay debt first if controller-enabled debt exists
- then deposit the remainder as supplied assets

### 6.6 Swap invariants and hooks

The core post-swap invariant in `SwapLib.finish(...)` is:

- compute `newReserve0 = old + in - out`
- compute `newReserve1 = old + in - out`
- require `CurveLib.verify(...)`
- only then persist reserves

Euler Swap also supports:

- direct swap callbacks through `IEulerSwapCallee`
- configurable before-swap and after-swap hooks
- a Uniswap v4 hook-driven mode in `UniswapHook.sol`

So this subtree contains both a native Euler Swap lifecycle and a Uniswap-hook-integrated lifecycle, but they reuse the same underlying funds and settlement libraries.

## 7. Liquidation Lifecycle

### 7.1 Liquidation is an unhealthy-path EVault operation

The liquidation path in `Liquidation.sol` is the main failure branch for the lending system.

Public entrypoints are:

- `checkLiquidation(...)`
- `liquidate(...)`

`checkLiquidation` is a read-only preview.
`liquidate` is the real state-changing path.

### 7.2 Liquidation eligibility checks

`liquidate(...)` begins with:

1. `initOperation(OP_LIQUIDATE, CHECKACCOUNT_CALLER)`
2. `calculateLiquidation(...)`
3. `executeLiquidation(...)`

Before any debt transfer or collateral seizure, Euler checks:

- liquidator and violator are not the same account
- collateral is recognized and enabled
- this vault is the violator's controller
- the violator is not already in deferred-liquidity state
- liquidation cool-off has elapsed
- the violator actually has liabilities

Then it computes:

- current liability
- current collateral-adjusted value
- liquidation discount
- maximum repay and maximum yield

### 7.3 Liquidation execution

If liquidation proceeds, the path is:

1. transfer borrow exposure from violator to liquidator for the repay portion
2. enforce collateral transfer from violator to liquidator
3. forgive the violator account status check that was triggered by the enforced collateral transfer
4. if configured conditions are met, socialize remaining bad debt

The debt socialization branch only happens when:

- remaining liability is large enough
- debt socialization is not disabled
- some debt remains after the liquidator repay
- the violator has no remaining collateral

So liquidation is not just a simple seize-and-repay path. It can end in either:

- partial restoration via collateral seizure and debt transfer
- or a residual debt socialization branch when collateral is exhausted

## 8. Where Tokens Actually Move

This is the shortest possible operational summary:

### 8.1 EVault

- `deposit` and `repay` pull assets into EVault with `pullAssets`
- `withdraw` and `borrow` push assets out of EVault with `pushAssets`
- `repayWithShares` burns internal balances and debt without moving underlying ERC20s
- `flashLoan` pushes assets out and checks that they came back by the end of the callback

### 8.2 EVC

- does not custody or transfer the ERC20 as the core lifecycle step
- frames execution, authentication, and deferred checks

### 8.3 Euler Earn

- pulls underlying assets into Euler Earn from the user
- then deposits them into downstream strategy vaults
- withdraws from downstream strategy vaults when satisfying user exits

### 8.4 Euler Swap

- user input is initially pulled by the periphery
- output tokens are sourced from supply-vault withdrawals and, if needed, borrow-vault borrowing
- input tokens are used to repay debt first and deposit remainder back into the supply vaults

## 9. Key Validation Invariants

Across the unified Euler v1 surface, the key invariants are:

1. EVault operations must survive EVC-framed deferred account and vault checks.
2. EVault cannot withdraw or borrow more cash than it actually has.
3. Euler Earn reallocation must keep total withdrawn assets equal to total supplied assets.
4. Euler Swap must pass `CurveLib.verify(...)` before new reserves are committed.
5. Liquidation can only proceed when the violator is genuinely unhealthy under the oracle-driven liquidity checks.
6. Hooks can extend or constrain behavior, and a hooked operation can be disabled by configuration.

## 10. Scope Boundaries

This note focuses on the main protocol lifecycle surfaces:

- EVault
- EVC
- Euler Earn
- Euler Swap
- liquidation

It does not try to fully document:

- reward streams
- OFT and bridging contracts
- most governor and factory contracts
- periphery utilities that do not materially change the main lifecycle
- the full adapter catalog under `oracle/adapter`

Those are adjacent systems, but not part of the core lifecycle spine described here.

## 11. Bottom Line

Euler v1 in this tree is a layered system.

At the center is EVault, which actually holds cash, mints and burns shares, tracks debt, and moves the underlying token. Around that is EVC, which authenticates execution and defers health checks until the operation is complete. Euler Earn builds an allocator vault on top of ERC4626 strategy vaults, and Euler Swap builds a swap surface whose liquidity can be sourced from supplied assets and borrow capacity in Euler vaults. When accounts become unhealthy, liquidation takes over and resolves the position through collateral seizure, debt transfer, and possibly debt socialization.

So the clean mental model is:

1. EVault is the custody and debt engine
2. EVC is the execution and validation frame
3. Euler Earn is the allocator layer
4. Euler Swap is the liquidity-routing layer
5. liquidation is the unhealthy-path settlement branch
