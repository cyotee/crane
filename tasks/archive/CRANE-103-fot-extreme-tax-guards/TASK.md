# Task CRANE-103: Add Guards for Extreme Tax Values Near 100%

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-047
**Worktree:** `test/fot-extreme-tax-guards`
**Origin:** Code review suggestion from CRANE-047

---

## Description

Add guards and/or tests for extreme tax values near 100% in FoT tests. Several helpers compute `amountToSend = INITIAL_LIQUIDITY * 10000 / (10000 - taxBps)`, which will divide-by-zero at 100% tax and grows rapidly near 100%, causing unrealistic liquidity or overflow hazards in future test extensions.

(Created from code review of CRANE-047)

## Dependencies

- CRANE-047: Add Fee-on-Transfer Token Integration Tests (parent task - complete)

## User Stories

### US-CRANE-103.1: Extreme Tax Value Guards

As a developer, I want FoT test helpers to guard against extreme tax values so that tests don't encounter division-by-zero or overflow errors.

**Acceptance Criteria:**
- [ ] Add `require(taxBps < 10000)` guard in helpers that compute inverse tax
- [ ] OR add explicit tests documenting expected behavior at 100% tax
- [ ] Prevent divide-by-zero when `taxBps == 10000`
- [ ] Document edge case behavior near 100% tax
- [ ] Tests pass
- [ ] Build succeeds

## Technical Details

**Problem:**
```solidity
// This will divide-by-zero at taxBps = 10000
uint256 amountToSend = INITIAL_LIQUIDITY * 10000 / (10000 - taxBps);
```

**Options:**
1. Add guard: `require(taxBps < 10000, "Tax must be < 100%")`
2. Add explicit edge case test documenting 100% tax behavior
3. Use checked math with error handling

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol

## Inventory Check

Before starting, verify:
- [ ] CamelotV2_feeOnTransfer.t.sol exists
- [ ] Helper functions using inverse tax formula exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
