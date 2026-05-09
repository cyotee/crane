# Balancer V3 Lifecycle In Crane

This note explains the Balancer V3 swap, add liquidity, and remove liquidity lifecycles in the Crane port, with emphasis on:

- when accounting changes happen versus when ERC20 transfers happen
- when tokens must already be present in the Vault
- when configured Rate Providers are applied
- what is feasible for wrapping and unwrapping flows with pools, hooks, and routers

The main code paths are:

- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultTransientFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultSwapFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLiquidityFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultModifiers.sol`
- `contracts/external/balancer/v3/vault/contracts/lib/PoolDataLib.sol`
- `contracts/external/balancer/v3/solidity-utils/contracts/helpers/ScalingHelpers.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterModifiers.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterSwapFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterAddLiquidityFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterRemoveLiquidityFacet.sol`
- `contracts/protocols/dexes/balancer/v3/hooks/BaseHooksTarget.sol`
- `contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/BufferRouterFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityERC4626Facet.sol`
- `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol`

## 1. Core Mental Model

Balancer V3 here is a two-layer system:

1. the Vault does transient accounting and pool balance updates
2. the Router performs the actual user-facing token movement into and out of the Vault

That distinction is the most important thing to keep straight.

Inside the Vault, swaps and liquidity operations do not immediately pull input tokens from the user and do not immediately push output tokens to the user. Instead, they create transient signed deltas with:

- `_takeDebt(token, amount)` when the Vault is owed tokens
- `_supplyCredit(token, amount)` when the Vault owes tokens

The unlock session in `VaultTransientFacet.unlock` must end with `_nonZeroDeltaCount() == 0`, or the whole call reverts with `BalanceNotSettled()`.

So the lifecycle is:

1. Router enters `vault.unlock(...)`
2. Vault computes balances, fees, and deltas
3. Router settles those deltas by transferring tokens in with `settle(...)` and transferring tokens out with `sendTo(...)`
4. unlock closes only if everything nets to zero

## 2. When Tokens Actually Move

There are only a few places where real token transfers happen.

### 2.1 Tokens moving into the Vault

Real token movement into the Vault happens in router helpers, not in Vault swap or liquidity math.

For standard router flows, `BalancerV3RouterModifiers._takeTokenIn(...)` does one of the following:

- WETH as ETH path: wrap ETH into WETH, transfer WETH to the Vault, then call `vault.settle(tokenIn, amountIn)`
- retail path: `Permit2.transferFrom(sender, address(vault), amountIn, token)` and then `vault.settle(tokenIn, amountIn)`
- prepaid path: no transfer happens there because tokens are already sitting in the Vault; the router only calls `vault.settle(tokenIn, amountIn)`

The important point is that `settle(...)` does not trust a nominal amount. It measures `currentReserves - reservesBefore`, caps by `amountHint`, stores the new reserves, and then calls `_supplyCredit(token, credit)`.

### 2.2 Tokens moving out of the Vault

Real token movement out of the Vault happens in `VaultTransientFacet.sendTo(...)`.

That function:

1. calls `_takeDebt(token, amount)`
2. decrements `reservesOf[token]`
3. performs `token.safeTransfer(to, amount)`

Router helpers call `vault.sendTo(...)` via `_sendTokenOut(...)`.

If `wethIsEth` is enabled and the token is WETH, the Router:

1. calls `vault.sendTo(WETH, address(this), amountOut)`
2. unwraps WETH to ETH
3. sends ETH to the user

Otherwise the Router just calls `vault.sendTo(tokenOut, sender, amountOut)`.

### 2.3 What does not move tokens

The following are accounting-only from the user token movement perspective:

- `vault.swap(...)`
- `vault.addLiquidity(...)`
- `vault.removeLiquidity(...)`

Those functions change pool state and transient deltas. They do not by themselves pull from the user wallet.

## 3. When Tokens Must Be Present In The Vault

### 3.1 Before `swap`, `addLiquidity`, or `removeLiquidity`

For normal router flows, input tokens do not need to already be present in the Vault before the Vault computes the swap or liquidity result.

That is because the Vault records debt first, and the Router settles that debt afterward inside the same unlock session.

This is why the router hook order looks inverted at first glance:

- the Router calls `vault.swap(...)` or `vault.addLiquidity(...)`
- the Vault creates deltas
- the Router then transfers tokens in and calls `vault.settle(...)`

So for retail mode, user input tokens can remain in the user wallet until after the Vault math runs, as long as the Router can transfer them and settle them before unlock ends.

### 3.2 In prepaid mode

In prepaid mode, the tokens must already be in the Vault before the operation-specific router hook calls `vault.settle(...)`.

This path is used when the router is configured as prepaid instead of retail. In that case `_takeTokenIn(...)` does not transfer tokens. It only settles pre-existing Vault balances.

If the prepositioned balance is insufficient, the Router reverts with `InsufficientPayment(token)`.

### 3.3 Before `sendTo(...)`

Output tokens do need to be present in the Vault by the time the Router calls `vault.sendTo(...)`.

That is stricter than the input side. `sendTo(...)` decrements reserves and then performs a real ERC20 transfer immediately. So the Vault must be able to satisfy that transfer at that point.

In practice, that means:

- the pool's accounted raw balances and Vault reserves must support the outgoing transfer
- if the Router wants ETH-out for WETH, the Vault must hold WETH, because the unwrap happens only after `sendTo(WETH, router, amount)`

## 4. Swap Lifecycle

### 4.1 Unlock and callback

`RouterSwapFacet.swapSingleTokenExactIn` and `swapSingleTokenExactOut` call `vault.unlock(abi.encodeCall(this.swapSingleTokenHook, params))`.

That creates a single transient accounting session.

### 4.2 Vault loads pool data

Inside `VaultSwapFacet.swap(...)`, the Vault first calls `_loadPoolDataUpdatingBalancesAndYieldFees(pool, rounding)`.

That loads:

- raw balances
- live balances
- token rates
- pool config
- token metadata

and then `PoolDataLib.syncPoolBalancesAndFees(...)` pushes any due yield fees into aggregate fee storage.

### 4.3 Hooks before math

If configured, the Vault calls:

- `onBeforeSwap(...)`
- `onComputeDynamicSwapFeePercentage(...)`

If `onBeforeSwap(...)` runs, the Vault reloads balances and rates with `poolData.reloadBalancesAndRates(...)` before continuing. That matters because a hook may have changed raw balances or caused rate-sensitive state to change.

### 4.4 Rate Provider application during swap

Configured Rate Providers are applied before the pool's `onSwap(...)` math whenever raw amounts or raw balances are converted into the Vault's normalized 18-decimal space.

Specifically:

- `PoolDataLib.load(...)` calls `getTokenRate(tokenInfo)`
- `TokenType.STANDARD` gets rate `1e18`
- `TokenType.WITH_RATE` gets `tokenInfo.rateProvider.getRate()`
- raw pool balances are turned into `balancesLiveScaled18` with `toScaled18ApplyRateRoundDown` or `toScaled18ApplyRateRoundUp`

For swap inputs and outputs:

- EXACT_IN input raw amount uses `toScaled18ApplyRateRoundDown(tokenInScaling, tokenInRate)`
- EXACT_OUT desired output raw amount uses `toScaled18ApplyRateRoundUp(tokenOutScaling, tokenOutRate.computeRateRoundUp())`
- EXACT_IN output is converted back to raw with `toRawUndoRateRoundDown(..., tokenOutRate.computeRateRoundUp())`
- EXACT_OUT input is converted back to raw with `toRawUndoRateRoundUp(..., tokenInRate)`

So the rate provider is part of every raw-to-scaled and scaled-to-raw conversion used by swap math.

### 4.5 Pool math and fee math

The Vault then:

1. applies swap fee on the scaled18 side
2. calls `IBasePool(pool).onSwap(poolSwapParams)`
3. converts the result back to raw
4. checks the user limit

The transient accounting changes are then:

- `_takeDebt(tokenIn, amountInRaw)`
- `_supplyCredit(tokenOut, amountOutRaw)`

Swap fee accounting is also converted back to raw using token rates before the aggregate protocol and creator fee portion is stored.

### 4.6 Hook after math

If configured, `onAfterSwap(...)` runs after the Vault has already updated balances and computed the raw amount.

If hook-adjusted amounts are enabled for the pool, this hook can replace the final raw amount calculated. It can adjust the amount, but it does not change which token addresses are being swapped.

### 4.7 Settlement and transfer

After the Vault returns `(amountCalculated, amountIn, amountOut)`, the Router settles:

- input side with `_takeTokenIn(...)` or prepaid `settle(...)`
- output side with `_sendTokenOut(...)`

The actual ERC20 transfers happen here, not in the Vault swap math itself.

## 5. Add Liquidity Lifecycle

### 5.1 Vault-side flow

`RouterAddLiquidityFacet` enters `vault.unlock(...)` and its hook calls `vault.addLiquidity(...)`.

Inside `VaultLiquidityFacet.addLiquidity(...)`, the Vault:

1. records `addLiquidityCalled` for round-trip fee protection
2. loads pool data and updates yield fees
3. converts `maxAmountsIn` raw to scaled18 with rates applied
4. optionally calls `onBeforeAddLiquidity(...)`
5. reloads balances and rates if the hook ran
6. computes liquidity math based on `AddLiquidityKind`
7. creates deltas with `_takeDebt(token, amountInRaw)` for each input token
8. computes aggregate fees
9. updates pool raw and live balances
10. mints BPT
11. optionally calls `onAfterAddLiquidity(...)`

### 5.2 Rate Provider application during add liquidity

Rate providers are applied in two places:

- pool raw balances are converted into live balances during pool-data load/reload
- user-provided `maxAmountsIn` are converted into scaled18 amounts with `copyToScaled18ApplyRateRoundDownArray(...)`

When the Vault needs to convert a computed scaled18 input amount back into raw token units, it uses `toRawUndoRateRoundUp(...)`.

That means the configured rate provider affects:

- the pool-side liquidity math inputs
- the raw amount finally charged to the user
- the raw fee amount derived from scaled18 fee amounts

### 5.3 When input tokens move

The Vault add-liquidity logic does not move input tokens from the user. It only records debt.

After `vault.addLiquidity(...)` returns, `RouterAddLiquidityFacet._processTokensIn(...)` settles each token:

- normal retail mode: transfer token to Vault, then `vault.settle(...)`
- prepaid mode: `vault.settle(...)` against already-prepositioned balances, then refund any unused excess
- WETH-as-ETH mode: wrap ETH into WETH, transfer to Vault, then settle

So user tokens do not need to be in the Vault before `vault.addLiquidity(...)` runs, except in prepaid flows.

## 6. Remove Liquidity Lifecycle

### 6.1 Vault-side flow

`RouterRemoveLiquidityFacet` enters `vault.unlock(...)` and its hook calls `vault.removeLiquidity(...)`.

Inside `VaultLiquidityFacet.removeLiquidity(...)`, the Vault:

1. loads pool data and updates yield fees
2. converts `minAmountsOut` raw into scaled18 with rate-aware round-up
3. optionally calls `onBeforeRemoveLiquidity(...)`
4. reloads balances and rates if the hook ran
5. computes the remove-liquidity math for the requested kind
6. for proportional remove, may charge a round-trip fee if add and remove occur in the same unlock session
7. converts scaled18 outputs back to raw with `toRawUndoRateRoundDown(...)`
8. creates deltas with `_supplyCredit(token, amountOutRaw)`
9. charges aggregate fees and updates pool balances
10. spends BPT allowance and burns BPT
11. optionally calls `onAfterRemoveLiquidity(...)`

### 6.2 Rate Provider application during remove liquidity

Rate providers are applied to:

- the live pool balances loaded before remove-liquidity math
- the scaled18 version of `minAmountsOut` via `copyToScaled18ApplyRateRoundUpArray(...)`
- the raw outputs obtained from scaled18 with `toRawUndoRateRoundDown(...)`
- the raw fee amounts derived from scaled18 fees

So the configured rate provider is active throughout the remove-liquidity quoting and settlement path, not only in view helpers.

### 6.3 When output tokens move

The Vault remove-liquidity logic creates credit first. It does not automatically transfer tokens to the user.

After the Vault returns, `RouterRemoveLiquidityFacet` loops through pool tokens and calls `_sendTokenOut(...)`, which delegates to `vault.sendTo(...)`.

That is the point where real token transfer occurs.

So by the time remove-liquidity settlement runs, the Vault must be able to physically transfer the output tokens.

## 7. Hooks: What They Can And Cannot Do

Hooks can run:

- before initialize, swap, add liquidity, remove liquidity
- after initialize, swap, add liquidity, remove liquidity
- during dynamic swap fee computation

Important constraints:

- hooks are always called by the Vault
- hooks receive the operation's token set and amounts; they do not redefine token identities
- after hooks can adjust raw amounts only if `enableHookAdjustedAmounts` is enabled

So hooks are good for:

- validation and gating
- dynamic fee logic
- supplementary accounting
- amount adjustments
- carefully designed reentrant flows that the Vault API already supports

Hooks are not, by themselves, a complete generic token-wrapper router.

In particular, a swap hook can change the amount but it does not replace `tokenIn` and `tokenOut` in the Vault swap interface. If you want the user to trade an underlying asset while the pool actually holds a wrapped asset, you need an explicit wrapping layer around the standard swap path.

## 8. Feasibility Of Wrapped And Unwrapped Asset Flows

### 8.1 Native ETH and WETH

This is already supported in the base router.

The pool and Vault still trade WETH. The router simply:

- wraps ETH to WETH before settling token-in
- unwraps WETH to ETH after receiving token-out

So this is feasible today without custom pool or hook logic. The wrap and unwrap happen in the Router, not inside pool math.

### 8.2 ERC4626 wrapped assets

This is also supported, but not through the plain single-token swap or plain add/remove routes alone.

The intended path is:

- `BufferRouterFacet` for ERC4626 buffer initialization and liquidity
- `CompositeLiquidityERC4626Facet` for adding/removing liquidity to ERC4626 pools while wrapping and unwrapping automatically
- `vault.erc4626BufferWrapOrUnwrap(...)` for the actual wrap/unwrap execution

The key operational detail is that `CompositeLiquidityERC4626Facet` requires a registered ERC4626 buffer asset. If the buffer is not initialized, it reverts with `BufferNotInitialized(...)`.

So for ERC4626-style wrapping, the feasible path is:

1. register the wrapped token in the pool
2. initialize the corresponding Vault buffer
3. use the composite liquidity or buffer router path to wrap or unwrap around Vault settlement

### 8.3 Can a pool and hook alone implement generic wrap/unwrap swap UX?

Not cleanly in the standard Vault swap lifecycle.

The reason is structural:

- pool swap math operates on the registered pool tokens
- hook callbacks observe and adjust amounts for those same tokens
- final settlement still occurs in those same token addresses through `settle(...)` and `sendTo(...)`

So if a pool holds wrapped token `wToken`, a vanilla `swap(tokenIn=underlying, tokenOut=other)` is not something the core swap interface natively expresses unless a separate wrapping layer first turns `underlying` into `wToken`.

In practice:

- WETH/ETH is handled by router-side convenience logic
- ERC4626 wrapping is handled by dedicated buffer and composite-liquidity routes
- a custom hook may assist, but the full user-facing wrap/unwrap flow still needs an explicit routing and settlement design

### 8.4 A realistic design boundary

If you want user-facing swaps between underlying and a wrapped-token pool position, the most realistic options are:

1. keep the wrapped asset as the pool token and add a specialized router layer that wraps before settlement and unwraps after settlement
2. use the ERC4626 buffer and composite-liquidity facilities if the wrapped token is ERC4626-compatible
3. build a custom pool or custom router flow if you need broader wrapper semantics than WETH or ERC4626 buffers provide

Trying to do the whole thing with only a hook-adjusted amount and no explicit routing layer is too weak a primitive for general wrapping.

## 9. Exactly When Rate Providers Matter

This is the concise answer to the Rate Provider question.

Configured Rate Providers are applied:

- when `PoolDataLib.load(...)` computes each token's `tokenRates[i]`
- when raw pool balances are converted to live balances in `balancesLiveScaled18`
- when swap inputs are converted from raw to scaled18
- when swap outputs are converted from scaled18 back to raw
- when add-liquidity inputs are converted from raw to scaled18
- when remove-liquidity minimums are converted from raw to scaled18
- when computed liquidity amounts are converted from scaled18 back to raw
- when scaled18 fee amounts are converted into raw token fee amounts
- when yield fees are computed from live-balance growth caused by rate changes
- when balances and rates are reloaded after before-hooks

Configured Rate Providers are not applied at the final ERC20 transfer step itself. `settle(...)`, `sendTo(...)`, Permit2 transfers, WETH wrapping, and WETH unwrapping all operate on raw token units. The rate has already influenced the amounts by the time those transfer functions are called.

## 10. Bottom Line

- The Vault is accounting-first. The Router is transfer-first.
- `swap`, `addLiquidity`, and `removeLiquidity` do not directly pull user tokens; they create transient debts and credits.
- Real input transfer happens when the Router calls `_takeTokenIn(...)` and then `vault.settle(...)`.
- Real output transfer happens when the Router calls `_sendTokenOut(...)`, which uses `vault.sendTo(...)`.
- Input tokens need not already be in the Vault for standard retail flows, but they do need to be there for prepaid settlement paths.
- Output tokens must be available in the Vault at the moment `sendTo(...)` executes.
- Rate Providers affect all internal balance normalization and raw-to-scaled or scaled-to-raw amount conversions, plus yield-fee charging.
- WETH/ETH wrap and unwrap is already supported in the base router.
- Generic wrapped-asset UX requires an explicit wrapper-aware router path; for ERC4626, the supported mechanism is the buffer plus composite-liquidity route rather than plain swap hooks alone.
