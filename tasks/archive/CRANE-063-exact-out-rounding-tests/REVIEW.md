# Code Review: CRANE-063

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Small-input “no undercharge” test would not catch floor rounding
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol
**Severity:** Medium
**Description:** `test_exactOut_smallInputSpace_noUndercharge()` currently asserts `amountIn >= floorResult`. If the production implementation accidentally used floor division for EXACT_OUT, the test would still pass (because `amountIn == floorResult` satisfies `>=`). The targeted search should assert the *ceiling* result: if `numerator % denominator != 0`, then `amountIn == floorResult + 1`, else `amountIn == floorResult`.
**Status:** Open
**Resolution:** Update the test to compute remainder and assert the exact ceil behavior per-iteration (and optionally assert the loop found at least one remainder case to ensure it meaningfully exercises the ceil path).

### Finding 2: Small-input search is very gas-expensive (may become a suite-time tax)
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol
**Severity:** Low
**Description:** `test_exactOut_smallInputSpace_noUndercharge()` uses nested loops (10k iterations) and allocates new dynamic arrays/structs each iteration. In a focused run it consumed ~82M gas. It currently runs fast, but this is the kind of test that can become a CI-time footgun as the suite grows.
**Status:** Open
**Resolution:** Consider reusing a single `uint256[2]`/memory array and mutating values, or reducing search size while keeping coverage (e.g., constrain to values that guarantee remainder), or keep 10k but minimize allocations.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Align documented worktree name/path
**Priority:** Very Low
**Description:** `TASK.md` lists worktree `test/exact-out-rounding`, while `tasks/INDEX.md` lists `feature/exact-out-rounding-tests`. Pick one convention and make them consistent to reduce confusion when launching/pruning tasks.
**Affected Files:**
- tasks/CRANE-063-exact-out-rounding-tests/TASK.md
- tasks/INDEX.md
**User Response:** (pending)
**Notes:** Purely documentation/ops hygiene.

---

## Review Summary

**Findings:** 2 (1 medium, 1 low)
**Suggestions:** 1
**Recommendation:** Changes Requested

**What’s good / verified:**
- The production EXACT_OUT math already uses `FixedPoint.divUpRaw(...)`, and the dedicated remainder test (`test_exactOut_ceilRounding_addsOneWhenRemainder`) would fail if this ever regressed.
- Strict `assertGe` invariant checks for both EXACT_IN and EXACT_OUT pass.
- Targeted run passed: `forge test --match-path test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol` (36 tests).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
