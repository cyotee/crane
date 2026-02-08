# Code Review: CRANE-102

**Reviewer:** Claude (Opus 4.6)
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

None needed. Requirements are clear from TASK.md.

---

## Acceptance Criteria Verification

### AC-1: Add test that computes `requiredInput` from `quotedInput` adjustment
**Status:** PASS

All 4 new tests (lines 675-802) compute `requiredInput = (quotedInput * 10000) / (10000 - taxBps)`. This is the correct algebraic inverse of the FoT tax. Verified in:
- `_testFixUpInputAchievesDesiredOutput()` (line 736)
- `testFuzz_fixUpInput_achievesDesiredOutput()` (line 785)

### AC-2: Execute swap with `requiredInput` on fresh pool state
**Status:** PASS

- Deterministic tests use `vm.snapshot()` / `vm.revertTo()` (lines 724, 762), ensuring the pool is in pristine state when the swap executes.
- Fuzz test creates a fresh pair per run via `_createFuzzPair(taxBps)` (line 774).

### AC-3: Assert received output equals (or is within rounding of) `desiredOutput`
**Status:** PASS

Assertion at line 749: `assertGe(actualOutput + 1, desiredOutput)` allows exactly 1 wei of rounding tolerance, which is appropriate given `_purchaseQuote()` uses ceiling division (`+ 1` at line 214 of ConstProdUtils.sol). Same assertion in fuzz test at line 797.

### AC-4: Ensure state isolation (fresh pair per test or snapshot/revert)
**Status:** PASS

- Deterministic: `vm.snapshot()` at line 724, `vm.revertTo()` at line 762.
- Fuzz: fresh pair via `_createFuzzPair()` at line 774.

### AC-5: Tests pass
**Status:** PASS (per PROGRESS.md: 18/18 tests pass)

### AC-6: Build succeeds
**Status:** PASS (per PROGRESS.md: 1694 files compiled)

---

## Review Findings

### Finding 1: Snapshot/Revert is redundant for the deterministic fix-up tests
**File:** CamelotV2_feeOnTransfer.t.sol:724,762
**Severity:** Info (no bug)
**Description:** The three deterministic fix-up tests (`test_fixUpInput_achievesDesiredOutput_{1,5,10}percent`) snapshot and revert pool state. However, each test runs in its own Foundry test context where `setUp()` already provides a clean state. The `vm.revertTo()` at line 762 restores state within the test function, but since Foundry already isolates each `test_*` function, the snapshot/revert is technically redundant. That said, it *does* match the pattern described in TASK.md ("fresh pair per test or snapshot/revert"), is self-documenting about the test's intent, and would be necessary if a test performed multiple swaps within the same function.
**Status:** Resolved (acceptable as-is)
**Resolution:** Matches task specification. Not harmful. Self-documenting intent.

### Finding 2: Fix-up formula slightly over-compensates at very high tax rates
**File:** CamelotV2_feeOnTransfer.t.sol:785
**Severity:** Info (by design)
**Description:** The formula `requiredInput = quotedInput * 10000 / (10000 - taxBps)` is a first-order linear approximation. At very high tax rates (e.g., 50% / 5000 bps), the pool's constant-product curve has already shifted its effective exchange rate, meaning the actual output may slightly exceed `desiredOutput`. This is correct and safe behavior (you get a tiny bit more than desired, not less). The fuzz test bounds tax to 1-5000 bps, which covers the full realistic range. The `assertGe` assertion correctly validates the "at least desired" semantics.
**Status:** Resolved (correct behavior)
**Resolution:** Over-compensation is safe. Under-compensation would be the concern, and the test proves it doesn't happen.

### Finding 3: The 1-wei tolerance assertion is correctly formulated
**File:** CamelotV2_feeOnTransfer.t.sol:749,797
**Severity:** Info (correctness confirmation)
**Description:** The assertion `assertGe(actualOutput + 1, desiredOutput)` is equivalent to `actualOutput >= desiredOutput - 1`. This correctly accounts for integer rounding in the AMM math. The `_purchaseQuote()` function applies `+ 1` ceiling division to ensure the computed input is sufficient, and the AMM's swap uses floor division on output. The net effect is at most 1 wei of rounding loss. This is mathematically sound.
**Status:** Resolved (correct)
**Resolution:** No issue.

---

## Suggestions

### Suggestion 1: Consider adding a fix-up verification for FoT output token scenario
**Priority:** Low
**Description:** The current fix-up tests only verify the case where the FoT token is the *input* token (selling FoT to buy standard). There's a complementary scenario: when the *output* token is FoT, the `_saleQuote()` overestimates because the recipient gets less than the pool sends. A corresponding fix-up for sale quotes could be verified: `requiredOutput = quotedOutput * (10000 - taxBps) / 10000` to get the actual received amount. However, this is a different formula (scaling down, not up) and was not in scope for CRANE-102.
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-241.

### Suggestion 2: Add explicit `assertGt(p.requiredInput, p.quotedInput)` sanity check
**Priority:** Low
**Description:** Adding an assertion that the fix-up input is strictly greater than the quoted input would make the test self-documenting about *why* the fix-up is needed. Currently, this relationship is implied by the math but not explicitly asserted. For example, after line 736: `assertGt(p.requiredInput, p.quotedInput, "Fix-up should exceed naive quote for non-zero tax");`
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-242.

---

## Code Quality Notes

- **Helper reuse:** The new tests correctly reuse existing helpers (`_getReservesForTokenInput`, `_executeSwapForPurchase`, `_createFuzzPair`, `_getReservesForToken`) without unnecessary duplication.
- **Stack-too-deep handling:** The `FixUpTestParams` struct follows the same pattern as `PurchaseQuoteTestParams` and `FuzzTestParams`, which is consistent.
- **NatSpec:** The section header and function-level documentation are thorough and clearly explain the test pattern.
- **Fuzz bounds:** Tax bounded to [1, 5000] bps and desiredOutput to [1e15, 100e18] with `vm.assume(desiredOutput < reserveOut / 2)` — all reasonable guard rails.

---

## Review Summary

**Findings:** 3 (all Info severity, all Resolved)
**Suggestions:** 2 (both Low priority)
**Recommendation:** APPROVE

The implementation cleanly satisfies all 6 acceptance criteria. The fix-up formula is mathematically correct, state isolation is properly handled, and assertions are well-calibrated. The code integrates seamlessly with the existing test structure, reusing helpers and following established patterns. No bugs, security issues, or correctness problems found.

---

**Review complete.**
