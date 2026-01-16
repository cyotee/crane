# Code Review: CRANE-028

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Review Findings

### Finding 1: Fuzz test name doesn’t match assertion
**File:** test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol
**Severity:** Low
**Description:** `testFuzz_priceImpact_increasesWithTradeSize` does not actually compare two trade sizes; it only bounds `priceImpactBP` against a theoretical maximum with tolerance. The monotonicity property is separately covered by `testFuzz_priceImpact_monotonic`, so behavior is correct, but the name is misleading.
**Status:** Open
**Resolution:** Suggested follow-up: rename the test or extend it to compare against a smaller trade size.

### Finding 2: Console logs add noise to test output
**File:** test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol
**Severity:** Low
**Description:** Several tests emit console logs. This is helpful for debugging, but it can be noisy in CI and makes test output less signal-dense.
**Status:** Open
**Resolution:** Suggested follow-up: remove logs or gate behind a debug flag/pattern used elsewhere in Crane.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Align fuzz test name with behavior
**Priority:** Low
**Description:** Rename `testFuzz_priceImpact_increasesWithTradeSize` to reflect what it asserts (e.g., "boundedByTheoretical"/"reasonableBounds"), or modify it to actually compare price impact at two sizes and assert monotonicity.
**Affected Files:**
- test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-075

### Suggestion 2: Reduce console output
**Priority:** Low
**Description:** Remove `console.log` output from passing tests (or gate it) to keep CI output clean.
**Affected Files:**
- test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-076

---

## Review Summary

**Findings:** 2 (Low severity)
**Suggestions:** 2 (Low priority)
**Recommendation:** Approve

### Acceptance Criteria Check
- Small/medium/large trade bands covered with explicit assertions
- Formula validation included (`priceImpact = 1 - (effectivePrice / spotPrice)`)
- Fuzz coverage included (trade sizes + reserve ratios + monotonicity)
- Focused test run passes: `forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
