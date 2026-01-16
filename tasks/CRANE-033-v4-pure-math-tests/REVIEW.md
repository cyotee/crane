# Code Review: CRANE-033

**Reviewer:** (pending)
**Review Started:** 2026-01-15
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

(Questions and answers will be recorded here during review)

---

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| Unit tests for `TickMath.getSqrtRatioAtTick()` with known tick/sqrtPrice pairs | Pass | Implemented as `getSqrtPriceAtTick()` in [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol). Includes exact checks for tick 0 / MIN_TICK / MAX_TICK plus additional sanity checks. |
| Unit tests for `TickMath.getTickAtSqrtRatio()` with known sqrtPrice/tick pairs | Pass | Implemented as `getTickAtSqrtPrice()` in [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol). Includes exact checks for Q96, MIN_SQRT_PRICE, and MAX bound behavior via `MAX_SQRT_PRICE - 1`. |
| Unit tests for `SwapMath.computeSwapStep()` with known inputs/outputs | Pass (see Suggestion 1) | [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol) has exact assertions for several corner cases and strong invariant-based coverage across directions/modes. |
| Unit tests for `SqrtPriceMath` amount calculations | Pass (see Suggestion 2) | [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol) covers next-price functions, delta calculations, rounding consistency, and key reverts. |
| Edge cases: MIN_TICK, MAX_TICK, MIN_SQRT_RATIO, MAX_SQRT_RATIO | Pass | TickMath suite explicitly covers MIN/MAX tick, MIN sqrt price, and validates MAX sqrt as an exclusive upper bound. |
| Tests pass | Pass | `forge test --match-path 'test/foundry/spec/protocols/dexes/uniswap/v4/libraries/*.t.sol' -vvv` ran 3 suites: 65 passed, 0 failed, 0 skipped. |
| Build succeeds | Pass | `forge build` succeeded. |

---

## Review Findings

### Finding 1: TASK.md completion command can produce “No tests found”
**File:** [tasks/CRANE-033-v4-pure-math-tests/TASK.md](tasks/CRANE-033-v4-pure-math-tests/TASK.md)
**Severity:** Low
**Description:** The completion command uses a directory path: `forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v4/libraries/`. In Foundry, `--match-path` is applied against test file paths; using a directory string can result in no matched `.t.sol` files and “No tests found in project”.
**Status:** Open
**Resolution:** Update the command to include `*.t.sol` (or a regex that matches the intended files).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add a handful of “golden vector” exact-output assertions for SwapMath
**Priority:** Medium
**Description:** `computeSwapStep()` is well-covered for invariants (directionality, input conservation, fee bounds) and a few exact corner cases (e.g. max fee implies no movement), but it would benefit from 3–6 deterministic “known inputs → exact outputs” vectors (from the upstream reference implementation) to catch subtle rounding/fee regressions.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol)
**User Response:** (pending)
**Notes:** Target both directions and both modes (exact-in/exact-out), with at least one case that reaches target and one that exhausts amount.

### Suggestion 2: Add explicit tests for remaining SqrtPriceMath custom errors
**Priority:** Low
**Description:** Add minimal deterministic test cases for `NotEnoughLiquidity()` and `PriceOverflow()` to cover the remaining assembly-based guard rails.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol)
**User Response:** (pending)
**Notes:** Keep these cases small and targeted; no fuzzing required.

### Suggestion 3: Add more exact tick↔sqrtPrice known pairs in TickMath
**Priority:** Low
**Description:** TickMath already asserts exact values for tick 0 / MIN_TICK / MAX_TICK and uses inequality checks for several other ticks. Adding exact constants for a few more pairs (e.g. ±1, ±10, ±60, ±200) would better satisfy the “known values” intent and reduce the chance of an off-by-one regression.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol](test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol)
**User Response:** (pending)
**Notes:** Hardcode constants derived from the upstream reference library/tooling.

---

## Review Summary

**Findings:** 1 (Low)
**Suggestions:** 3
**Recommendation:** Approve (with minor follow-ups)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
