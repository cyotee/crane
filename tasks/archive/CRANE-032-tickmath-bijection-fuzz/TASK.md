# Task CRANE-032: Add TickMath Bijection Fuzz Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Completed:** 2026-01-15
**Dependencies:** CRANE-008
**Worktree:** `test/tickmath-bijection-fuzz`
**Origin:** Code review suggestion from CRANE-008 (Suggestion 3)

---

## Description

Implement fuzz tests to verify the bijection property of TickMath functions: `getTickAtSqrtRatio(getSqrtRatioAtTick(tick)) == tick` across the full tick range.

This strengthens confidence in the vendored library integration.

(Created from code review of CRANE-008)

## Dependencies

- CRANE-008: Uniswap V3 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-032.1: TickMath Bijection Fuzz Tests

As a developer, I want fuzz tests that verify the TickMath bijection property so that I can be confident the tick <-> sqrtPrice conversions are correct.

**Acceptance Criteria:**
- [x] Fuzz test: `getSqrtRatioAtTick(getTickAtSqrtRatio(sqrtPrice))` approximates `sqrtPrice` within acceptable bounds
- [x] Fuzz test: `getTickAtSqrtRatio(getSqrtRatioAtTick(tick)) == tick` for all valid ticks
- [x] Tests cover MIN_TICK to MAX_TICK range
- [x] Tests handle edge cases (MIN_SQRT_RATIO, MAX_SQRT_RATIO)
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol`

**Reference Files:**
- `lib/v3-core/contracts/libraries/TickMath.sol`
- Existing TickMath fuzz test patterns

## Inventory Check

Before starting, verify:
- [x] CRANE-008 is complete
- [x] TickMath.sol is available in v3-core

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v3/libraries/TickMath.t.sol`)
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
