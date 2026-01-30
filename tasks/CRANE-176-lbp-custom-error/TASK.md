# Task CRANE-176: Replace LBP String Revert with Custom Error

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-143
**Worktree:** `fix/lbp-custom-error`
**Origin:** Code review suggestion from CRANE-143

---

## Description

Replace the string revert in `BalancerV3LBPoolTarget.computeBalance()` with a custom error for gas optimization.

Currently the function reverts with:
```solidity
revert("LBP: unsupported operation");
```

This should be replaced with a custom error like:
```solidity
error UnsupportedOperation();
```

(Created from code review of CRANE-143)

## Dependencies

- CRANE-143: Refactor Balancer V3 Weighted Pool Package (parent task)

## User Stories

### US-CRANE-176.1: Custom Error Implementation

As a developer, I want LBP to use custom errors so that gas costs are minimized when reverts occur.

**Acceptance Criteria:**
- [ ] Add `UnsupportedOperation()` custom error to `BalancerV3LBPoolTarget`
- [ ] Replace string revert with custom error
- [ ] Update any tests that check for the revert message
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolTarget.sol`
- Related test files (if any check for revert message)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
