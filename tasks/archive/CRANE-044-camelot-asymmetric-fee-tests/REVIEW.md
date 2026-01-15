# Code Review: CRANE-044

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Status:** Complete

---

## Clarifying Questions

None.

---

## Review Findings

### Finding 1: Minor test naming ambiguity
**File:** test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol
**Severity:** Low
**Description:** `test_swap_token0ToToken1_usesToken0Fee` / `test_swap_token1ToToken0_usesToken1Fee` actually swap TokenA↔TokenB, and then infer whether TokenA/TokenB is token0/token1 at runtime. The assertions are correct, but the names can mislead readers into thinking the test forces token0->token1 direction.
**Status:** Open
**Resolution:** Rename tests (or add a clarifying comment) so they describe “input token fee selection” rather than hard-coded token0/token1 direction.

### Finding 2: Minor cleanup opportunities
**File:** test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol
**Severity:** Nit
**Description:** A couple small cleanups would improve readability:
- `FEE_DENOMINATOR` constant is unused.
- `_setAsymmetricFees()` uses `vm.prank(address(this))` (no-op here) and casts to `CamelotPair` even though the interface includes `setFeePercent`.
**Status:** Open
**Resolution:** Remove the unused constant and simplify `_setAsymmetricFees()`.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Tighten the "both directions" fuzz assertion
**Priority:** Medium
**Description:** `testFuzz_asymmetricFees_bothDirections` currently validates fee selection via `_sortReservesStruct()` and that both swaps succeed, but it does not assert output correctness against `ConstProdUtils._saleQuote`. Consider splitting into two phases with fresh pools (or snapshot/restore) so each direction can be validated against the expected quote under known reserves.
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-069

### Suggestion 2: Reduce noisy logs from stubs (optional)
**Priority:** Low
**Description:** Running this suite prints debug logs from `CamelotPair._getAmountOut`. If these logs aren't intentionally part of the test UX, consider removing or gating them to keep CI output clean.
**Affected Files:**
- contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-070

---

## Review Summary

**Findings:** 2 (Low/Nit only; no blockers)
**Suggestions:** 2
**Recommendation:** Approve

Acceptance criteria check:
- Fuzz test for asymmetric fees: ✅ (3 fuzz tests)
- Both swap directions tested: ✅ (unit tests for A->B and B->A + fuzz coverage)
- Fee selection based on input token: ✅
- `_sortReservesStruct()` selects fee by direction: ✅
- Tests pass: ✅ `forge test --match-path test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol`

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
