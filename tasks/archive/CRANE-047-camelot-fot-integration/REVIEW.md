# Code Review: CRANE-047

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

(none)

---

## Review Findings

### Finding 1: Fuzz purchase-quote tax parameter unused
**File:** test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol
**Severity:** Medium
**Description:** `testFuzz_purchaseQuote_underestimation(uint256 taxBps_, uint256 desiredOutput_)` binds `taxBps_` into `p.taxBps` but never applies it (the test always uses the existing 5% FoT token). This makes the fuzz signature misleading and reduces coverage for "various tax rates" on the `_purchaseQuote()` side.
**Status:** ✅ Resolved
**Resolution:** Removed `taxBps_` parameter from the fuzz test and renamed to `testFuzz_purchaseQuote_underestimation_5percent` to clarify it tests with the existing 5% FoT pool.

### Finding 2: Implementation files are currently untracked
**File:** test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol; test/foundry/spec/protocols/dexes/camelot/v2/mocks/FeeOnTransferToken.sol
**Severity:** High (process / integration)
**Description:** In this worktree, the new FoT mock + test suite are present but show as untracked in `git status`. If this branch is intended to be merged, these need to be added and committed; otherwise CI / reviewers won't see the actual implementation.
**Status:** ✅ Resolved
**Resolution:** Files added and committed with implementation.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Strengthen `_purchaseQuote()` tests by proving “fix-up input” works
**Priority:** Medium
**Description:** The deterministic `_purchaseQuote()` tests compute a `requiredInput` estimate (quotedInput adjusted by $(1-\text{tax})^{-1}$), but never execute a swap with `requiredInput` to demonstrate that it achieves `desiredOutput` (or hits it within rounding). Adding that second swap (fresh pool or reset state) would make the underestimation story airtight.
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-102

### Suggestion 2: Add a guard/test for extreme tax values near 100%
**Priority:** Low
**Description:** Several helpers compute `amountToSend = INITIAL_LIQUIDITY * 10000 / (10000 - taxBps)`. This will divide-by-zero at 100% tax and grows rapidly near 100%, which can cause unrealistic liquidity / overflow hazards in future test extensions.
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-103

---

## Review Summary

**Findings:** 2 (all resolved)
**Suggestions:** 2 (for follow-up tasks)
**Recommendation:** ✅ Approved - All findings resolved. Test suite is correct and all 14 tests pass.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
