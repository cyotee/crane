# Code Review: CRANE-050

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Review Findings

### Finding 1: Balance checks rely on zero dust
**File:** test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_multihop.t.sol
**Severity:** Low
**Description:** Several tests assert `tokenX.balanceOf(address(this)) == expectedAmount` without measuring deltas from a pre-swap balance. This is correct given the current setup (the deposit paths consume the minted liquidity amounts), but it’s a little brittle if future changes introduce dust/leftovers (e.g., router behavior changes, rounding, or token hooks).
**Status:** Open
**Resolution:** Prefer `balanceBefore`/`balanceAfter` deltas for the asserted output amounts (the helper `_executeAndGetOutput` already follows this approach).

### Finding 2: Non-blocking forge warnings during build
**File:** (build output)
**Severity:** Info
**Description:** `forge build` prints multiple `Warning: AST source not found for ...` lines unrelated to the new test. Tests still pass.
**Status:** Open
**Resolution:** No change required for CRANE-050; consider a separate cleanup task if these warnings become noisy in CI.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Use balance deltas consistently
**Priority:** Low
**Description:** Update multi-hop tests to compute outputs via deltas (e.g., `uint256 before = tokenD.balanceOf(address(this)); ...; uint256 actual = tokenD.balanceOf(address(this)) - before;`). This makes the suite more resilient to future changes that might leave token dust.
**Affected Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_multihop.t.sol
**User Response:** (n/a)
**Notes:** Not required for acceptance criteria; purely hardening.

### Suggestion 2: Consider reducing stub log noise in verbose runs
**Priority:** Very Low
**Description:** Verbose test runs (`-vvv`) emit a lot of `CamelotPair._getAmountOut` logs from the stub. If this is unintended, consider gating those logs behind a debug flag or removing them.
**Affected Files:**
- contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol
**User Response:** (n/a)
**Notes:** This isn’t introduced by CRANE-050, but it made the review runs noisy.

---

## Review Summary

**Scope Reviewed:** Multi-hop Camelot router tests with per-hop directional fees.

**Acceptance Criteria Check:**
- ✅ Different fee configurations per hop: covered by `test_multihop_differentFeesPerHop`
- ✅ Accumulated fee impact: covered by `test_multihop_accumulatedFeeImpact`
- ✅ Specific path 0.3% → 0.5% → 0.1%: covered by `test_multihop_specificPath_0_3_0_5_0_1`
- ✅ Cumulative quote equals actual swap: covered by `test_multihop_cumulativeQuoteMatchesActual` and fuzz

**Tests Verified:**
- `forge build`
- `forge test --match-path test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_multihop.t.sol -vvv` (7/7 passing)

**Findings:** 2 (1 low, 1 info)
**Suggestions:** 2 (both low priority)
**Recommendation:** Approve (non-blocking suggestions only).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
