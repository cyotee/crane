# Task CRANE-067: Add Slipstream Single-Tick Guard Assertion

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-038
**Worktree:** `test/slipstream-singletick-guard`
**Origin:** Code review suggestion from CRANE-038

---

## Description

Add an explicit single-tick guard assertion to the Slipstream fuzz tests. The quote-vs-swap tests rely on the documented single-tick assumption via high liquidity + bounded amounts. Adding an explicit post-swap assertion would make failures easier to interpret and would harden the test against accidental parameter drift.

(Created from code review of CRANE-038)

## Dependencies

- CRANE-038: Add Slipstream Fuzz Tests (parent task)

## User Stories

### US-CRANE-067.1: Add single-tick guard assertion

As a developer, I want explicit assertions that swaps stayed within the expected tick range so that test failures are easier to diagnose.

**Acceptance Criteria:**
- [ ] Add post-swap assertion that pool tick is unchanged OR swap didn't cross ticks
- [ ] If tick movement is expected, check swap stayed within same initialized tick range
- [ ] Makes test failures easier to interpret
- [ ] Hardens test against accidental parameter drift
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_fuzz.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-038 is complete
- [ ] SlipstreamUtils_fuzz.t.sol exists
- [ ] Current quote-vs-swap tests exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fuzz tests pass with new assertions
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
