# Task CRANE-033: Add Uniswap V4 Pure Math Unit Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-009
**Worktree:** `test/v4-pure-math-tests`
**Origin:** Code review suggestion from CRANE-009 (Suggestion 1)

---

## Description

Add unit tests for pure math functions (TickMath, SwapMath, SqrtPriceMath) with known inputs/outputs to complement fork tests. This catches edge cases without requiring fork infrastructure.

(Created from code review of CRANE-009)

## Dependencies

- CRANE-009: Uniswap V4 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-033.1: Pure Math Unit Tests

As a developer, I want unit tests for Uniswap V4 math libraries so that I can verify correctness without requiring fork infrastructure.

**Acceptance Criteria:**
- [ ] Unit tests for `TickMath.getSqrtRatioAtTick()` with known tick/sqrtPrice pairs
- [ ] Unit tests for `TickMath.getTickAtSqrtRatio()` with known sqrtPrice/tick pairs
- [ ] Unit tests for `SwapMath.computeSwapStep()` with known inputs/outputs
- [ ] Unit tests for `SqrtPriceMath` amount calculations
- [ ] Edge cases: MIN_TICK, MAX_TICK, MIN_SQRT_RATIO, MAX_SQRT_RATIO
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/TickMath.t.sol`
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.t.sol`
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol`
- `contracts/protocols/dexes/uniswap/v4/libraries/SwapMath.sol`
- `contracts/protocols/dexes/uniswap/v4/libraries/SqrtPriceMath.sol`
- CRANE-009 PROGRESS.md (contains example test code)

## Inventory Check

Before starting, verify:
- [x] CRANE-009 is complete
- [x] V4 math libraries exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v4/libraries/`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
