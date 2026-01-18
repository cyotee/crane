# Task CRANE-066: Strengthen Zap-In Value Conservation Assertions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-038
**Worktree:** `test/slipstream-zapin-conservation`
**Origin:** Code review suggestion from CRANE-038

---

## Description

Strengthen the zap-in value conservation assertions in the Slipstream fuzz tests. The current `testFuzz_zapIn_valueConservation` test checks basic sanity (`swapAmountIn <= amountIn` and some value is produced) but doesn't assert a meaningful conservation relationship (even allowing for fees).

(Created from code review of CRANE-038)

## Dependencies

- CRANE-038: Add Slipstream Fuzz Tests (parent task)

## User Stories

### US-CRANE-066.1: Add tighter value conservation invariant

As a developer, I want the zap-in fuzz test to assert a meaningful value conservation relationship so that I can catch regressions in the zap logic.

**Acceptance Criteria:**
- [ ] Add tighter invariant bounding dust + used value relative to `amountIn` in the input token domain
- [ ] OR assert dust percent is bounded for the zap scenario
- [ ] Keep assertions tolerant of fee mechanics
- [ ] Avoid brittle accounting across token domains
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/slipstreamUtils/SlipstreamZapQuoter_fuzz.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-038 is complete
- [ ] SlipstreamZapQuoter_fuzz.t.sol exists
- [ ] Current testFuzz_zapIn_valueConservation test exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fuzz tests pass with new assertions
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
