# Code Review: CRANE-034

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| Fuzz test for `computeSwapStep()` with randomized inputs | ✅ | Implemented in `SwapMath.fuzz.t.sol` (7 fuzz tests). |
| Invariant: `amountIn + feeAmount <= abs(amountRemaining)` for exactIn | ✅ | Covered in `testFuzz_computeSwapStep_exactIn_inputConservation` and in `testFuzz_computeSwapStep_allInvariants`. |
| Invariant: `amountOut <= abs(amountRemaining)` for exactOut | ✅ | Covered in `testFuzz_computeSwapStep_exactOut_outputConservation` and in `testFuzz_computeSwapStep_allInvariants`. |
| Test sqrtPriceNext is bounded by sqrtPriceLimit | ✅ | Price bounding is enforced against the *target* passed to `computeSwapStep` (see `testFuzz_computeSwapStep_priceBounds` + `testFuzz_computeSwapStep_allInvariants`). Suggestion below: add a combined `getSqrtPriceTarget` → `computeSwapStep` fuzz that asserts the same bound against `sqrtPriceLimitX96` explicitly. |
| Test fee calculations are non-negative | ✅ | `testFuzz_computeSwapStep_feeNonNegative` asserts non-negativity and `feePips == 0 => feeAmount == 0`. |
| Tests pass with default fuzz runs | ✅ | Verified: `forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol -vvv` (7/7 passing, 256 runs each). |
| Build succeeds | ✅ | Verified: `forge build` succeeds in worktree. (Non-blocking warnings unrelated to this change observed.) |

---

## Review Findings

No blocking issues found.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add explicit sqrtPriceLimit bound test
**Priority:** Medium
**Description:** Add a fuzz test that generates `(sqrtPriceCurrentX96, sqrtPriceNextTickX96, sqrtPriceLimitX96)`, derives `sqrtPriceTargetX96 = getSqrtPriceTarget(zeroForOne, sqrtPriceNextTickX96, sqrtPriceLimitX96)`, then asserts `sqrtPriceNextX96` returned by `computeSwapStep` never crosses `sqrtPriceLimitX96`. The current tests bound `sqrtPriceNextX96` vs the *target*, which is correct for `computeSwapStep` in isolation, but an explicit limit-based assertion would map 1:1 to the acceptance criterion wording.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol`
**User Response:** (pending)
**Notes:** This also validates the intended call composition used by pool swap loops.

### Suggestion 2: Handle `amountRemaining == type(int256).min` deliberately
**Priority:** Low
**Description:** Consider either (a) adding `vm.assume(amountRemaining != type(int256).min)` in fuzz tests where you want to avoid the negation wrap semantics, or (b) add a dedicated test that documents and asserts the expected behavior when `amountRemaining` is `int256.min` (since `uint256(-amountRemaining)` is a special-case wrap in unchecked code).
**Affected Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol`
**User Response:** (pending)
**Notes:** Current tests appear stable even with this input, but making the intent explicit improves maintainability.

### Suggestion 3: Remove minor test cruft
**Priority:** Low
**Description:** Remove unused import (`SqrtPriceMath`) and redundant non-negativity asserts on `uint256` values, or reframe them as overflow/underflow invariants where they add signal.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol`
**User Response:** (pending)
**Notes:** Non-functional cleanup; keep only if you prefer stricter lint cleanliness.

---

## Review Summary

**Findings:** None (no blockers).
**Suggestions:** 3 (1 medium, 2 low).
**Recommendation:** Approve.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
