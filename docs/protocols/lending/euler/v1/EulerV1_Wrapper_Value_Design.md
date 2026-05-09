# Euler V1 Wrapper-Value Design

This note proposes a concrete Euler-side design for supporting wrapper tokens whose economic value tracks an underlying asset while preserving Euler's existing execution model.

The target use case is:

- a wrapper or ERC4626-style vault abstracts an underlying protocol position
- users want to think and quote in underlying-value terms
- custody may remain in the wrapper form
- swap, deposit, withdraw, borrow, and repay paths must still fit the existing EVC and EVault flow

The core design principle is:

Euler should not pretend the core EVault is natively rate-aware.

Instead, the wrapper-value translation should live at the wrapper vault and swap adapter layer, while EVault and EVC continue to own custody, debt accounting, and deferred health validation.

## 1. Design Summary

The recommended Euler design is:

1. use an ERC4626-style wrapper vault as the canonical conversion layer between assets and wrapper shares
2. keep EVault accounting denominated in the actual asset each EVault already owns
3. use Euler Swap or a swap hook as the execution surface that translates user-facing underlying-value intent into actual vault deposits and withdrawals
4. let EVC remain the sole owner of deferred controller and account health checks
5. keep wrap and unwrap synchronous and atomic inside a single execution path

This keeps responsibilities separated cleanly:

- wrapper vault owns asset/share conversion
- EVault owns cash, shares, debt, and token custody
- EVC owns authentication and deferred checks
- swap layer owns quote translation and routing

## 2. Goals And Non-Goals

### Goals

- expose user-facing amounts in underlying-value terms
- allow actual custody to remain in wrapper or vault form where needed
- preserve the existing EVault and EVC accounting model
- support just-in-time wrap and unwrap during swap execution
- support deposits and withdrawals through a wrapper abstraction without bypassing risk checks

### Non-Goals

- do not modify EVault core math to become globally rate-normalized
- do not spread wrapper conversion logic across every module path
- do not treat EVC as a token-custody layer
- do not support wrappers with asynchronous redemption, delayed queues, or non-atomic settlement in the first implementation

## 3. Why Euler Can Support This Cleanly

Euler already separates execution roles well enough for this design.

### 3.1 EVault already works on concrete asset custody

In the existing lifecycle:

- deposits pull the actual underlying into the vault
- withdrawals push the actual underlying out of the vault
- borrow pushes real underlying out
- repay pulls real underlying back in

That is a good base. The wrapper-value layer does not need to change how EVault accounts for real token movement.

### 3.2 EVC already provides the right execution frame

EVC already handles:

- authenticated execution
- `onBehalfOf` routing
- controller enablement
- deferred account and vault checks

That means wrapper-aware execution can remain a higher-level orchestration problem. The health and controller model does not need to be reinvented.

### 3.3 Euler Swap already has the right insertion point

`UniswapHook` and `SwapLib` already compute quotes externally, perform deposits and withdrawals through Euler vaults, and then finish settlement.

That is the correct seam for wrapper-value translation because it already owns:

- quote-time amount computation
- swap-time amount application
- deposit and withdraw orchestration through `FundsLib`

## 4. Recommended Architecture

The design has three primary layers.

### 4.1 Wrapper vault layer

Use an ERC4626-style wrapper as the canonical conversion layer.

The wrapper should expose deterministic conversion functions equivalent to:

- `convertToAssets(shares)`
- `convertToShares(assets)`
- `previewDeposit`, `previewMint`, `previewWithdraw`, `previewRedeem` when available

`ERC4626EVC.sol` is a strong template because it already provides:

- explicit asset and share accounting
- EVC-compatible caller semantics
- internal total asset tracking
- clear deposit and withdraw boundaries

The wrapper vault is where asset/share math should live. Do not duplicate that conversion logic inside each EVault module.

### 4.2 Euler vault layer

Each EVault should continue to hold and account for its actual configured asset.

That means:

