# Code Review: CRANE-042

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Acceptance criteria met
**File:**
- [contracts/utils/math/SlipstreamUtils.sol](../../contracts/utils/math/SlipstreamUtils.sol)
- [contracts/utils/math/SlipstreamQuoter.sol](../../contracts/utils/math/SlipstreamQuoter.sol)
- [contracts/utils/math/SlipstreamZapQuoter.sol](../../contracts/utils/math/SlipstreamZapQuoter.sol)
- [test/foundry/spec/utils/math/slipstream/SlipstreamUtils_UnstakedFee.t.sol](../../test/foundry/spec/utils/math/slipstream/SlipstreamUtils_UnstakedFee.t.sol)
**Severity:** Info
**Description:**
- `SlipstreamUtils` adds overloads that take `unstakedFeePips` and combine fees as `feePips + unstakedFeePips`.
- `SlipstreamQuoter` adds `includeUnstakedFee` and conditionally adds `pool.unstakedFee()` into the `fee` passed to `SwapMath.computeSwapStep`.
- `SlipstreamZapQuoter` threads `includeUnstakedFee` through zap quote params and provides backwards-compatible `createZapInParams` / `createZapOutParams` overloads defaulting to `false`.
- New unit tests cover the single-tick quote overloads and assert monotonic effects (exact-in output decreases; exact-out input increases).
**Status:** Resolved
**Resolution:** Verified locally with `forge build` + Slipstream math test subset.

### Finding 2: Fee bound assumption is implicit
**File:**
- [contracts/utils/math/SlipstreamUtils.sol](../../contracts/utils/math/SlipstreamUtils.sol)
- [contracts/utils/math/SlipstreamQuoter.sol](../../contracts/utils/math/SlipstreamQuoter.sol)
**Severity:** Low
**Description:**
- The implementation assumes `feePips + unstakedFeePips` remains a valid `SwapMath` fee (i.e., below the 1e6 denominator). If an upstream factory ever permits larger combined fees, quotes may revert inside `SwapMath.computeSwapStep`.
**Status:** Open
**Resolution:** (none)

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add explicit combined-fee guard (or clearer revert)
**Priority:** Medium
**Description:**
- Consider adding a guard like `require(totalFee < 1e6, "SL:FEE")` (or equivalent) where the combined fee is formed.
- This makes failure modes clearer and documents the invariant that `SwapMath` expects.
**Affected Files:**
- [contracts/utils/math/SlipstreamUtils.sol](../../contracts/utils/math/SlipstreamUtils.sol)
- [contracts/utils/math/SlipstreamQuoter.sol](../../contracts/utils/math/SlipstreamQuoter.sol)
**User Response:** Accepted
**Notes:** Converted to task CRANE-095

### Suggestion 2: Add positive-path tests for `includeUnstakedFee=true`
**Priority:** Medium
**Description:**
- Current test updates primarily ensure compilation/backwards-compat by setting `includeUnstakedFee: false`.
- Add at least one test that sets `includeUnstakedFee: true` on `SlipstreamQuoter` (and optionally `SlipstreamZapQuoter`) and asserts the quote changes in the expected direction.
**Affected Files:**
- [test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol](../../test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol)
- [test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapIn.t.sol](../../test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapIn.t.sol)
- [test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapOut.t.sol](../../test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_ZapOut.t.sol)
**User Response:** Accepted
**Notes:** Converted to task CRANE-096

---

## Review Summary

**Findings:** 2 (1 info / 1 low)
**Suggestions:** 2 (both medium priority)
**Recommendation:** Approve (with minor follow-ups)

**Verification:**
- `forge build` (no recompilation needed)
- `forge test --match-path 'test/foundry/spec/utils/math/slipstream*/*.t.sol'` (119 passing)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
