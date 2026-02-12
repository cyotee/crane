# Task CRANE-106: Use Balance Deltas Consistently in Multihop Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-050
**Worktree:** `fix/multihop-balance-deltas`
**Origin:** Code review suggestion from CRANE-050

---

## Description

Update multi-hop tests to compute outputs via balance deltas rather than relying on zero starting balances. This makes the test suite more resilient to future changes that might leave token dust (router behavior changes, rounding, or token hooks).

(Created from code review of CRANE-050)

## Dependencies

- CRANE-050: Add Multi-Hop Swap with Directional Fees Tests (parent task - complete)

## User Stories

### US-CRANE-106.1: Balance Delta Pattern

As a developer, I want multihop tests to use balance deltas so that tests remain accurate even if setup leaves dust.

**Acceptance Criteria:**
- [ ] Update tests to capture `balanceBefore` before swap operations
- [ ] Compute actual output as `balanceAfter - balanceBefore`
- [ ] Assert against the computed delta rather than absolute balance
- [ ] Follow pattern from `_executeAndGetOutput` helper
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Current Pattern (brittle):**
```solidity
router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    amountIn, minOut, path, address(this), deadline
);
assertEq(tokenD.balanceOf(address(this)), expectedOutput);
```

**Improved Pattern (resilient):**
```solidity
uint256 balanceBefore = tokenD.balanceOf(address(this));
router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    amountIn, minOut, path, address(this), deadline
);
uint256 actualOutput = tokenD.balanceOf(address(this)) - balanceBefore;
assertEq(actualOutput, expectedOutput);
```

**Test Suite:** Unit

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_multihop.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-050 is complete
- [ ] CamelotV2_multihop.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
