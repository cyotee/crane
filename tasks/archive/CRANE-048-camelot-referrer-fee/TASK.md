# Task CRANE-048: Add Referrer Fee Integration Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-referrer-fee`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add tests for referrer fee share - quote accuracy when referrer rebate applies and fee distribution verification. Camelot supports referrer fee rebates that reduce the remaining LP fee.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-048.1: Referrer Fee Tests

As a developer, I want tests for referrer fee handling so that quote accuracy with rebates is verified.

**Acceptance Criteria:**
- [x] Test quote accuracy when referrer rebate applies
- [x] Test fee distribution with referrer
- [x] Test `referrersFeeShare()` factory lookup
- [x] Verify referrer receives correct fee portion
- [x] Tests pass

## Technical Details

**Referrer Fee Implementation:**
```solidity
uint256 referrerInputFeeShare = referrer != address(0)
    ? ICamelotFactory(factory).referrersFeeShare(referrer) : 0;
if (referrerInputFeeShare > 0) {
    fee = amount0In.mul(referrerInputFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 2);
    tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
    _safeTransfer(tokensData.token0, referrer, fee);
}
```

**Test Suite:** Unit

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_referrerFee.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol`
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol`

## Inventory Check

Before starting, verify:
- [x] `referrersFeeShare()` in CamelotFactory
- [x] Referrer handling in CamelotPair._swap()

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
