Thank you for confirming that you’ve provided all the code. Below is a detailed explanation of the swap, add liquidity, and remove liquidity lifecycles in Balancer V3, based on the provided code (`Router.sol`, `RouterCommon.sol`, `Vault.sol`, `VaultExtension.sol`, `VaultCommon.sol`). This documentation focuses on the lifecycle of each operation, highlighting key points where hooks and pools interact with the Vault, particularly when they can take or add tokens to integrate with external protocols. The explanation avoids referencing any prior designs and is structured to serve as a clear, standalone analysis for future redesign discussions.

---

## Overview
In Balancer V3, the `Router` serves as the primary user-facing interface for interacting with the `Vault`. The `Vault` manages pool operations (swaps, add/remove liquidity) and maintains token balances, while hooks and pools can extend functionality via callbacks. Hooks are external contracts that can modify operation parameters or execute logic at specific points, and pools implement logic for calculating swap amounts or liquidity changes. The lifecycle of each operation involves validation, hook calls, pool interactions, and Vault accounting, with opportunities for hooks and pools to interact with external protocols by taking or adding tokens to the Vault.

Key points for hooks and pools:
- **Hooks** can execute arbitrary logic during `before` and `after` hooks, including interacting with external protocols, provided they settle any token movements with the Vault.
- **Pools** are called during operations to compute amounts (e.g., swap outputs or BPT amounts) and can implement custom logic to interact with external systems in certain cases (e.g., custom liquidity operations).
- **Token Movements**: Both hooks and pools can take tokens from or add tokens to the Vault using `sendTo` (to withdraw tokens) or `settle` (to deposit tokens), typically during reentrant hook or pool callbacks.

Below, we detail the lifecycle for each operation, emphasizing where hooks and pools can interact with the Vault for token movements.

---

## 1. Swap Lifecycle
The swap operation allows users to exchange one token for another within a pool. It is initiated via the `Router.swapSingleToken` function, which calls the `Vault.swap` function. The lifecycle involves validation, hook calls, pool computation, and Vault accounting.

### Steps in the Swap Lifecycle
1. **Router Entry (`Router.swapSingleToken`)**:
   - **Input**: `VaultSwapParams` (pool, swap kind, tokenIn, tokenOut, amountGivenRaw, limitRaw, userData, deadline).
   - Validates inputs (e.g., non-zero amount, valid deadline).
   - Handles token permissions via `Permit2` or direct transfers to the Vault.
   - For ETH swaps, wraps ETH to WETH using `_takeTokenIn`.
   - Calls `Vault.swap` with the swap parameters.

2. **Vault Validation (`Vault.swap`)**:
   - Ensures the Vault is unlocked (`onlyWhenUnlocked`), the pool is initialized (`withInitializedPool`), and not paused (`_ensureUnpaused`).
   - Checks for valid swap parameters (non-zero amount, distinct tokens).
   - Loads pool data (`_loadPoolDataUpdatingBalancesAndYieldFees`), updating balances and yield fees (non-reentrant).