- an EVault holding an underlying token should stay an underlying-token EVault
- an EVault holding a wrapper token should stay a wrapper-token EVault
- debt and collateral state should remain defined on the actual vault asset, not a synthetic underlying-value shadow unit

This avoids hidden conversion risk inside the risk engine.

### 4.3 Swap and routing layer

The swap layer should own value translation between user intent and actual vault assets.

For Euler Swap, that means:

- quote in underlying-value terms for the user-facing API
- convert to actual asset amounts before `FundsLib.depositAssets(...)` and `FundsLib.withdrawAssets(...)`
- if needed, wrap before deposit and unwrap after withdraw inside the same execution path

This matches the existing `UniswapHook -> SwapLib -> FundsLib` structure.

## 5. Where Conversion Logic Should Live

There are two plausible places to put conversion logic.

### 5.1 Preferred: wrapper-owned conversion plus swap-owned orchestration

Recommended rule:

- wrapper contract decides asset/share conversion
- swap or periphery adapter decides when to call those conversions
- EVault remains unaware of value translation beyond the actual asset it already holds

This is the cleanest ownership model.

### 5.2 Avoid: embedding wrapper translation in EVault core modules

Do not add wrapper-value translation directly inside:

- `Vault.deposit`
- `Vault.withdraw`
- `Borrowing.borrow`
- `Borrowing.repay`

That would blur the boundary between:

- asset custody
- wrapper conversion
- risk validation

and would make core lending paths harder to reason about.

## 6. Concrete Swap Design

The most natural Euler implementation is a quote-and-settle model, not a passive pool-pricing model.

### 6.1 Exact-input user flow

Recommended first implementation:

1. user specifies exact input in underlying-value terms
2. swap layer reads live wrapper conversion from the wrapper vault
3. swap layer computes actual deposit and withdrawal amounts for the concrete EVault assets
4. if the input side needs wrapping, wrap first
5. call `FundsLib.depositAssets(...)` with the actual asset amount that the target vault expects
6. perform swap accounting and quote verification in `SwapLib`
7. call `FundsLib.withdrawAssets(...)` for the output side
8. if the user expects underlying output rather than wrapper output, unwrap before final delivery
9. let EVC close the frame and run deferred checks

This keeps all conversions explicit and auditable.

### 6.2 Exact-output support

Exact-output should be considered optional.

It is only safe when:

- preview and execution conversion paths match closely
- wrapper rounding direction is bounded and understood
- the wrapper can synchronously mint and redeem inside the transaction
- there is no stateful delay or queue between input and output determination

If those conditions are not guaranteed, exact-output should revert.

## 7. Deposit And Withdraw Design

The wrapper design should support two surfaces.

### 7.1 Wrapper-facing vault surface

If the user intentionally interacts with the wrapper vault itself:

- `deposit` accepts the underlying asset and mints wrapper shares
- `withdraw` burns wrapper shares and returns the underlying asset

That is standard ERC4626 behavior and should remain local to the wrapper.

### 7.2 Euler-facing vault surface

If the wrapper token is the actual asset of an EVault:

- deposit path should first obtain wrapper shares, then deposit those shares into the EVault
- withdrawal path should first withdraw wrapper shares from the EVault, then optionally redeem them to underlying assets in periphery

The important boundary is that EVault only sees its actual asset. The wrap and unwrap happens before or after EVault custody changes, not inside EVault's core share math.

## 8. Borrow And Repay Design

Borrow and repay require stricter boundaries because debt should stay on concrete assets.

### 8.1 Borrow

If a borrow vault is wrapper-denominated:

- EVault debt is denominated in wrapper token units
- borrow pushes wrapper tokens out
- periphery may optionally redeem them to underlying before giving final assets to the user

If a borrow vault is underlying-denominated but the user wants wrapped output:

- borrow pushes underlying out
- periphery wraps before final delivery

In both cases, the debt remains defined on the actual borrowed asset.

