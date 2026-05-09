# Uniswap V4 Lifecycle In Crane

This note explains the lifecycle of swaps and liquidity changes in the Crane port of Uniswap v4, with emphasis on:

- when tokens actually move
- what the PoolManager must really hold versus what can be traded by accounting
- how hook-based wrapping and unwrapping works
- what is and is not feasible if assets are held in alternate wrappers

The relevant code paths in this repo are centered in:

- `contracts/protocols/dexes/uniswap/v4/PoolManager.sol`
- `contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol`
- `contracts/protocols/dexes/uniswap/v4/base/DeltaResolver.sol`
- `contracts/protocols/dexes/uniswap/v4/hooks/public/base/BaseTokenWrapperHook.sol`
- `contracts/protocols/dexes/uniswap/v4/hooks/public/WETHHook.sol`
- `contracts/protocols/dexes/uniswap/v4/hooks/public/WstETHHook.sol`
- `contracts/protocols/dexes/uniswap/v4/hooks/public/dependencies/v4-core/test/PoolSwapTest.sol`
- `contracts/protocols/dexes/uniswap/v4/hooks/public/dependencies/v4-core/test/PoolModifyLiquidityTest.sol`

## 1. The Right Mental Model

The first important point is that Uniswap v4 does not behave like a naive pair contract that immediately transfers tokens in and out inside `swap`.

In this implementation, the PoolManager is an accounting engine plus a settlement hub.

- Pools store price, tick, liquidity, fee, and position accounting.
- The PoolManager tracks per-address currency deltas during an `unlock` session.
- Actual ERC20 and native token movement is deferred until the caller resolves those deltas with `settle`, `take`, `mint`, `burn`, or `clear`.

The core invariant is enforced in `PoolManager.unlock`:

- the manager is unlocked
- the caller executes arbitrary pool actions in `unlockCallback`
- all open deltas must net out to zero before the manager relocks
- otherwise it reverts with `CurrencyNotSettled()`

That means the system is transient-accounting first, token-transfer second.

## 2. What A Pool "Contains"

There are really three distinct notions of value here:

1. Pool state
2. PoolManager token balances
3. Per-address transient deltas during `unlock`

They are related, but they are not the same thing.

### 2.1 Pool state

Each pool tracks virtual AMM state and LP positions. That state determines pricing, fee accrual, and how much a caller owes or is owed after a swap or liquidity modification.

### 2.2 PoolManager token balances

The PoolManager contract is the custody point for settled currencies. It can also temporarily send tokens out during an unlocked action via `take`, then require them to come back via `settle` before the unlock closes.

### 2.3 Transient deltas

During an unlocked execution, addresses accumulate signed deltas per currency.

- Negative delta: that address owes the PoolManager that currency.
- Positive delta: the PoolManager owes that address that currency.

This is why the manager can support flash-loan-like flows. `take` can send currency out before final payment, but the overall unlock must still end flat.

## 3. When Tokens Actually Move

This is the most important lifecycle rule.

### 3.1 `swap` and `modifyLiquidity` do not directly settle the user

`PoolManager.swap` and `PoolManager.modifyLiquidity` do accounting and hook dispatch. They do not themselves collect the caller's ERC20 input by calling `transferFrom`, and they do not automatically push output tokens to the caller.

Instead, they produce deltas, and then the caller's unlock callback must resolve them.

The test routers in this repo show the intended integration pattern clearly:

- `PoolSwapTest.unlockCallback`
- `PoolModifyLiquidityTest.unlockCallback`

Those callbacks:

1. call `manager.swap(...)` or `manager.modifyLiquidity(...)`
2. inspect resulting deltas
3. if a delta is negative, call `settle(...)`
4. if a delta is positive, call `take(...)`

### 3.2 ERC20 settlement is explicit

For ERC20s, settlement follows the `sync -> transfer -> settle` pattern.

From `DeltaResolver._settle`:

1. `poolManager.sync(currency)` snapshots the manager's current ERC20 balance
2. tokens are transferred to the PoolManager
3. `poolManager.settle()` computes how much actually arrived and credits that amount

This is deliberate. The manager does not trust a nominal requested amount; it trusts the observed post-transfer balance delta.

### 3.3 Native settlement is explicit too

For native currency, `settle{value: amount}()` uses `msg.value` instead of an ERC20 balance delta.

### 3.4 Output transfers are explicit

If an address has positive delta, the unlock callback can:

- call `take(currency, to, amount)` to receive the actual token now
- or in some integrations, turn that value into ERC6909 claims via `mint`

So receiving output is also a conscious settlement action, not an automatic side effect of `swap`.

## 4. Swap Lifecycle

The swap lifecycle in Crane's v4 port is:

