# Task CRANE-088: Remove Minor Test Cruft from SwapMath Fuzz Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-034
**Worktree:** `fix/swapmath-test-cleanup`
**Origin:** Code review suggestion from CRANE-034

---

## Description

Remove unused import (`SqrtPriceMath`) and redundant non-negativity asserts on `uint256` values, or reframe them as overflow/underflow invariants where they add signal.

Non-functional cleanup for lint cleanliness.

(Created from code review of CRANE-034)

## Dependencies

- CRANE-034: Add Uniswap V4 SwapMath Fuzz Tests (Complete - parent task)

## User Stories

### US-CRANE-088.1: Clean Up Test Cruft

As a developer, I want unused imports and redundant asserts removed so that the test code is clean and lint-compliant.

**Acceptance Criteria:**
- [ ] Remove unused `SqrtPriceMath` import
- [ ] Remove or reframe redundant non-negativity asserts on uint256 values
- [ ] Tests pass
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
