# Code Review: CRANE-084

**Reviewer:** OpenCode
**Review Started:** 2026-01-20
**Review Completed:** 2026-01-21
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

No issues found that block acceptance.

### Finding 1: Stable-vs-Volatile comparison uses different token pairs
**File:** test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol
**Severity:** Low
**Description:** The comparison is conceptually about slippage/fees, but the stable and volatile swaps use different token contracts (stable token A/B vs balanced token A/B). They share 18 decimals and seeded 1:1 liquidity, so the numeric comparison is still meaningful, but using the same token pair for both pool types would make the test intent even clearer and reduce the chance of a future change (e.g., different decimals) weakening the assertion.
**Status:** Open
**Resolution:** N/A (non-blocking).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Make stable-vs-volatile comparison apples-to-apples
**Priority:** Low
**Description:** Consider creating both a stable and volatile pool for the same token pair (same token contracts) in the test base, then compare outputs for identical inputs. This will keep the test focused on curve + fee behavior and avoid assumptions about token parity.
**Affected Files:**
- contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol
**User Response:** (pending)
**Notes:** Optional hardening only; current test meets CRANE-084 acceptance.

### Suggestion 2: Assert the fee config used by the stub
**Priority:** Low
**Description:** Add an assertion that the factory fees match expectations (stable 5 bps, volatile 30 bps) so the test fails loudly if stub defaults change.
**Affected Files:**
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol
**User Response:** (pending)
**Notes:** This can be a quick precondition check near the comparison test.

---

## Review Summary

**Findings:** 1 (Low)
**Suggestions:** 2 (Low)
**Recommendation:** Approve (meets acceptance criteria; test/build passing).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
