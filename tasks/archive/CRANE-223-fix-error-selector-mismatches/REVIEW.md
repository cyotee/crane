# Code Review: CRANE-223

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

None needed. Requirements and implementation are straightforward.

---

## Review Findings

### Finding 1: All error selector changes are correct and trace to runtime code paths
**File:** All 4 modified files
**Severity:** N/A (positive finding)
**Description:** Each error selector change was verified against the actual runtime revert path:

1. **BufferVaultPrimitive.t.sol** - `SafeCastLib.Overflow.selector` correctly matches `SafeCastLib.sol:14` `error Overflow()`. The production code in `BatchRouterHooks.sol` calls `.toUint160()` through the `SafeCast` wrapper which delegates to `SafeCastLib`. The old `SafeCastOverflowedUintDowncast(uint8,uint256)` error was declared in the wrapper but never thrown.

2. **RouterCommon.t.sol** - Same pattern. `RouterCommon.sol:279` calls `amountIn.toUint160()` through `SafeCast` -> `SafeCastLib`. Overflow correctly reverts with `SafeCastLib.Overflow()`.

3. **WeightedPool8020Factory.t.sol** - `Create2.Create2FailedDeployment.selector` correctly matches `Create2.sol:24`. The deployment path is: `WeightedPool8020Factory.create()` -> `BasePoolFactory._create()` -> `BaseSplitCodeFactory` -> `Create2.deploy()`. When CREATE2 fails (duplicate salt), `Create2FailedDeployment()` reverts. The old `Errors.FailedDeployment` import was correctly removed (no remaining references).

4. **StableSurgeHook.t.sol** - `StableMath.MaxImbalanceRatioExceeded.selector` correctly matches `StableMath.sol:22,303`. The `computeBalance()` function reverts with `MaxImbalanceRatioExceeded()` during the pool math computation, **before** the vault reaches the `afterAddLiquidity` hook callback. The vault never wraps this as `AfterAddLiquidityHookFailed` because the revert propagates directly from pool math.

**Status:** Resolved
**Resolution:** All changes are correct.

### Finding 2: No stale imports remain
**File:** All 4 modified files
**Severity:** N/A (positive finding)
**Description:** Verified no residual references to old error sources:
- No `SafeCast.` references in BufferVaultPrimitive.t.sol or RouterCommon.t.sol
- No `Errors.` references in WeightedPool8020Factory.t.sol
- `Create2` import at line 8 was already present (pre-existing, now used for error selector)
- `StableMath` import at line 17 was already present (pre-existing, now used for error selector)
**Status:** Resolved

### Finding 3: Test-only changes, no production code modified
**File:** All 4 modified files
**Severity:** N/A (positive finding)
**Description:** All changes are confined to test files (`*.t.sol`). No production Solidity code was modified. Changes are limited to:
- 2 import swaps (`SafeCast` -> `SafeCastLib`)
- 1 import removal (`Errors`)
- 4 `vm.expectRevert()` argument updates
**Status:** Resolved

---

## Suggestions

### Suggestion 1: Consider documenting the SafeCast wrapper delegation pattern
**Priority:** Low
**Description:** The `SafeCast.sol` wrapper declares `SafeCastOverflowedUintDowncast` but delegates to `SafeCastLib` which throws `Overflow()`. This is a subtlety that could trip up future developers. A brief NatSpec comment in `SafeCast.sol` noting that runtime reverts use `SafeCastLib.Overflow` (not the declared error) would prevent confusion.
**Affected Files:**
- `contracts/utils/SafeCast.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-230

---

## Review Summary

**Findings:** 3 findings, all positive (no issues found)
**Suggestions:** 1 low-priority documentation suggestion
**Recommendation:** APPROVE - All 4 error selector fixes are correct and well-traced to runtime code paths. No stale imports, no production code changes, no regressions. The implementation matches TASK.md requirements exactly.

### Acceptance Criteria Checklist

- [x] All 4 error selector mismatch tests pass (per PROGRESS.md: 4/4 targeted tests PASS)
- [x] Tests import the correct error definitions from Crane libraries
- [x] No other tests broken by the changes (4745/4787 pass, 42 pre-existing failures unrelated)
- [x] No regression in other tests
- [x] Test imports are updated to reference Crane libraries, not OZ

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
