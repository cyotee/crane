# Task CRANE-225: Fix E2eErc4626Swaps Fuzz Input Bounds (4 tests)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/erc4626-fuzz-bounds`

---

## Description

4 fuzz tests in `E2eErc4626SwapsStableTest` fail with `MaxImbalanceRatioExceeded` because the `_setPoolBalances()` helper allows liquidity values to create extreme imbalance ratios (up to 10,000:1), which exceeds StableMath's `MAX_IMBALANCE_RATIO` guard. The liquidity bounds need to be tightened to match the base `E2eSwap.t.sol` pattern (10% to 1000% instead of 1% to 10000%).

## Dependencies

- None

## User Stories

### US-CRANE-225.1: Tighten Fuzz Bounds to Avoid Imbalance Guard

As a developer, I want the E2eErc4626Swaps fuzz tests to use realistic liquidity ranges so that fuzzing doesn't hit the imbalance ratio guard with degenerate inputs.

**Acceptance Criteria:**
- [ ] All 4 MaxImbalanceRatioExceeded fuzz failures are resolved
- [ ] Liquidity bounds match the pattern used by E2eSwap.t.sol base class
- [ ] Tests still exercise meaningful value ranges

## Technical Details

### Root Cause

In `_setPoolBalances()` (E2eErc4626Swaps.t.sol), liquidity is bounded:
```solidity
liquidityWaDai = bound(liquidityWaDai,
    erc4626PoolInitialAmount.mulDown(1e16),    // 1%
    erc4626PoolInitialAmount.mulDown(10000e16) // 10000%
);
```

This allows one token at 10000% and another at 1%, creating a 10,000:1 ratio. StableMath checks:
```solidity
if (imbalance >= MAX_IMBALANCE_RATIO) revert MaxImbalanceRatioExceeded();
```

where `MAX_IMBALANCE_RATIO = 10_000`.

### Recommended Fix

Tighten bounds to match base E2eSwap.t.sol:
```solidity
liquidityWaDai = bound(liquidityWaDai,
    erc4626PoolInitialAmount / 10,     // 10%
    10 * erc4626PoolInitialAmount      // 1000%
);
```

### Affected Tests (4 total)

**pool-stable/test/foundry/E2eErc4626Swaps.t.sol:**
- `testDoUndoExactInComplete__Fuzz(uint256,uint256,uint256,uint256)`
- `testDoUndoExactInLiquidity__Fuzz(uint256,uint256)`
- `testDoUndoExactOutComplete__Fuzz(uint256,uint256,uint256,uint256)`
- `testDoUndoExactOutLiquidity__Fuzz(uint256,uint256)`

## Files to Create/Modify

**Modified Files:**
- `contracts/external/balancer/v3/pool-stable/test/foundry/E2eErc4626Swaps.t.sol` - Tighten `_setPoolBalances()` bounds

**Files to Read (for reference):**
- Base E2eSwap.t.sol for the correct bound pattern

## Inventory Check

Before starting, verify:
- [ ] `_setPoolBalances()` method exists with the wide bounds described
- [ ] StableMath MAX_IMBALANCE_RATIO is 10,000
- [ ] Base E2eSwap.t.sol uses tighter bounds (10% to 1000%)

## Completion Criteria

- [ ] All 4 fuzz tests pass with reasonable run counts (256 runs)
- [ ] No regression in the other 5 passing tests in this file
- [ ] Bounds are documented with comments explaining the constraint

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
