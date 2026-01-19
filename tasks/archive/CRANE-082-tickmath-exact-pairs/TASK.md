# Task CRANE-082: Add TickMath Exact Known Pairs

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-033
**Worktree:** `test/tickmath-exact-pairs`
**Origin:** Code review suggestion from CRANE-033

---

## Description

Add more exact tick↔sqrtPrice known pairs in TickMath tests. Currently the suite asserts exact values for tick 0 / MIN_TICK / MAX_TICK. Adding exact constants for additional pairs (e.g. ±1, ±10, ±60, ±200) would better satisfy the "known values" intent and reduce the chance of off-by-one regressions.

(Created from code review of CRANE-033)

## Dependencies

- CRANE-033: Add Uniswap V4 Pure Math Unit Tests (Complete - parent task)

## User Stories

### US-CRANE-082.1: Add Exact Tick/SqrtPrice Pairs

As a developer, I want more exact tick↔sqrtPrice test pairs so that I can catch off-by-one regressions in TickMath conversions.

**Acceptance Criteria:**
- [ ] Add exact constants for tick ±1
- [ ] Add exact constants for tick ±10
- [ ] Add exact constants for tick ±60
- [ ] Add exact constants for tick ±200
- [ ] Constants derived from upstream Uniswap V4 reference library
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-033 is complete
- [x] TickMath.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
