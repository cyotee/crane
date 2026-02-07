# Code Review: CRANE-093

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-06
**Status:** Complete

---

## Clarifying Questions

No clarifying questions were needed. The task requirements, SwapMath behavior, and MockCLPool implementation are well-documented and self-consistent.

---

## Acceptance Criteria Verification

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Assert end price equals sqrtPriceLimitX96 (or document tolerance) | PASS | `assertEq` in `test_priceLimitExactness_zeroForOne` (L462), `test_priceLimitExactness_oneForZero` (L517), multi-target tests (L575, L615), exact-output test (L657) |
| 2 | Keep existing "no overshoot" assertions | PASS | `assertTrue(sqrtPriceX96End >= sqrtPriceLimitX96)` kept at L456 (zeroForOne), `assertTrue(sqrtPriceX96End <= sqrtPriceLimitX96)` kept at L511 (oneForZero), L654 (exact-output) |
| 3 | Assert swap consumed enough input to plausibly reach the limit | PASS | `consumed > 0 && consumed < LARGE_AMOUNT` at L472-473 (zeroForOne), L525-527 (oneForZero). Multi-target tests check `< LARGE_AMOUNT` (L583, L620) |
| 4 | Document any rounding tolerance if exact equality not possible | PASS | NatSpec at L419-423 and L477-479 documents why no tolerance is needed (SwapMath direct assignment) |
| 5 | Tests pass | PASS | 48/48 pass (verified via `FOUNDRY_OFFLINE=true forge test --match-path ...`) |
| 6 | Build succeeds | PASS | Compilation skipped (no changes since last build), tests ran successfully |

**All 6 acceptance criteria are met.**

---

## Review Findings

### Finding 1: Unused variable `sqrtPriceX96Start` in enhanced tests
**File:** `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**Lines:** L436, L492
**Severity:** Low (style)
**Description:** Both `test_priceLimitExactness_zeroForOne` and `test_priceLimitExactness_oneForZero` declare `sqrtPriceX96Start` from `pool.slot0()` but never reference it. This is a pre-existing issue (present before CRANE-093 changes), but since CRANE-093 touched these functions it could have been cleaned up.
**Status:** Resolved (not a bug; pre-existing)
**Resolution:** Not blocking. This variable existed before CRANE-093. Cleaning it up is outside scope.

### Finding 2: Multi-target tests omit `consumed > 0` lower-bound check
**File:** `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**Lines:** L583, L620
**Severity:** Low (test completeness)
**Description:** The multi-target tests (`test_priceLimitExactness_zeroForOne_multipleTargets` and `test_priceLimitExactness_oneForZero_multipleTargets`) assert `consumed < LARGE_AMOUNT` but do not assert `consumed > 0`. The single-target versions at L472 and L525 do include the `> 0` check. While the test is effectively safe (the `assertEq` on end price proves the price moved, which implies input was consumed), explicit `> 0` would be more consistent with the single-target tests.
**Status:** Open
**Resolution:** Minor improvement — add `assertTrue(uint256(amount0) > 0, "Must consume input")` in the multi-target loop bodies for consistency.

### Finding 3: Exact-output limit test lacks input consumption assertion
**File:** `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**Lines:** L627-662
**Severity:** Low (test completeness)
**Description:** `test_priceLimitExactness_exactOutput_hitsLimit` asserts exact landing and no-overshoot but does not check that the swap actually consumed input (no `consumed > 0` or `consumed < LARGE_AMOUNT`). The return values from `pool.swap()` are discarded. Adding an input consumption check would make this test as thorough as the exact-input counterparts.
**Status:** Open
**Resolution:** Minor improvement — capture the return values and add consumption assertions.

### Finding 4: Documentation claim accuracy verified
**File:** `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**Lines:** L419-423
**Severity:** N/A (verification)
**Description:** The NatSpec claims "SwapMath.computeSwapStep sets sqrtRatioNextX96 = sqrtRatioTargetX96 exactly" and "MockCLPool stores this value directly." Verified against:
  - SwapMath.sol L45: `if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96` (exact input)
  - SwapMath.sol L57: `if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96` (exact output)
  - MockCLPool L436: `_sqrtPriceX96 = sqrtRatioNextX96` (direct assignment)

  The claim is accurate. No rounding occurs in this assignment chain for single-tick mock pools.
**Status:** Resolved (verified correct)

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add `consumed > 0` to multi-target and exact-output tests
**Priority:** Low
**Description:** For consistency with the single-target tests, add explicit `consumed > 0` assertions in:
  - `test_priceLimitExactness_zeroForOne_multipleTargets` (inside loop)
  - `test_priceLimitExactness_oneForZero_multipleTargets` (inside loop)
  - `test_priceLimitExactness_exactOutput_hitsLimit` (capture return values)
**Affected Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**User Response:** (pending)
**Notes:** This is purely a consistency improvement. The `assertEq` on price already implicitly proves input was consumed. Not blocking.

### Suggestion 2: Clean up unused `sqrtPriceX96Start` in price-limit tests
**Priority:** Low
**Description:** Remove the unused `sqrtPriceX96Start` declaration from `test_priceLimitExactness_zeroForOne` (L436) and `test_priceLimitExactness_oneForZero` (L492), or use it in a delta assertion if desired.
**Affected Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`
**User Response:** (pending)
**Notes:** Pre-existing issue, not introduced by CRANE-093.

---

## Review Summary

**Findings:** 4 (0 Critical, 0 High, 0 Medium, 3 Low, 1 Verification)
**Suggestions:** 2 (both Low priority)
**Recommendation:** **APPROVE**

The implementation is correct and well-executed. All 6 acceptance criteria are met. The key technical claim (SwapMath direct assignment enables exact equality) has been verified against the source code. The 5 new/enhanced tests provide strong coverage of the price-limit exactness property across both swap directions, multiple price targets, and exact-output mode. The only suggestions are minor consistency improvements to test assertions.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