### 4.1 Unlock starts the session

The integrator calls `PoolManager.unlock(data)`.

The manager:

- checks it is not already unlocked
- marks itself unlocked
- invokes `IUnlockCallback(msg.sender).unlockCallback(data)`
- requires `NonzeroDeltaCount == 0` before relocking

Everything interesting happens inside that callback.

### 4.2 The callback calls `swap`

Inside the callback, the integrator calls `manager.swap(key, params, hookData)`.

`PoolManager.swap` does this in order:

1. validate nonzero `amountSpecified`
2. load pool state and ensure pool is initialized
3. call `hooks.beforeSwap(...)`
4. compute the actual swap in `_swap(...)`
5. emit `Swap`
6. call `hooks.afterSwap(...)`
7. account hook deltas if any
8. account caller delta to `msg.sender`

Important consequence: hooks can change the effective swap amount before the core swap runs, and can also alter final deltas after the swap.

### 4.3 Hook phase can transform the assets

Wrapper hooks use `beforeSwap` to pre-process the trade.

`BaseTokenWrapperHook._beforeSwap` can:

- determine whether the trade direction is wrapping or unwrapping
- compute exact input or exact output requirements
- call `_deposit` or `_withdraw`
- return a `BeforeSwapDelta` that changes what the core pool swap sees

This is how a pool can present a wrapper/underlying pair while still performing actual wrap/unwrap logic inside the transaction.

### 4.4 The core pool computes deltas, not transfers

The pool's swap math returns a `BalanceDelta`.

That delta tells the manager, and later the integrator, who owes what.

Only after the delta is known does the unlock callback settle:

- negative deltas via `settle`
- positive deltas via `take`

### 4.5 Unlock must end flat

If any currency delta remains nonzero when the callback returns, `unlock` reverts.

That means every wrapper step, external protocol interaction, and user payment must complete atomically inside the same unlock session.

## 5. Add / Remove Liquidity Lifecycle

Liquidity modification follows the same unlock-and-delta pattern.

### 5.1 Modify liquidity happens inside `unlock`

The caller enters through `unlock`, then calls `manager.modifyLiquidity(...)` inside the callback.

`PoolManager.modifyLiquidity` does this in order:

1. load and validate pool
2. call `hooks.beforeModifyLiquidity(...)`
3. call the pool's `modifyLiquidity(...)`
4. compute principal delta and fees accrued
5. emit `ModifyLiquidity`
6. call `hooks.afterModifyLiquidity(...)`
7. account hook delta if any
8. account caller delta

### 5.2 Adding liquidity

When adding liquidity, the caller usually ends with negative deltas in one or both pool currencies. Those must be settled before unlock completes.

The manager does not pull the deposit automatically. The callback must explicitly settle the required amounts.

### 5.3 Removing liquidity

When removing liquidity, the caller usually ends with positive deltas in one or both currencies. The callback can then `take` those outputs.

### 5.4 LP lifecycle is still bounded by settlement

Even though positions are accounted in pool state, all value movements still obey the same unlock invariant: by the end of the callback, all deltas must be resolved.

## 6. What The PoolManager Must Actually Hold

This is where many mental models go wrong.

### 6.1 It does not need static per-pool reserves at every instant

Because v4 uses transient deltas, the manager can momentarily send tokens out during an unlock and receive them back later in the same unlock.

So the manager does not need to maintain a simplistic "this pool always has exactly these tokens sitting untouched" model during execution.

### 6.2 It does need real final settlement in actual pool currencies

However, by the time unlock finishes, all owed amounts must be settled in the actual currencies whose deltas are open.

That means the system cannot merely pretend that one wrapper is equivalent to another.

Examples:

- If the open debt is in `stETH`, you must settle `stETH`, not `wstETH`.
- If the open debt is in `WETH`, you must settle `WETH`, not raw ETH, unless a hook or callback converts it before settlement.
- If the user is owed a positive delta in `token0`, `take(token0, ...)` must transfer real `token0` or mint its claim representation.

So the answer to "what must the vault actually contain" is:

- not necessarily the final assets throughout the entire transaction
- but yes, the manager must end the unlock with actual settlement in the currencies whose deltas remain open

### 6.3 Balances are global to the manager, not siloed per pool during settlement

Settlement is against the PoolManager's custody, not against an isolated vault balance attached to one pool instance.

That is why the manager can support cross-step netting and flash-like flows inside one unlock, but it still must be globally solvent in the currencies that need to leave custody.

## 7. Wrapper Hooks: What Is Feasible

Wrapper hooks are absolutely feasible in this model, but only under strict conditions.

### 7.1 The happy path

The WETH and wstETH hooks show the intended pattern.

For wrapping:

