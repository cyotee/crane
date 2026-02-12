# Code Review: CRANE-052

**Reviewer:** (pending)
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None. TASK.md acceptance criteria are clear and PROGRESS.md describes the intended rounding convention.

---

## Review Findings

### Finding 1: Pool-favorable rounding implemented correctly
**File:** contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol
**Severity:** Low
**Description:**
- `computeBalance()` now rounds UP via `FixedPoint.divUpRaw(newInvariant * newInvariant, otherBalance)`.
- `onSwap()` EXACT_OUT now rounds UP via `FixedPoint.divUpRaw(X * dy, Y - dy)`.
- `onSwap()` EXACT_IN remains raw `/` (ROUND_DOWN), which is pool-favorable when paying out.

This matches the stated Balancer convention: round UP when charging users, round DOWN when paying users.
**Status:** Resolved
**Resolution:** Verified by code inspection and tests.

### Finding 2: Acceptance criteria wording vs implementation detail
**File:** contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol
**Severity:** Low
**Description:** TASK.md mentions using `mulDown`/`divUp` in `onSwap()`. The implementation uses raw multiplication/division plus `divUpRaw` (not `divUp`) because operands are already 18-decimal scaled and the intermediate numerator is “raw/inflated”.
**Status:** Resolved
**Resolution:** This is appropriate and consistent with `FixedPoint.divUpRaw` documentation.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Consider `Math.mulDiv(..., Rounding.Ceil)` to avoid overflow in `a*b` intermediates
**Priority:** Medium
**Description:** Both `computeBalance()` and `onSwap()` form a product (`a * b`) before dividing. For extremely large balances, `a * b` can overflow and revert even when the final quotient would fit. Using OpenZeppelin’s 512-bit `Math.mulDiv` with explicit rounding (ceil for pool-favorable EXACT_OUT / computeBalance) would make the math more robust.
**Affected Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-108

### Suggestion 2: Optional guardrails / clearer invariants around “2-token only” assumption
**Priority:** Low
**Description:** The implementation assumes 2-token pools (`computeBalance()` hardcodes the “other token index”). `computeInvariant()` comments “expects exactly 2 tokens” but does not enforce it. Consider adding a require/assert or tightening docs to avoid misuse.
**Affected Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-109

---

## Review Summary

**Findings:** 2 (both resolved)
**Suggestions:** 2 (robustness + clarity)
**Recommendation:** Approve. Implementation matches pool-favorable rounding conventions, and targeted tests cover EXACT_OUT round-up and `computeBalance()` round-up behavior.

**Verification:**
- `forge build`: PASS (warnings only)
- `forge test`: PASS (all suites)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
