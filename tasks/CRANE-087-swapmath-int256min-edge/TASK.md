# Task CRANE-087: Handle amountRemaining == int256.min Edge Case

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-034
**Worktree:** `test/swapmath-int256min-edge`
**Origin:** Code review suggestion from CRANE-034

---

## Description

Handle the `amountRemaining == type(int256).min` edge case deliberately. Options:
1. Add `vm.assume(amountRemaining != type(int256).min)` in fuzz tests to avoid negation wrap semantics
2. Add a dedicated test that documents and asserts expected behavior when `amountRemaining` is `int256.min` (since `uint256(-amountRemaining)` is a special-case wrap in unchecked code)

Current tests appear stable even with this input, but making the intent explicit improves maintainability.

(Created from code review of CRANE-034)

## Dependencies

- CRANE-034: Add Uniswap V4 SwapMath Fuzz Tests (Complete - parent task)

## User Stories

### US-CRANE-087.1: Document int256.min Edge Case Handling

As a developer, I want explicit handling for the int256.min edge case so that the behavior is documented and intentional.

**Acceptance Criteria:**
- [ ] Either add vm.assume to exclude int256.min, OR add dedicated test documenting expected behavior
- [ ] Choice is documented in code comments
- [ ] Tests pass with default fuzz runs
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-034 is complete
- [x] SwapMath.fuzz.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
