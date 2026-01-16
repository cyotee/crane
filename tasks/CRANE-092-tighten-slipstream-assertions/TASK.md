# Task CRANE-092: Tighten Slipstream Edge Case Test Assertions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-040
**Worktree:** `fix/tighten-slipstream-assertions`
**Origin:** Code review suggestion from CRANE-040 (Suggestion 1)

---

## Description

Replace tautological assertions (e.g., `assertTrue(x >= 0)` for unsigned ints) with meaningful value bounds / equality checks so the tests fail on meaningful regressions. Focus specifically on `*_minSqrtRatioBoundary`, `*_maxSqrtRatioBoundary`, and the dust-liquidity tests.

(Created from code review of CRANE-040)

## Dependencies

- CRANE-040: Add Slipstream Edge Case Tests (parent task - completed)

## User Stories

### US-CRANE-092.1: Meaningful Test Assertions

As a developer, I want test assertions that fail on meaningful regressions so that the test suite provides signal rather than false confidence.

**Acceptance Criteria:**
- [ ] Replace tautological assertions with value bounds
- [ ] Assert on returned value ranges, not just "no revert"
- [ ] Focus on minSqrtRatioBoundary, maxSqrtRatioBoundary tests
- [ ] Focus on dust-liquidity tests
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
