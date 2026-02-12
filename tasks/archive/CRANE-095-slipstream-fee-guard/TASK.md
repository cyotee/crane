# Task CRANE-095: Add Slipstream Combined Fee Guard

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-042
**Worktree:** `fix/slipstream-fee-guard`
**Origin:** Code review suggestion from CRANE-042

---

## Description

Add explicit guard for combined fee (feePips + unstakedFeePips) to ensure it remains below the 1e6 denominator required by SwapMath. This makes failure modes clearer and documents the invariant.

(Created from code review of CRANE-042)

## Dependencies

- CRANE-042: Add Unstaked Fee Handling (parent task - complete)

## User Stories

### US-CRANE-095.1: Add Combined Fee Validation

As a developer, I want explicit validation that combined fees stay below 1e6 so that failure modes are clear and the SwapMath invariant is documented.

**Acceptance Criteria:**
- [ ] Add guard like `require(totalFee < 1e6, "SL:FEE")` where combined fee is formed
- [ ] Guard added to SlipstreamUtils.sol fee combining logic
- [ ] Guard added to SlipstreamQuoter.sol fee combining logic
- [ ] Tests verify the guard reverts on invalid combined fees
- [ ] `forge build` passes
- [ ] `forge test` passes

## Technical Details

The implementation should add validation wherever `feePips + unstakedFeePips` is computed:

```solidity
uint24 totalFee = feePips + unstakedFeePips;
require(totalFee < 1e6, "SL:INVALID_FEE");
```

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/math/SlipstreamUtils.sol`
- `contracts/utils/math/SlipstreamQuoter.sol`

**New/Modified Tests:**
- `test/foundry/spec/utils/math/slipstream/SlipstreamUtils_UnstakedFee.t.sol` (add revert tests)

## Inventory Check

Before starting, verify:
- [ ] CRANE-042 is complete
- [ ] Affected files exist and contain fee combining logic

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