3. **Before Swap Hook (`HooksConfigLib.callBeforeSwapHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallBeforeSwap()` is true (set during pool registration).
   - **Execution**: Calls `onBeforeSwap` on the hook contract (`_hooksContracts[pool]`).
   - **Token Interaction Opportunity**:
     - The hook is reentrant and can call `Vault.unlock` to execute arbitrary logic, including:
       - **Taking Tokens**: Use `Vault.sendTo` to withdraw tokens from the Vault (e.g., to interact with external protocols).
       - **Adding Tokens**: Use `Vault.settle` to deposit tokens into the Vault (e.g., after external protocol interactions).
     - The hook must settle any token deltas by the end of the operation to avoid `BalanceNotSettled` reversion.
   - **Impact**: The hook can modify pool state (e.g., balances, rates) via external calls, so pool data is reloaded afterward.

4. **Dynamic Swap Fee Hook (`HooksConfigLib.callComputeDynamicSwapFeeHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallComputeDynamicSwapFee()` is true.
   - **Execution**: Calls `onComputeDynamicSwapFee` on the hook contract to adjust the swap fee percentage.
   - **Token Interaction Opportunity**:
     - This hook is typically non-reentrant and focused on fee calculation, but if it triggers reentrant calls (e.g., via external protocol interactions), it could use `Vault.unlock` to call `sendTo` or `settle` for token movements.
     - Any token interactions must be settled to maintain Vault consistency.
   - **Impact**: Updates the `swapFeePercentage` used in the swap.

5. **Pool Swap Computation (`Vault._swap`)**:
   - **Execution**: Calls `IBasePool(pool).onSwap` with `PoolSwapParams` (kind, amountGivenScaled18, balancesScaled18, indexIn, indexOut, router, userData).
   - **Logic**:
     - The pool computes the `amountCalculatedScaled18` (e.g., amountOut for EXACT_IN, amountIn for EXACT_OUT).
     - For EXACT_IN, deducts swap fees from `amountGivenScaled18` before computation.
     - For EXACT_OUT, adds fees to `amountCalculatedScaled18` after computation.
   - **Token Interaction Opportunity**:
     - The pool’s `onSwap` is non-reentrant and typically does not directly interact with the Vault for token movements.
     - However, pools can implement custom logic to query external protocols (e.g., oracles) or trigger reentrant calls via `Vault.unlock` to:
       - **Take Tokens**: Call `Vault.sendTo` to withdraw tokens.
       - **Add Tokens**: Call `Vault.settle` to deposit tokens.
     - Any token movements must be settled by the end of the operation.
   - **Output**: Returns `amountCalculatedScaled18`, converted to raw amounts (`amountCalculatedRaw`).

6. **Vault Accounting (`Vault._swap`)**:
   - Validates swap amounts (`_ensureValidSwapAmount`).
   - Updates token deltas:
     - **Debit**: `_takeDebt(tokenIn, amountInRaw)` for tokens entering the Vault.
     - **Credit**: `_supplyCredit(tokenOut, amountOutRaw)` for tokens leaving the Vault.
   - Computes and charges aggregate fees (`_computeAndChargeAggregateSwapFees`).
   - Updates pool balances (`_poolTokenBalances`) for `indexIn` and `indexOut`.
   - Emits a `Swap` event.

7. **After Swap Hook (`HooksConfigLib.callAfterSwapHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallAfterSwap()` is true.
   - **Execution**: Calls `onAfterSwap` on the hook contract, passing swap details and results.
   - **Token Interaction Opportunity**:
     - The hook is reentrant and can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens (e.g., to settle with external protocols).
       - **Add Tokens**: Use `Vault.settle` to deposit tokens (e.g., after external interactions).
     - If `enableHookAdjustedAmounts` is true, the hook can modify `amountCalculatedRaw`, affecting `amountOut` (EXACT_IN) or `amountIn` (EXACT_OUT).
     - All token deltas must be settled to avoid reversion.
   - **Impact**: Can adjust the final swap output, impacting user returns.

8. **Router Finalization (`Router.swapSingleToken`)**:
   - Receives `(amountCalculated, amountIn, amountOut)` from `Vault.swap`.
   - Sends `tokenOut` to the sender using `_sendTokenOut` (unwraps WETH to ETH if needed).
   - Returns `(amountIn, amountOut)` to the user.

### Hook and Pool Token Interaction Points
- **Before Swap Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for token movements with external protocols.
  - **Use Case**: Adjust pool state, fetch external data, or pre-process tokens.
  - **Constraint**: Must settle token deltas by operation end.
- **Dynamic Swap Fee Hook**:
  - **Opportunity**: Limited, but reentrant calls via `Vault.unlock` could enable token movements.
  - **Use Case**: Adjust fees based on external protocol data.
  - **Constraint**: Primarily for fee computation; token interactions are secondary.
- **Pool `onSwap`**:
  - **Opportunity**: Non-reentrant, but custom logic could trigger reentrant `Vault.unlock` calls to `sendTo` or `settle`.
  - **Use Case**: Compute swap amounts using external protocol data (e.g., dynamic pricing).
  - **Constraint**: Must return valid `amountCalculatedScaled18` and settle any token movements.
- **After Swap Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for token adjustments.
  - **Use Case**: Post-process swap results, settle with external protocols, or adjust outputs.
  - **Constraint**: Must settle token deltas; can modify `amountCalculatedRaw` if enabled.

---

## 2. Add Liquidity Lifecycle
The add liquidity operation allows users to deposit tokens into a pool to receive BPT (pool tokens). It is initiated via `Router.addLiquidity`, which calls `Vault.addLiquidity`. The lifecycle involves validation, hook calls, pool computation, and Vault accounting.

### Steps in the Add Liquidity Lifecycle
1. **Router Entry (`Router.addLiquidity` / `addLiquidityProportional` / `addLiquidityUnbalanced`)**:
   - **Input**: `AddLiquidityParams` (pool, to, maxAmountsIn, minBptAmountOut, kind, userData, deadline).
   - Validates inputs (e.g., non-zero amounts, valid deadline).
   - Handles token permissions via `Permit2` or direct transfers.
   - For ETH, wraps to WETH using `_takeTokenIn`.
   - Calls `Vault.addLiquidity` with the parameters.

2. **Vault Validation (`Vault.addLiquidity`)**:
   - Ensures the Vault is unlocked (`onlyWhenUnlocked`), the pool is initialized (`withInitializedPool`), and not paused (`_ensureUnpaused`).
   - Sets a session flag (`_addLiquidityCalled`) to track for round-trip fee checks.
   - Loads pool data (`_loadPoolDataUpdatingBalancesAndYieldFees`), updating balances and yield fees (non-reentrant).
   - Scales `maxAmountsIn` to `maxAmountsInScaled18` (round down).

3. **Before Add Liquidity Hook (`HooksConfigLib.callBeforeAddLiquidityHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallBeforeAddLiquidity()` is true.
   - **Execution**: Calls `onBeforeAddLiquidity` on the hook contract.
   - **Token Interaction Opportunity**:
     - Reentrant, can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens for external protocol interactions.
       - **Add Tokens**: Use `Vault.settle` to deposit tokens after external interactions.
     - Must settle token deltas to avoid `BalanceNotSettled` reversion.
   - **Impact**: Can modify pool state (e.g., balances, rates), so pool data is reloaded.

4. **Pool Liquidity Computation (`Vault._addLiquidity`)**:
   - **Execution**: Depending on `AddLiquidityKind`:
     - **PROPORTIONAL**: Calls `BasePoolMath.computeProportionalAmountsIn` to compute `amountsInScaled18`.
     - **DONATION**: Uses `maxAmountsInScaled18` directly; requires `enableDonation`.
     - **UNBALANCED**: Calls `BasePoolMath.computeAddLiquidityUnbalanced` or pool’s `computeAddLiquidityUnbalanced`.
     - **SINGLE_TOKEN_EXACT_OUT**: Calls `BasePoolMath.computeAddLiquiditySingleTokenExactOut`.
     - **CUSTOM**: Calls `IPoolLiquidity(pool).onAddLiquidityCustom`, passing `maxAmountsInScaled18`, `minBptAmountOut`, `balancesLiveScaled18`, `userData`.
   - **Token Interaction Opportunity**:
     - For `CUSTOM`, the pool’s `onAddLiquidityCustom` is reentrant and can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens for external protocols.
       - **Add Tokens**: Use `Vault.settle` to deposit tokens after external interactions.
     - Other kinds use internal math or non-reentrant pool calls, but pools could trigger reentrant calls via `Vault.unlock`.
     - Must settle token deltas and return valid `amountsInScaled18`, `bptAmountOut`, and `swapFeeAmounts`.
   - **Output**: Returns `amountsInRaw`, `amountsInScaled18`, `bptAmountOut`, and `returnData`.

5. **Vault Accounting (`Vault._addLiquidity`)**:
   - Validates `bptAmountOut` against `minBptAmountOut` and trade amounts.
   - For each token:
     - Scales `amountsInScaled18` to `amountsInRaw` (round up).
     - Checks against `maxAmountsIn`.
     - Debits tokens (`_takeDebt`).
     - Computes and charges fees (`_computeAndChargeAggregateSwapFees`).
     - Updates pool balances (`_writePoolBalancesToStorage`).
   - Mints BPT (`_mint`).
   - Emits a `LiquidityAdded` event.

6. **After Add Liquidity Hook (`HooksConfigLib.callAfterAddLiquidityHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallAfterAddLiquidity()` is true.
   - **Execution**: Calls `onAfterAddLiquidity` on the hook contract.
   - **Token Interaction Opportunity**:
     - Reentrant, can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens (e.g., for external protocol settlement).
       - **Add Tokens**: Use `Vault.settle` to deposit tokens.
     - If `enableHookAdjustedAmounts` is true, the hook can modify `amountsIn`, affecting final token inputs.
     - Must settle token deltas.
   - **Impact**: Can adjust `amountsIn` for the operation.

7. **Router Finalization**:
   - Receives `(amountsIn, bptAmountOut, returnData)` from `Vault.addLiquidity`.
   - Returns results to the user.

### Hook and Pool Token Interaction Points
- **Before Add Liquidity Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external protocol interactions.
  - **Use Case**: Pre-process tokens or adjust pool state.
  - **Constraint**: Must settle token deltas.
- **Pool `onAddLiquidityCustom`** (CUSTOM only):
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external protocol interactions.
  - **Use Case**: Implement custom liquidity logic (e.g., dynamic token sourcing).
  - **Constraint**: Must return valid amounts and settle token deltas.
- **After Add Liquidity Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external adjustments.
  - **Use Case**: Post-process liquidity addition or settle with external protocols.
  - **Constraint**: Must settle token deltas; can modify `amountsIn` if enabled.

---

## 3. Remove Liquidity Lifecycle
The remove liquidity operation allows users to burn BPT to withdraw tokens from a pool. It is initiated via `Router.removeLiquidity`, which calls `Vault.removeLiquidity`. The lifecycle involves validation, hook calls, pool computation, and Vault accounting.

### Steps in the Remove Liquidity Lifecycle
1. **Router Entry (`Router.removeLiquidity` / `removeLiquidityProportional`)**:
   - **Input**: `RemoveLiquidityParams` (pool, from, to, maxBptAmountIn, minAmountsOut, kind, userData, deadline).
   - Validates inputs (e.g., valid deadline).
   - Handles BPT permissions via `Permit2` or direct transfers.
   - Calls `Vault.removeLiquidity` with the parameters.

2. **Vault Validation (`Vault.removeLiquidity`)**:
   - Ensures the Vault is unlocked (`onlyWhenUnlocked`), the pool is initialized (`withInitializedPool`), and not paused (`_ensureUnpaused`).
   - Loads pool data (`_loadPoolDataUpdatingBalancesAndYieldFees`), updating balances and yield fees (non-reentrant).
   - Scales `minAmountsOut` to `minAmountsOutScaled18` (round up).

3. **Before Remove Liquidity Hook (`HooksConfigLib.callBeforeRemoveLiquidityHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallBeforeRemoveLiquidity()` is true.
   - **Execution**: Calls `onBeforeRemoveLiquidity` on the hook contract.
   - **Token Interaction Opportunity**:
     - Reentrant, can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens for external protocols.
       - **Add Tokens**: Use `Vault.settle` to deposit tokens.
     - Must settle token deltas.
   - **Impact**: Can modify pool state, so pool data is reloaded.

4. **Pool Liquidity Computation (`Vault._removeLiquidity`)**:
   - **Execution**: Depending on `RemoveLiquidityKind`:
     - **PROPORTIONAL**: Calls `BasePoolMath.computeProportionalAmountsOut`; applies round-trip fees if `_addLiquidityCalled` is set.
     - **SINGLE_TOKEN_EXACT_IN**: Calls `BasePoolMath.computeRemoveLiquiditySingleTokenExactIn`.
     - **SINGLE_TOKEN_EXACT_OUT**: Calls `BasePoolMath.computeRemoveLiquiditySingleTokenExactOut`.
     - **CUSTOM**: Calls `IPoolLiquidity(pool).onRemoveLiquidityCustom`, passing `maxBptAmountIn`, `minAmountsOutScaled18`, `balancesLiveScaled18`, `userData`.
   - **Token Interaction Opportunity**:
     - For `CUSTOM`, the pool’s `onRemoveLiquidityCustom` is reentrant and can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens for external protocols.
       - **Add Tokens**: Use `Vault.settle` to deposit tokens.
     - Other kinds use internal math or non-reentrant pool calls, but pools could trigger reentrant calls via `Vault.unlock`.
     - Must settle token deltas and return valid `bptAmountIn`, `amountsOutScaled18`, and `swapFeeAmounts`.
   - **Output**: Returns `bptAmountIn`, `amountsOutRaw`, `amountsOutScaled18`, and `returnData`.

5. **Vault Accounting (`Vault._removeLiquidity`)**:
   - Validates `bptAmountIn` against `maxBptAmountIn` and trade amounts.
   - For each token:
     - Scales `amountsOutScaled18` to `amountsOutRaw` (round down).
     - Checks against `minAmountsOut`.
     - Credits tokens (`_supplyCredit`).
     - Computes and charges fees (`_computeAndChargeAggregateSwapFees`).
     - Updates pool balances (`_writePoolBalancesToStorage`).
   - Burns BPT (`_burn` after spending allowance).
   - Emits a `LiquidityRemoved` event.

6. **After Remove Liquidity Hook (`HooksConfigLib.callAfterRemoveLiquidityHook`)**:
   - **Condition**: If `poolConfigBits.shouldCallAfterRemoveLiquidity()` is true.
   - **Execution**: Calls `onAfterRemoveLiquidity` on the hook contract.
   - **Token Interaction Opportunity**:
     - Reentrant, can call `Vault.unlock` to:
       - **Take Tokens**: Use `Vault.sendTo` to withdraw tokens for external protocols.
       - **Add Tokens**: Use `Vault.settle` to deposit tokens.
     - If `enableHookAdjustedAmounts` is true, the hook can modify `amountsOut`, affecting final token outputs.
     - Must settle token deltas.
   - **Impact**: Can adjust `amountsOut` for the operation.

7. **Router Finalization**:
   - Receives `(bptAmountIn, amountsOut, returnData)` from `Vault.removeLiquidity`.
   - Sends tokens to the sender using `_sendTokenOut` (unwraps WETH to ETH if needed).
   - Returns results to the user.

### Hook and Pool Token Interaction Points
- **Before Remove Liquidity Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external protocol interactions.
  - **Use Case**: Pre-process tokens or adjust pool state.
  - **Constraint**: Must settle token deltas.
- **Pool `onRemoveLiquidityCustom`** (CUSTOM only):
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external protocol interactions.
  - **Use Case**: Implement custom withdrawal logic (e.g., dynamic token distribution).
  - **Constraint**: Must return valid amounts and settle token deltas.
- **After Remove Liquidity Hook**:
  - **Opportunity**: Reentrant, can call `Vault.unlock` to execute `sendTo` or `settle` for external adjustments.
  - **Use Case**: Post-process withdrawal or settle with external protocols.
  - **Constraint**: Must settle token deltas; can modify `amountsOut` if enabled.

---

## Key Considerations for External Protocol Integration
- **Reentrancy**: Hooks and custom pool functions (`onAddLiquidityCustom`, `onRemoveLiquidityCustom`) are reentrant, allowing `Vault.unlock` calls to execute arbitrary logic, including token movements via `sendTo` and `settle`. This is the primary mechanism for integrating with external protocols.
- **Token Settlement**: Any tokens taken from or added to the Vault must be settled by the end of the operation to avoid `BalanceNotSettled` reversion. Hooks and pools must carefully manage token deltas.
- **Hook Adjustment**: If `enableHookAdjustedAmounts` is true, `after` hooks can modify operation outputs (e.g., `amountCalculated` for swaps, `amountsIn` for add liquidity, `amountsOut` for remove liquidity), providing flexibility for external protocol interactions.
- **Non-Reentrant Sections**: Pool computations (`onSwap`, non-custom liquidity functions) are non-reentrant, limiting direct token movements unless reentrancy is triggered via `Vault.unlock`.
- **Session Tracking**: The Vault tracks sessions via `_sessionIdSlot` to apply round-trip fees for add/remove liquidity in the same unlock call, which may affect external protocol strategies.
- **Gas and Complexity**: External protocol interactions increase gas costs and complexity, requiring careful optimization to avoid hitting gas limits.

---

## Summary of Token Interaction Opportunities
| **Operation**          | **Hook/Pool**                     | **Reentrant?** | **Token Interaction**                                                                 |
|-------------------------|-----------------------------------|----------------|---------------------------------------------------------------------------------------|
| **Swap**               | Before Swap Hook                 | Yes            | Use `Vault.unlock` to call `sendTo`/`settle` for external protocol interactions.      |
|                        | Dynamic Swap Fee Hook            | Limited        | Possible via reentrant `Vault.unlock` for `sendTo`/`settle`.                          |
|                        | Pool `onSwap`                    | No             | Custom logic can trigger reentrant `Vault.unlock` for `sendTo`/`settle`.              |
|                        | After Swap Hook                  | Yes            | Use `Vault.unlock` to call `sendTo`/`settle`; can adjust `amountCalculated` if enabled. |
| **Add Liquidity**      | Before Add Liquidity Hook        | Yes            | Use `Vault.unlock` to call `sendTo`/`settle` for external protocol interactions.      |
|                        | Pool `onAddLiquidityCustom`      | Yes            | Use `Vault.unlock` to call `sendTo`/`settle` for custom logic.                        |
|                        | After Add Liquidity Hook         | Yes            | Use `Vault.unlock` to call `sendTo`/`settle`; can adjust `amountsIn` if enabled.      |
| **Remove Liquidity**   | Before Remove Liquidity Hook     | Yes            | Use `Vault.unlock` to call `sendTo`/`settle` for external protocol interactions.      |
|                        | Pool `onRemoveLiquidityCustom`   | Yes            | Use `Vault.unlock` to call `sendTo`/`settle` for custom logic.                        |
|                        | After Remove Liquidity Hook      | Yes            | Use `Vault.unlock` to call `sendTo`/`settle`; can adjust `amountsOut` if enabled.     |

---

This analysis provides a comprehensive view of the swap, add liquidity, and remove liquidity lifecycles in Balancer V3, with a focus on where hooks and pools can interact with the Vault to integrate with external protocols. It serves as a foundation for discussing a redesign, highlighting critical points for token movements and constraints to consider. Let me know how you’d like to proceed with the redesign discussion!