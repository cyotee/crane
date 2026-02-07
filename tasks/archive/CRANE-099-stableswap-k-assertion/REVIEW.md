# Code Review: CRANE-099

**Reviewer:** Claude (Opus 4.6)
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements are clear and well-scoped.

---

## Review Findings

### Finding 1: k() wrapper correctly exposes internal _k() for testing
**File:** `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol:360-362`
**Severity:** None (Positive finding)
**Description:** The new `k()` function is a minimal `external view` wrapper that calls `_k(uint256(reserve0), uint256(reserve1))`, passing the current reserves. This mirrors exactly how `_k()` is called internally (e.g., in `setStableSwap` at line 132, `mint` at line 203, `burn` at line 229, and `_swap` at line 351). The function is properly placed directly above `_k()` for co-locality, has clear NatSpec, and is appropriately scoped as a testing-only concern on a test stub contract.
**Status:** Resolved
**Resolution:** Implementation is correct and follows codebase conventions.

### Finding 2: Direct assertEq verifies formula correctness
**File:** `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol:142-143`
**Severity:** None (Positive finding)
**Description:** The test now computes `expectedK` using the cubic invariant formula `xy(x^2 + y^2)` in Solidity (lines 130-139), then retrieves `actualK` via `CamelotPair(address(stablePair)).k()`, and asserts exact equality with `assertEq`. This is a strong assertion -- any change to `_k()` math will cause this test to fail deterministically, unlike the previous approach which only checked that swap outputs were "in range."
**Status:** Resolved
**Resolution:** The direct assertion achieves the stated goal of catching `_k()` regressions.

### Finding 3: Test-side formula mirrors on-chain formula exactly
**File:** `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol:130-139` vs `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol:364-373`
**Severity:** Info
**Description:** The test-side computation (lines 130-139) and the `_k()` implementation (lines 366-370) use the same intermediate steps:
- Normalize: `x = balance * 1e18 / precisionMultiplier`
- `a = (x * y) / 1e18`
- `b = (x^2 / 1e18) + (y^2 / 1e18)`
- `k = (a * b) / 1e18`

This is correct for verifying consistency. The `_calculateK()` helper (line 691-706) used elsewhere in the test file also matches this formula, so all K calculations in the test file are self-consistent.
**Status:** Resolved
**Resolution:** The formula replication is intentional and necessary for the assertion pattern. The test validates that the on-chain implementation matches the expected cubic invariant.

### Finding 4: Retained swap-output checks provide defense-in-depth
**File:** `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol:145-157`
**Severity:** None (Positive finding)
**Description:** The existing swap-output range checks (lines 145-157) were retained alongside the new direct assertion. This provides two layers of validation: (1) `_k()` matches the expected formula exactly, and (2) swaps using `_k()` produce outputs in the expected range. Good decision to keep both.
**Status:** Resolved
**Resolution:** No action needed.

---

## Suggestions

### Suggestion 1: Add k() assertion for non-stable mode
**Priority:** Low
**Description:** The `k()` wrapper could also be tested in constant-product mode (stableSwap=false), where `_k()` returns `balance0 * balance1`. This would provide full branch coverage of `_k()`. Currently, the `test_kCalculation_stableVsConstantProduct` test compares outputs but doesn't directly assert the constant-product K value.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol`
**User Response:** Accepted, Converted to task CRANE-236
**Notes:** Very low priority -- the constant-product branch is trivial (`balance0 * balance1`), and the stable branch is the important one to validate.

### Suggestion 2: Add k() assertion for mixed-decimal pair
**Priority:** Low
**Description:** `test_cubicInvariant_calculation` only tests the 18-decimal pair. Adding a similar direct assertion for the `mixedDecimalPair` (6+8 decimals) would verify that the precision-multiplier normalization in `_k()` works correctly across decimal combinations.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol`
**User Response:** Accepted, Converted to task CRANE-237
**Notes:** Low priority because `_calculateK()` helper already handles different decimals and is exercised by `testFuzz_kPreservation`, but a direct assertion would be more explicit.

---

## Acceptance Criteria Checklist

- [x] Add testing-only view method `k()` on CamelotPair stub returning `_k(reserve0, reserve1)` -- Added at line 360-362
- [x] Update `test_cubicInvariant_calculation()` to compare computed expectedK against stub's `k()` return value -- Lines 142-143 use `assertEq(actualK, expectedK, ...)`
- [x] Assert the formula: `xy(x^2 + y^2)` or equivalent `x^3y + y^3x` -- Test computes formula at lines 130-139
- [x] Test fails if `_k()` math changes unexpectedly -- `assertEq` ensures exact match
- [x] Tests pass -- 19/19 tests pass (verified locally)
- [x] Build succeeds -- `forge build` completes without errors

---

## Review Summary

**Findings:** 4 findings, all positive/informational. No bugs, no security issues, no code quality concerns.
**Suggestions:** 2 low-priority suggestions for extended coverage (mixed decimals, constant-product branch).
**Recommendation:** **APPROVE** -- All acceptance criteria are met. The implementation is minimal, correct, and well-placed. The diff is tight (6 lines added to CamelotPair.sol, ~10 lines modified in the test file), which is appropriate for the scope of the task.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
