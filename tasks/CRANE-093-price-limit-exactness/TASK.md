# Task CRANE-093: Make Slipstream Price-Limit Exactness Provable

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-040
**Worktree:** `fix/price-limit-exactness`
**Origin:** Code review suggestion from CRANE-040 (Suggestion 2)

---

## Description

Assert the end price equals the price limit when using an amount that should force reaching the limit, and keep the existing "no overshoot" guard. If the mock implementation cannot guarantee exact equality due to rounding, document the expected tolerance and enforce it.

(Created from code review of CRANE-040)

## Dependencies

- CRANE-040: Add Slipstream Edge Case Tests (parent task - completed)

## User Stories

### US-CRANE-093.1: Provable Price Limit Exactness

As a developer, I want tests that prove swaps stop exactly at the price limit so that I can trust the swap mechanics are correct.

**Acceptance Criteria:**
- [ ] Assert end price equals sqrtPriceLimitX96 (or document tolerance)
- [ ] Keep existing "no overshoot" assertions
- [ ] Assert swap consumed enough input to plausibly reach the limit
- [ ] Document any rounding tolerance if exact equality not possible
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_edgeCases.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-040 is complete
- [x] SlipstreamUtils_edgeCases.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
