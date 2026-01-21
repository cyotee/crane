# Code Review: CRANE-085

**Reviewer:** OpenCode
**Review Started:** 2026-01-20
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Gas estimate wording could mislead
**File:** `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol`
**Severity:** Low
**Description:** The NatSpec provides gas estimates and references “mainnet, ~25 gwei”, but gwei does not affect gas usage (only cost), and the estimates are not clearly sourced. This is minor (docs-only), but could miscalibrate expectations if developers treat the numbers as authoritative.
**Status:** Open
**Resolution:** Suggestion added below (clarify as approximate, remove gwei mention, optionally describe how to reproduce measurements).

### Finding 2: Redundant helper name in Newton-Raphson docs
**File:** `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol`
**Severity:** Nit
**Description:** `_k_from_f()` is a thin wrapper around `_f()`. The name implies a different calculation than `_f`, but it is identical. This is harmless, but slightly confusing in the Newton-Raphson early-exit comment that references it.
**Status:** Open
**Resolution:** Suggestion added below (either inline `_f` or rename/remove helper).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Tighten/clarify gas estimate language
**Priority:** P2
**Description:** Update the NatSpec gas notes to avoid "~25 gwei" (cost vs gas confusion), and clearly label the gas figures as "rough order-of-magnitude" / "environment-dependent" with a pointer to a reproducible measurement method (e.g., a Foundry gas snapshot or dedicated micro-benchmark test).
**Affected Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-135

### Suggestion 2: Simplify `_k_from_f` helper
**Priority:** P3
**Description:** Replace `_k_from_f(x0, y + 1)` with `_f(x0, y + 1)` (or rename the helper to something more explicit). Keeps the Newton-Raphson section easier to audit.
**Affected Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-136

---

## Review Summary

**Findings:** 1 low-severity docs concern, 1 nit
**Suggestions:** 2 follow-ups (clarify gas wording; minor helper cleanup)
**Recommendation:** Approve (meets acceptance criteria; optional nits)

**Verification:**
- `forge build`: Pass (warnings pre-existing)
- `forge test --match-path "**/aerodrome/**"`: Pass (68 tests)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