### 8.2 Repay

Repay should mirror borrow.

- if debt is wrapper-denominated, repay path must deliver wrapper tokens
- if user pays with underlying, periphery wraps first and then repays
- if debt is underlying-denominated, do not introduce a wrapper translation inside core repay logic

This keeps debt accounting simple and avoids hidden exchange-rate dependency in debt units.

## 9. Risk Model Recommendations

Wrapper support is safe only if the risk model remains explicit about what is being valued.

Recommended rules:

- collateral and debt units are always the actual EVault asset units
- oracle and risk configuration may value those units through an external rate-aware price feed if needed
- internal vault accounting should not silently convert debt or collateral into another unit system

If the protocol wants underlying-value health semantics for a wrapper asset, handle that in oracle or risk configuration, not by mutating EVault balance math.

## 10. Recommended Adapter Shapes

There are two good concrete adapter shapes.

### 10.1 ERC4626 wrapper periphery adapter

This adapter sits above EVault and EVC and offers:

- deposit underlying into wrapper then into EVault
- withdraw from EVault then redeem wrapper to underlying
- repay underlying by wrapping first
- borrow wrapper and optionally redeem before delivery

This is the right shape for user-facing wallet flows.

### 10.2 Euler Swap hook adapter

This adapter sits in the swap path and offers:

- quote translation from underlying-value to actual vault asset amounts
- execution-time wrap and unwrap when needed
- final settlement through `FundsLib`

This is the right shape for trading and routing flows.

## 11. Failure Modes To Explicitly Guard

The design must reject or explicitly handle:

- wrappers with asynchronous redemption
- wrappers with cooldowns or exit queues
- wrappers whose preview functions diverge materially from execution
- wrappers with transfer fees or stateful redemption penalties unless fully modeled
- repay flows that attempt to repay wrapper debt with underlying tokens without a conversion step
- borrow flows that hide conversion slippage from the user

If the wrapper cannot mint and redeem atomically with predictable rounding, it should not be in the first implementation scope.

## 12. Concrete Invariants

The first implementation should preserve these invariants.

1. EVault cash and debt accounting remain in actual asset units.
2. EVC remains the only owner of deferred account and vault validation.
3. Wrapper asset/share conversion has a single source of truth: the wrapper vault.
4. Swap and periphery adapters may orchestrate wrap and unwrap, but they do not redefine EVault units.
5. If user-facing amounts are shown in underlying-value terms, the execution path must use the same conversion source.
6. Unsupported exact-output or asynchronous paths must revert explicitly.

## 13. Recommended First Implementation Scope

The first Euler wrapper-value implementation should stay narrow.

Recommended first version:

- one ERC4626-style wrapper type
- synchronous wrap and unwrap only
- exact-input swap support only
- user-facing periphery adapter for deposit, withdraw, borrow, and repay
- swap integration through Euler Swap hook or equivalent adapter
- oracle configuration that explicitly values the wrapper asset without changing EVault internal units

This gives the protocol wrapper-aware user flows without destabilizing the core lending model.

## 14. Relationship To The Uniswap V4 Design

The matching v4 design should be read as the pool-side half of the same system.

The recommended composition is:

- Euler-side wrapper vault and adapters own conversion and custody orchestration
- v4-side hook owns pool-facing amount translation and atomic settlement

That gives a clean split:

- Euler handles vault, debt, and authenticated execution semantics
- v4 hook handles wrapper-aware swap semantics

Neither side needs to pretend its core accounting engine is natively rate-normalized.

## 15. Bottom Line

For Euler, the right design is not to make EVault itself behave like a rate-aware wrapper vault.

The right design is:

- keep EVault concrete
- keep EVC in charge of deferred validation
- use an ERC4626-style wrapper as the canonical conversion source
- use periphery and swap adapters to perform just-in-time wrap and unwrap around the real vault operations

That gives the desired underlying-value user experience while keeping Euler's lending and risk model legible.