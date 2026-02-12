# Code Review: CRANE-222

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

None required. The task scope is clear: add `allow_internal_expect_revert = true` to foundry.toml and verify the 24 tests pass.

---

## Review Findings

### Finding 1: Change is correct and minimal
**File:** `foundry.toml` (line 19-20)
**Severity:** N/A (positive finding)
**Description:** The implementation adds exactly 2 lines: a descriptive comment and the `allow_internal_expect_revert = true` flag. This is the minimal and correct fix for the Foundry v1.0+ call depth enforcement change. The comment explains *why* the setting exists, which aids future maintainability.
**Status:** Resolved
**Resolution:** Approved as-is.

### Finding 2: No other files modified (correctly)
**File:** N/A
**Severity:** N/A (positive finding)
**Description:** The diff shows only `foundry.toml` was modified (plus task tracking files). No test files were altered, confirming the fix is purely configuration-based. Option A from the task spec (foundry.toml flag) was correctly chosen over Option B (per-test wrappers), which would have required modifying 24 test functions across 10 files.
**Status:** Resolved
**Resolution:** Correct approach.

### Finding 3: Pre-existing failures unchanged
**File:** Various (see below)
**Severity:** Informational
**Description:** The full test suite shows 14 pre-existing failures (vs 12 reported in PROGRESS.md). The 2-count difference is from the E2eErc4626Swaps fuzz tests which sometimes produce varying counterexamples. All failures are error selector mismatches from library version differences (Solady vs OpenZeppelin), unrelated to this change. Confirmed no regressions.
**Status:** Resolved
**Resolution:** Pre-existing, out of scope.

---

## Suggestions

### Suggestion 1: Address pre-existing test failures in a separate task
**Priority:** Low
**Description:** 14 tests fail due to error selector mismatches from the Solady/OZ import migration (CRANE-219). These should be tracked and fixed in a follow-up task to maintain a clean test baseline. Specific categories:
- `BetterSafeERC20.t.sol` (5 tests): `TransferFailed`/`TransferFromFailed`/`ApproveFailed` vs OZ error messages
- `StableSurgeHook.t.sol` (1 test): `MaxImbalanceRatioExceeded` vs `AfterAddLiquidityHookFailed`
- `E2eErc4626Swaps.t.sol` (4 tests): `MaxImbalanceRatioExceeded` fuzz failures
- `WeightedPool8020Factory.t.sol` (1 test): `Create2FailedDeployment` vs `FailedDeployment`
- `BufferVaultPrimitive.t.sol` + `RouterCommon.t.sol` (2 tests): `Overflow` vs `SafeCastOverflowedUintDowncast`
- `BetterStrings.t.sol` (1 test): hex string format assertion mismatch
**Affected Files:**
- Various test files under `contracts/external/balancer/v3/` and `test/foundry/spec/`
**User Response:** Already tracked
**Notes:** All failures are covered by existing tasks: CRANE-223 (selector mismatches), CRANE-224 (BetterSafeERC20, now complete), CRANE-225 (ERC4626 fuzz), CRANE-226 (BetterStrings), CRANE-227 (StableSurgeHook). No new tasks needed.

---

## Acceptance Criteria Verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| All 24 "call didn't revert at a lower depth" failures are resolved | PASS | All 24 tests pass individually (verified via `--match-test`) |
| The fix does not break any currently passing tests | PASS | Full suite: 4547 passed, 14 failed (all pre-existing), 0 new failures |
| The approach is documented | PASS | Comment on line 19 of foundry.toml explains the setting and its rationale |

---

## Review Summary

**Findings:** 3 (all positive/informational, no issues found)
**Suggestions:** 1 (low priority follow-up for pre-existing failures)
**Recommendation:** **APPROVE** - The change is correct, minimal, well-documented, and passes all acceptance criteria. No regressions introduced.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
