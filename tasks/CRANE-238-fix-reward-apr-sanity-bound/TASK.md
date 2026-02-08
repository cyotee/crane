# Task CRANE-238: Fix test_calculateRewardAPR_livePool Assertion

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** -
**Worktree:** `fix/reward-apr-sanity-bound`
**Origin:** Failing fork test

---

## Description

The `test_calculateRewardAPR_livePool()` test in `SlipstreamRewardUtils_Fork.t.sol` fails because it asserts an arbitrary sanity bound (`aprBps < 10_000_000` = 100,000%) that is exceeded by the mathematically correct result. The test uses `liquidityValue = 1e18` (1 AERO nominal), which is tiny relative to the pool's reward rate (~2.57 AERO/sec on ~8.96e18 staked liquidity), producing a valid but large APR of ~7,006,862%.

The fix should replace the arbitrary sanity bound with assertions that verify correctness and functionality of the APR calculation, not arbitrary magnitude limits.

## Dependencies

None.

## User Stories

### US-CRANE-238.1: Replace Sanity Bound with Correctness Assertions

As a developer, I want the reward APR fork test to verify correctness of the calculation rather than assert arbitrary magnitude bounds, so that the test passes for any valid pool state.

**Acceptance Criteria:**
- [ ] Remove `assertTrue(aprBps < 10_000_000, ...)` sanity bound assertion
- [ ] Add assertion that APR is non-zero for a pool with active rewards and non-zero staked liquidity
- [ ] Add assertion that APR is finite (not overflow/max uint)
- [ ] Add assertion that APR scales correctly: doubling `liquidityValue` should halve APR
- [ ] Add assertion that APR is zero when `liquidityValue` is zero (already tested separately, but confirm consistency)
- [ ] Keep the diagnostic `console.log` output for observability
- [ ] Test passes on fork at block 28,000,000
- [ ] Build succeeds

## Technical Details

**Root Cause:**

The test at line 592:
```solidity
assertTrue(aprBps < 10_000_000, "APR should be below 100,000% (sanity check)");
```

The APR formula is:
```solidity
aprBps = (yearlyRewards * 10000) / liquidityValueInRewardToken;
```

With `liquidityValue = 1e18` and the pool's reward rate, `yearlyRewards` for this position is enormous relative to the nominal 1e18 value, producing ~700M bps (~7M%).

**Fix Pattern:**

Replace the magnitude assertion with proportionality/correctness checks:

```solidity
// APR should be non-zero for active pool
assertTrue(aprBps > 0, "APR should be non-zero for active pool");

// APR should be finite (not near max uint256)
assertTrue(aprBps < type(uint256).max / 2, "APR should be finite");

// Verify proportionality: doubling liquidityValue halves APR
uint256 aprBps2x = SlipstreamRewardUtils._calculateRewardAPR(
    pool, tickLower, tickUpper, liquidity, liquidityValue * 2
);
assertApproxEqRel(aprBps2x, aprBps / 2, 0.01e18, "APR should halve when liquidityValue doubles");
```

**Files:**
- `test/foundry/fork/base_main/slipstream/SlipstreamRewardUtils_Fork.t.sol` - lines ~559-593

## Files to Create/Modify

**Modified Files:**
- test/foundry/fork/base_main/slipstream/SlipstreamRewardUtils_Fork.t.sol

## Inventory Check

Before starting, verify:
- [ ] SlipstreamRewardUtils_Fork.t.sol exists
- [ ] `test_calculateRewardAPR_livePool()` function exists at line ~559
- [ ] Fork test infrastructure works (INFURA_KEY available)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-test test_calculateRewardAPR_livePool --match-path "test/foundry/fork/base_main/slipstream/SlipstreamRewardUtils_Fork.t.sol"` passes
- [ ] `forge build` passes
- [ ] No other fork tests broken

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
