# Task CRANE-043: Add Reward Quoting Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `feature/slipstream-reward-utils`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add utilities for reward quoting and claiming for Slipstream gauge integration. Currently there are no utilities to help estimate or interact with Slipstream's reward system.

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-043.1: Reward Estimation Utilities

As a developer, I want utilities to estimate pending rewards so that reward accrual can be predicted.

**Acceptance Criteria:**
- [ ] Function to estimate pending rewards for a position
- [ ] Function to calculate reward rate for a tick range
- [ ] Handle `rewardGrowthGlobalX128` and `getRewardGrowthInside()`
- [ ] Tests verify reward estimation accuracy

### US-CRANE-043.2: Reward Claiming Helpers

As a developer, I want helpers for reward claiming operations so that integration is simplified.

**Acceptance Criteria:**
- [ ] Helper to prepare reward claim parameters
- [ ] Documentation on gauge interaction
- [ ] Tests for helper functions

## Technical Details

**Slipstream Reward Functions:**
- `rewardRate()` - Current reward emission rate
- `rewardReserve()` - Available rewards
- `periodFinish()` - When current reward period ends
- `rewardGrowthGlobalX128()` - Accumulated rewards per liquidity
- `getRewardGrowthInside(tickLower, tickUpper)` - Rewards in range
- `syncReward()` - Sync reward params from gauge

**Reward Calculation:**
```solidity
function estimatePendingReward(
    ICLPool pool,
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity,
    uint256 positionRewardGrowthInsideLastX128
) internal view returns (uint256 pendingReward) {
    uint256 rewardGrowthInsideX128 = pool.getRewardGrowthInside(tickLower, tickUpper);
    uint256 rewardGrowthDelta = rewardGrowthInsideX128 - positionRewardGrowthInsideLastX128;
    pendingReward = FullMath.mulDiv(rewardGrowthDelta, liquidity, FixedPoint128.Q128);
}
```

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.sol`
- `test/foundry/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol`

## Inventory Check

Before starting, verify:
- [ ] `ICLPool` reward functions exist in interface
- [ ] Understand reward accrual mechanics
- [ ] Identify staking vs non-staking reward differences

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
