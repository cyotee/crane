# Task CRANE-097: Add SlipstreamRewardUtils Fork Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-043
**Worktree:** `test/reward-utils-fork`
**Origin:** Code review suggestion from CRANE-043

---

## Description

Add a fork test that uses a real Slipstream pool on Base mainnet to verify the reward estimation matches actual claimable amounts. This validates the library against real reward mechanics.

(Created from code review of CRANE-043)

## Dependencies

- CRANE-043: Add Reward Quoting Utilities (parent task - complete)

## User Stories

### US-CRANE-097.1: Fork Test for Live Pool Interaction

As a developer, I want fork tests against real Slipstream pools so that reward estimation accuracy is validated against production.

**Acceptance Criteria:**
- [ ] Fork test uses Base mainnet Slipstream pool
- [ ] Test verifies `_estimatePendingReward` matches actual claimable amounts
- [ ] Test verifies `_calculateRewardRateForRange` returns realistic values
- [ ] Test documents any expected discrepancies (timing, rounding)
- [ ] `forge build` passes
- [ ] `forge test --fork-url` passes

## Technical Details

Use the fork test pattern from `test/foundry/fork/`:

```solidity
contract SlipstreamRewardUtils_Fork_Test is Test {
    uint256 baseFork;

    function setUp() public {
        baseFork = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(baseFork);
    }

    function test_estimatePendingReward_matchesClaimable() public {
        // Find a real position with pending rewards
        // Compare estimation to actual getReward()
    }
}
```

## Files to Create/Modify

**New Files:**
- `test/foundry/fork/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.fork.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.sol`
- `test/foundry/spec/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-043 is complete
- [ ] BASE_RPC_URL environment variable available
- [ ] Know which Slipstream pools have active rewards on Base

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fork tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
