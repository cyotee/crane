# Code Review: CRANE-227

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task scope was well-defined: add an explanatory comment for the error expectation change that was already applied in CRANE-223.

---

## Review Findings

### Finding 1: Comment accurately documents execution order
**File:** `contracts/external/balancer/v3/pool-hooks/test/foundry/StableSurgeHook.t.sol:146-149`
**Severity:** N/A (Positive finding)
**Description:** The 4-line comment correctly explains that `StableMath.ensureBalancesWithinMaxImbalanceRange()` reverts before the Vault calls `onAfterAddLiquidity`, and that the 10:100,000 ratio (10,000x) hits the `MAX_IMBALANCE_RATIO` guard (value: 10,000) first. This is verified by examining `StableMath.sol:300-304` where `maxBalance / minBalance >= 10_000` triggers the revert.
**Status:** Resolved
**Resolution:** Correct as implemented.

### Finding 2: Error selector is correct
**File:** `contracts/external/balancer/v3/pool-hooks/test/foundry/StableSurgeHook.t.sol:150`
**Severity:** N/A (Positive finding)
**Description:** `vm.expectRevert(StableMath.MaxImbalanceRatioExceeded.selector)` matches the error defined in `StableMath.sol:22` and thrown at `StableMath.sol:303`. The test ratios (10e18 : 100_000e18 = 10,000x) exactly hit the `>= MAX_IMBALANCE_RATIO` guard. This is the correct error for the given pool state.
**Status:** Resolved
**Resolution:** Correct as implemented.

### Finding 3: Remove liquidity counterpart uses different error (expected)
**File:** `contracts/external/balancer/v3/pool-hooks/test/foundry/StableSurgeHook.t.sol:216`
**Severity:** N/A (Informational)
**Description:** `testRemoveLiquidityWhenSurging` still correctly expects `IVaultErrors.AfterRemoveLiquidityHookFailed.selector` (not `MaxImbalanceRatioExceeded`). This is because the remove liquidity path has a different execution order in the Vault: the pool math for remove does not hit the imbalance guard in the same way, so the hook runs and returns `false`, which the Vault wraps as `AfterRemoveLiquidityHookFailed`. The asymmetry between add and remove paths is correct and expected.
**Status:** Resolved
**Resolution:** No action needed. The asymmetry is inherent to Balancer V3's Vault execution flow.

---

## Suggestions

No suggestions. The change is minimal, correct, and well-documented.

---

## Review Summary

**Findings:** 3 (all positive/informational, 0 issues)
**Suggestions:** 0
**Recommendation:** APPROVE

### Acceptance Criteria Verification

- [x] `testUnbalancedAddLiquidityWhenSurging` passes - Verified (7/7 StableSurgeHook tests pass, plus 9 tests in related test file)
- [x] The fix correctly reflects the actual execution path - The `MaxImbalanceRatioExceeded` error matches the actual revert from `StableMath.ensureBalancesWithinMaxImbalanceRange()` at the 10:100,000 pool ratio
- [x] The reason for the change is documented in a test comment - 4-line comment at lines 146-149 clearly explains the execution order and why the expected error differs from the hook-based error
- [x] No regression in other StableSurgeHook tests - All 16 tests across both test files pass (7 + 9)

### Diff Summary

The only change is the addition of 4 comment lines (146-149) before the existing `vm.expectRevert` call. No logic was modified. The error selector was already corrected in a prior commit (CRANE-223, commit `8cc185bb`).

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
