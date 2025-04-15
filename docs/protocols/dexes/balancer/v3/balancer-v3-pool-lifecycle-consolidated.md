# Balancer V3 Pool Lifecycle (Consolidated)

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Reference / Summary Table](#quick-reference--summary-table)
3. [Detailed Lifecycle](#detailed-lifecycle)
    - [Swap Lifecycle](#swap-lifecycle)
    - [Add Liquidity Lifecycle](#add-liquidity-lifecycle)
    - [Remove Liquidity Lifecycle](#remove-liquidity-lifecycle)
4. [Advanced Patterns & Troubleshooting](#advanced-patterns--troubleshooting)
5. [References](#references)

---

## Introduction

This document is the single source of truth for the lifecycle of Balancer V3 pools in the Crane framework. It covers registration, initialization, swapping, adding/removing liquidity, extensibility via hooks, and advanced integration patterns. Use this as your primary reference for both onboarding and advanced development.

---

## Quick Reference / Summary Table

### Pool Lifecycle Stages

| Stage            | Entry Point(s)                | Key Checks/Actions                 | Hooks/Extensibility           |
|------------------|-----------------------------|------------------------------------|-------------------------------|
| Registration     | VaultExtension.registerPool | Token validation, config, events   | onRegister                    |
| Initialization   | VaultExtension.initialize   | Set balances, compute invariant    | onBefore/AfterInitialize      |
| Swap             | Vault.swap                  | Validate, compute, update balances | onBefore/AfterSwap, dynamic   |
| Add Liquidity    | Vault.addLiquidity/init     | Validate, compute, mint BPT        | onBefore/AfterAddLiquidity    |
| Remove Liquidity | Vault.removeLiquidity       | Validate, compute, burn BPT        | onBefore/AfterRemoveLiquidity |

See [Detailed Lifecycle](#detailed-lifecycle) for step-by-step breakdowns.

---

## Detailed Lifecycle

### Swap Lifecycle

The swap operation allows users to exchange one token for another within a pool. It is initiated via the Router, which calls the Vault. The process involves validation, hook calls, pool computation, and Vault accounting, with extensibility for custom logic via hooks.

**Step-by-step:**

1. **Router Entry:**
   - User calls `swapSingleToken` on the Router.
   - Validates input, handles token permissions, wraps ETH if needed.
   - Calls `Vault.swap`.
2. **Vault Validation:**
   - Ensures Vault is unlocked, pool is initialized, not paused.
   - Loads pool data and updates balances/fees.
3. **Before Swap Hook (optional):**
   - If enabled, calls `onBeforeSwap` on the hook contract.
   - Hooks can interact with external protocols, take/add tokens via `sendTo`/`settle` (must settle all deltas).
4. **Dynamic Swap Fee Hook (optional):**
   - If enabled, calls `onComputeDynamicSwapFee` for dynamic fee calculation.
5. **Pool Swap Computation:**
   - Calls `onSwap` on the pool to compute output amount.
   - Pools can implement custom logic, but must settle any token movements.
6. **Vault Accounting:**
   - Validates swap amounts, updates token deltas, charges fees, updates balances, emits `Swap` event.
7. **After Swap Hook (optional):**
   - If enabled, calls `onAfterSwap` on the hook contract.
   - Can adjust swap result, interact with external protocols, must settle all deltas.
8. **Router Finalization:**
   - Sends output tokens to user, returns swap results.

*See [Advanced Patterns & Troubleshooting](#advanced-patterns--troubleshooting) for token settlement, EXACT_IN vs. EXACT_OUT, and error handling.*

---

### Add Liquidity Lifecycle

Adding liquidity allows users to deposit tokens into a pool to receive BPT (pool tokens). The process is initiated via the Router and involves validation, hook calls, pool computation, and Vault accounting.

**Step-by-step:**

1. **Router Entry:**
   - User calls `addLiquidity` on the Router.
   - Validates input, handles token permissions, wraps ETH if needed.
   - Calls `Vault.addLiquidity`.
2. **Vault Validation:**
   - Ensures Vault is unlocked, pool is initialized, not paused.
   - Loads pool data, updates balances/fees, scales input amounts.
3. **Before Add Liquidity Hook (optional):**
   - If enabled, calls `onBeforeAddLiquidity` on the hook contract.
   - Hooks can interact with external protocols, take/add tokens via `sendTo`/`settle` (must settle all deltas).
4. **Pool Liquidity Computation:**
   - Depending on liquidity kind (proportional, unbalanced, custom), computes token amounts and BPT out.
   - For custom kinds, pool's `onAddLiquidityCustom` can interact with external protocols (must settle all deltas).
5. **Vault Accounting:**
   - Validates BPT out, debits tokens, charges fees, updates balances, mints BPT, emits `LiquidityAdded` event.
6. **After Add Liquidity Hook (optional):**
   - If enabled, calls `onAfterAddLiquidity` on the hook contract.
   - Can adjust final amounts, interact with external protocols, must settle all deltas.
7. **Router Finalization:**
   - Returns results to user.

*See [Advanced Patterns & Troubleshooting](#advanced-patterns--troubleshooting) for custom liquidity logic and settlement details.*

---

### Remove Liquidity Lifecycle

Removing liquidity allows users to burn BPT to withdraw tokens from a pool. The process is initiated via the Router and involves validation, hook calls, pool computation, and Vault accounting.

**Step-by-step:**

1. **Router Entry:**
   - User calls `removeLiquidity` on the Router.
   - Validates input, handles BPT permissions.
   - Calls `Vault.removeLiquidity`.
2. **Vault Validation:**
   - Ensures Vault is unlocked, pool is initialized, not paused.
   - Loads pool data, updates balances/fees, scales output amounts.
3. **Before Remove Liquidity Hook (optional):**
   - If enabled, calls `onBeforeRemoveLiquidity` on the hook contract.
   - Hooks can interact with external protocols, take/add tokens via `sendTo`/`settle` (must settle all deltas).
4. **Pool Liquidity Computation:**
   - Depending on liquidity kind (proportional, single token, custom), computes BPT in and token amounts out.
   - For custom kinds, pool's `onRemoveLiquidityCustom` can interact with external protocols (must settle all deltas).
5. **Vault Accounting:**
   - Validates BPT in, credits tokens, charges fees, updates balances, burns BPT, emits `LiquidityRemoved` event.
6. **After Remove Liquidity Hook (optional):**
   - If enabled, calls `onAfterRemoveLiquidity` on the hook contract.
   - Can adjust final amounts, interact with external protocols, must settle all deltas.
7. **Router Finalization:**
   - Returns results to user.

*See [Advanced Patterns & Troubleshooting](#advanced-patterns--troubleshooting) for custom removal logic and settlement details.*

---

## Advanced Patterns & Troubleshooting

### Token Settlement and Hook Patterns

- **Token Movements:**
  - Hooks can use `sendTo` to withdraw tokens from the Vault and `settle` to deposit tokens back, typically during before/after hooks.
  - All token deltas must be settled by the end of the operation, or the Vault will revert with `BalanceNotSettled`.
  - Pools generally do not move tokens directly during `onSwap` or liquidity functions, but custom logic can trigger reentrant calls to `Vault.unlock` for settlement.

- **Settlement Timing:**
  - Tokens transferred to the Vault (e.g., via hooks) must be settled with `Vault.settle` before the operation finalizes.
  - Failure to settle all deltas results in a revert and no state change.

### EXACT_IN vs. EXACT_OUT Swaps

| Aspect         | EXACT_IN                        | EXACT_OUT                       |
|---------------|----------------------------------|----------------------------------|
| User Input    | Exact input amount (`amountIn`)  | Exact output amount (`amountOut`)|
| Computed      | Output amount (`amountOut`)      | Input amount (`amountIn`)        |
| Fee Timing    | Deducted from input before swap  | Added to input after swap        |
| Fee Impact    | Reduces effective input          | Increases total input            |
| Limit Check   | `amountOut >= minAmountOut`      | `amountIn <= maxAmountIn`        |
| Rounding      | Output rounded down              | Input rounded up                 |

- **Practical Tip:**
  - For EXACT_OUT, ensure the pool has sufficient reserves of the output token, or the Vault will revert with an underflow error.

### Common Troubleshooting Scenarios

- **Vault Fails After onSwap but Before onAfterSwap:**
  - Most often caused by insufficient pool balances, incorrect fee handling, or token index errors.
  - Double-check that your pool's `onSwap` logic and token mappings align with the Vault's expectations.

- **BalanceNotSettled Errors:**
  - Occur when hooks or custom pool logic take tokens from the Vault but do not settle all deltas before the operation ends.
  - Always call `Vault.settle` for any tokens sent to the Vault during a hook or custom pool operation.

- **Token Index Errors:**
  - If the mapping from token index to address is incorrect, the Vault may update the wrong token's balance, causing underflows or overflows.
  - Verify token ordering and index mappings in your pool and hook configurations.

### Best Practices

- **Always Settle Deltas:**
  - Any time a hook or custom pool logic moves tokens, ensure all deltas are settled before the operation completes.

- **Use Hooks for Extensibility:**
  - Leverage before/after hooks for custom logic, external protocol integration, or dynamic fee calculation.

- **Test with Edge Cases:**
  - Test swaps and liquidity operations with minimal and maximal token amounts, and with all supported swap kinds.

- **Consult the [Testing Guide](balancer-v3-testing-guide.md):**
  - For reusable test patterns, setup, and best practices.

---

## References

- Balancer V3 official documentation
- Crane protocol source code
- [See also: Testing Guide](balancer-v3-testing-guide.md) 