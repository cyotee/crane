# Code Review: CRANE-113

**Reviewer:** Claude Opus 4.6
**Review Started:** 2026-02-08
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements are clear and well-scoped.

---

## Review Findings

### Finding 1: No dedicated negative test for LengthMismatch revert
**File:** (test coverage gap)
**Severity:** Low (Informational)
**Description:** There is no test that directly calls `_sortWithWeights` with mismatched array lengths to verify the `LengthMismatch` custom error reverts correctly. The callers (`BalancerV3WeightedPoolDFPkg.calcSalt` and `CowPoolDFPkg.calcSalt`) perform their own length validation with `WeightsTokensMismatch` *before* reaching `_sortWithWeights`, so the library's check acts as defense-in-depth. This is consistent with how other internal utility libraries are tested in the codebase.
**Status:** Resolved (Informational — documented as suggestion)
**Resolution:** The error is structurally unreachable through the current call paths since callers validate first. A dedicated test would strengthen coverage but is not blocking.

### Finding 2: Error parameter semantics are clear and correct
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol:24
**Severity:** None (Positive)
**Description:** The error `LengthMismatch(uint256 expected, uint256 actual)` passes `tokenConfigs.length` as `expected` and `weights.length` as `actual`. This convention is correct — tokenConfigs is the "primary" array that weights must match.
**Status:** Resolved (No issue)
**Resolution:** N/A

### Finding 3: Selector verified correct
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol:22
**Severity:** None (Positive)
**Description:** `@custom:selector 0xab8b67c6` verified via `cast sig "LengthMismatch(uint256,uint256)"` = `0xab8b67c6`. Correct.
**Status:** Resolved (No issue)
**Resolution:** N/A

### Finding 4: No naming collision with Permit2 LengthMismatch
**File:** contracts/interfaces/protocols/utils/permit2/ISignatureTransfer.sol:16
**Severity:** None (Positive)
**Description:** Permit2 defines `error LengthMismatch()` (no parameters) while this is `error LengthMismatch(uint256, uint256)`. Different selectors, different scopes. No collision.
**Status:** Resolved (No issue)
**Resolution:** N/A

### Finding 5: Docstring correction is accurate
**File:** contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol:29-34
**Severity:** None (Positive)
**Description:** The old comment "Work on copies to avoid modifying originals" was factually incorrect for `memory` arrays — `sortedConfigs = tokenConfigs` copies the pointer, not the data. The updated NatSpec correctly documents the in-place sort behavior and the `@return` tags now note "(same memory reference as input)".
**Status:** Resolved (No issue)
**Resolution:** N/A

---

## Suggestions

### Suggestion 1: Add negative test for LengthMismatch revert path
**Priority:** Low
**Description:** Add a test that directly calls `WeightedTokenConfigUtils._sortWithWeights()` with arrays of different lengths and asserts `vm.expectRevert(WeightedTokenConfigUtils.LengthMismatch.selector)`. This would provide direct coverage of the defense-in-depth check. Note: since the function is `internal` to a library, the test would need either a wrapper contract or to test via a call path that doesn't pre-validate lengths.
**Affected Files:**
- New test file (e.g., `test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.t.sol`)
**User Response:** Accepted
**Notes:** Converted to task CRANE-257

---

## Review Summary

**Findings:** 5 findings total — 0 issues, 1 informational (no negative test), 4 positive confirmations
**Suggestions:** 1 low-priority suggestion (add negative test, could fold into CRANE-114)
**Recommendation:** **APPROVE** — All acceptance criteria are met. The implementation is clean, correct, follows Crane conventions (and actually exceeds them with proper NatSpec tags), and all 427 tests pass. The single file change is minimal and well-scoped.

### Acceptance Criteria Checklist

- [x] Create `error LengthMismatch(uint256 expected, uint256 actual);` custom error
- [x] Replace `require(tokenConfigs.length == normalizedWeights.length, "Length mismatch")` with custom error
- [x] Update docstring comment (note that `sortedConfigs = tokenConfigs;` does not copy, it sorts in-place on memory array)
- [x] Tests pass (427 passed, 0 failed)
- [x] Build succeeds

---

**Review complete.**
