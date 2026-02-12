# Task CRANE-098: Document SlipstreamRewardUtils Limitations in NatSpec

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-043
**Worktree:** `docs/reward-utils-natspec`
**Origin:** Code review suggestion from CRANE-043

---

## Description

Add NatSpec comments noting that estimations assume constant reward rate and liquidity. The APR calculation is for estimation purposes only and doesn't account for compounding or liquidity changes.

(Created from code review of CRANE-043)

## Dependencies

- CRANE-043: Add Reward Quoting Utilities (parent task - complete)

## User Stories

### US-CRANE-098.1: Document Estimation Limitations

As a developer, I want clear documentation of estimation assumptions so that I understand the accuracy limitations when using the library.

**Acceptance Criteria:**
- [x] NatSpec on `_estimatePendingReward` notes timing assumptions
- [x] NatSpec on `_calculateRewardRateForRange` notes liquidity assumptions
- [x] NatSpec on `_estimateAPR` notes it's for estimation only, no compounding
- [x] NatSpec on `_projectFutureRewards` notes constant-rate assumption
- [x] `forge build` passes
- [x] `forge test` passes

## Technical Details

Add `@notice` or `@dev` comments like:

```solidity
/// @notice Estimates pending rewards for a position
/// @dev Assumes constant reward rate since last update. Actual claimable
///      amount may differ due to timing and on-chain reward rate changes.
///      Use for UI estimation purposes; for exact amounts, query the pool.
```

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-043 is complete
- [x] SlipstreamRewardUtils.sol exists with existing NatSpec

## Completion Criteria

- [x] All acceptance criteria met
- [x] NatSpec improvements applied
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