1. the hook `take`s the input currency from the manager
2. it performs the wrap
3. it `settle`s the output currency back into the manager
4. it returns a `BeforeSwapDelta` so the core pool accounting stays coherent

For unwrapping:

1. the hook `take`s the wrapped token from the manager
2. it performs the unwrap
3. it `settle`s the underlying currency back into the manager
4. it returns the corresponding delta adjustments

This is atomic and compatible with v4 because all of it happens during the same unlock.

### 7.2 Hard limitations of wrapper pools

`BaseTokenWrapperHook` imposes several important constraints:

- pool must contain exactly the underlying and wrapper currencies
- pool fee must be zero
- liquidity add is blocked
- liquidity remove is not specially handled by the wrapper hook, and is not part of the intended wrapper-pool model

So these wrapper pools are not generic AMMs with arbitrary LP behavior. They are special transformation pools.

### 7.3 Exact output may be impossible

`WstETHHook` disables exact output because the exchange rate and rounding behavior make exact output semantics unsafe or impractical.

This is a general wrapper limitation:

- exact input is usually easier because you know what you received and can transform it
- exact output is harder if the wrapper has rounding, rebase behavior, fees, slippage, or state-dependent conversion ratios

### 7.4 The hook must be able to source the real input token inside the unlock

If the hook needs to unwrap or wrap, it must be able to actually obtain the starting asset from the manager or from its own balance during the same transaction.

That means:

- no asynchronous redemption flows
- no delayed bridge finality
- no offchain settlement dependency
- no conversion that requires a separate transaction later

If the conversion is not atomic, it does not fit this lifecycle.

## 8. Can You Hold Assets In Other Wrappers And Still Swap?

Yes, but only in a narrow, explicit sense.

### 8.1 Feasible case

It is feasible if all of the following are true:

1. the hook can atomically obtain the owed input asset
2. the hook can atomically wrap or unwrap into the actual pool currency
3. the hook can settle the actual resulting currency back to the PoolManager before unlock ends
4. the wrapper's conversion semantics are deterministic enough for the swap mode being offered

This is exactly what `WETHHook` and `WstETHHook` are doing.

### 8.2 Not feasible case

It is not feasible if the system wants to rely on a wrapper as a mere accounting substitute.

Examples of not feasible behavior:

- pool debt is in `token`, but the system only holds `wrappedToken` and never unwraps before settlement
- the unwrap requires delayed redemption
- the wrapper has withdrawal windows or queued exits
- the output token can only be sourced from inventory outside the transaction

In those cases, the swap may be representable economically, but it is not valid for PoolManager settlement because the open delta is in the wrong currency.

### 8.3 Important distinction: economic exposure vs settlement currency

Holding a wrapper may give the same economic exposure as holding the underlying, but that does not make it a valid settlement asset for v4.

The manager settles in concrete currencies, not abstract equivalence classes.

If you want to trade against a wrapper while settling the underlying, the hook must explicitly do the conversion.

## 9. Practical Constraints For A Vault Or Strategy

If by "vault" you mean a strategy or account integrating with this v4 system, the practical requirements are:

### 9.1 For plain swaps

- you do not need to transfer tokens before calling `swap`
- you do need to resolve all negative deltas before unlock ends
- you can take all positive deltas before unlock ends

### 9.2 For liquidity changes

- adding liquidity requires you to settle whatever currencies the position deposit owes
- removing liquidity gives you positive deltas that you can take or convert to claims

### 9.3 For wrapper-based swaps

- the strategy can hold alternate forms only if the hook can atomically convert them into the required settlement currency
- the strategy cannot rely on "equivalent" wrappers without actual conversion
- wrappers with non-1:1 ratios, rebasing, rounding, or delayed redemption often constrain exact-output support

### 9.4 For solvency

You can be transiently underfunded in a particular currency during the middle of an unlock only if the net process of `take`, external action, and `settle` closes the delta before the callback returns.

You cannot finish the unlock undercollateralized in any open currency.

## 10. Bottom Line

The full lifecycle is:

1. enter `unlock`
2. perform `swap` or `modifyLiquidity`
3. let hooks optionally transform the trade
4. observe resulting deltas
5. settle negative deltas with actual token transfers
6. take positive deltas as actual tokens or claims
7. end with all deltas netted to zero

The key limitations are:

- the manager only accepts real settlement in the actual owed currency
- token movement is explicit and deferred, not automatic inside `swap`
- wrapper support is feasible only when conversion is atomic and settlement-compatible
- economic equivalence between wrappers does not replace settlement in the correct token
- special wrapper pools are much more constrained than ordinary LP pools

The core design implication is that v4 is flexible enough to support wrap/unwrap-as-part-of-swap, but only if the hook can transform custody and settlement atomically inside one unlock session.
