# Task CRANE-034: Add Uniswap V4 SwapMath Fuzz Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-009
**Worktree:** `test/v4-swapmath-fuzz`
**Origin:** Code review suggestion from CRANE-009 (Suggestion 2)

---

## Description

Add fuzz tests for `SwapMath.computeSwapStep()` to discover edge cases via randomized inputs. Test invariants like `amountIn + fee <= abs(amountRemaining)` for exactIn.

(Created from code review of CRANE-009)

## Dependencies

- CRANE-009: Uniswap V4 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-034.1: SwapMath Fuzz Tests

As a developer, I want fuzz tests for SwapMath so that edge cases are discovered via randomized testing.

**Acceptance Criteria:**
- [x] Fuzz test for `computeSwapStep()` with randomized inputs
- [x] Invariant: `amountIn + feeAmount <= abs(amountRemaining)` for exactIn swaps
- [x] Invariant: `amountOut <= abs(amountRemaining)` for exactOut swaps
- [x] Test sqrtPriceNext is bounded by sqrtPriceLimit
- [x] Test fee calculations are non-negative
- [x] Tests pass with default fuzz runs
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/uniswap/v4/libraries/SwapMath.sol`
- CRANE-009 PROGRESS.md (contains example fuzz test structure)

## Inventory Check

Before starting, verify:
- [x] CRANE-009 is complete
- [x] SwapMath.sol exists

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol`)
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
