Balancer V3 Lifecycle Summary
Swap Lifecycle
Handles token exchanges within a pool.

Entry: Vault.swap(PoolSwapParams, SwapKind, pool, ...)
Checks: onlyWhenUnlocked, withInitializedPool, whenVaultNotPaused.
Input: Tokens, amount, kind (EXACT_IN/EXACT_OUT), limits, userData.


Setup: Opens transient accounting (_isUnlocked().tstore(true)).
Dynamic Fee: Calls callComputeDynamicSwapFeeHook if enabled.
Before Swap Hook: Calls callBeforeSwapHook if shouldCallBeforeSwap.
Core Swap:
Loads PoolData (_loadPoolDataUpdatingBalancesAndYieldFees).
Computes amounts via IBasePool.onSwap.
Debits tokenIn (_takeDebt), credits tokenOut (_supplyCredit).


After Swap Hook: Calls callAfterSwapHook if shouldCallAfterSwap and enableHookAdjustedAmounts.
Updates: Writes _poolTokenBalances, charges fees to _aggregateFeeAmounts.
Transfers: Receives tokenIn, sends tokenOut.
Final: Verifies limits, closes accounting, emits Swap.

Storage:

Transient: _tokenDeltas, _nonZeroDeltaCount.
Persistent: _poolTokenBalances, _aggregateFeeAmounts.

Add Liquidity Lifecycle
Deposits tokens, mints BPT.

Entry: Vault.addLiquidity or VaultExtension.initialize.
Checks: onlyWhenUnlocked, withInitializedPool/withRegisteredPool, nonReentrant.
Input: Pool, tokens, amounts, min BPT out, kind.


Before Hook: Calls callBeforeAddLiquidityHook if enabled.
Core Logic:
Initialization: Debits tokens, computes BPT, mints BPT, sets isPoolInitialized.
Unbalanced: Scales amounts, calls IBasePool.onAddLiquidity, debits tokens, mints BPT.


After Hook: Calls callAfterAddLiquidityHook if enabled.
Updates: Writes _poolTokenBalances, updates fees.
Transfers: Receives input tokens.
Final: Verifies BPT out, emits LiquidityAdded.

Storage:

Transient: _tokenDeltas, _addLiquidityCalled.
Persistent: _poolTokenBalances, _aggregateFeeAmounts, _totalSupply.

Remove Liquidity Lifecycle
Burns BPT, withdraws tokens.

Entry: Vault.removeLiquidity or VaultExtension.removeLiquidityRecovery.
Checks: onlyWhenUnlocked, withInitializedPool, nonReentrant, onlyInRecoveryMode (recovery).
Input: Pool, BPT amount, min amounts out, kind.


Before Hook: Calls callBeforeRemoveLiquidityHook if enabled.
Core Logic:
Standard: Calls IBasePool.onRemoveLiquidity, credits tokens, burns BPT.
Recovery: Computes proportional amounts, applies fees, credits tokens, burns BPT.


After Hook: Calls callAfterRemoveLiquidityHook if enabled.
Updates: Writes _poolTokenBalances, updates fees.
Transfers: Sends output tokens.
Final: Verifies amounts out, emits LiquidityRemoved.

Storage:

Transient: _tokenDeltas.
Persistent: _poolTokenBalances, _aggregateFeeAmounts, _totalSupply.

