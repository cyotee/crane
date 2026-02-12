# Task CRANE-139: Remove Always-True feeAmount >= 0 Assertions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-087
**Worktree:** `fix/swapmath-feeamount-assertions`
**Origin:** Code review suggestion from CRANE-087

---

## Description

Remove `assertTrue(feeAmount >= 0, ...)` assertions from SwapMath fuzz tests since `feeAmount` is `uint256` and can never be negative. These assertions are always true and don't add signal. Keep the more meaningful overflow guard `assertLe(amountIn, type(uint256).max - feeAmount, ...)`.

(Created from code review of CRANE-087)

## Dependencies

- CRANE-087: Handle amountRemaining == int256.min Edge Case (Complete - parent task)

## User Stories

### US-CRANE-139.1: Remove Redundant Assertions

As a developer, I want redundant always-true assertions removed so that the test code is crisp and only contains meaningful checks.

**Acceptance Criteria:**
- [ ] Remove all `assertTrue(feeAmount >= 0, ...)` assertions on uint256 values
- [ ] Keep meaningful overflow guards like `assertLe(amountIn, type(uint256).max - feeAmount, ...)`
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/uniswap/v4/libraries/SwapMath.fuzz.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-087 is complete
- [x] SwapMath.fuzz.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
