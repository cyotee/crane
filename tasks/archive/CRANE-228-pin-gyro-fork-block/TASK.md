# Task CRANE-228: Pin Gyro Fork Test Block Number for RPC Cache Reliability

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** None
**Worktree:** `fix/pin-gyro-fork-block`

---

## Description

`TestBase_BalancerV3GyroFork.sol` is the only fork test base that uses `FORK_BLOCK = 0` (latest block) instead of a pinned block number. This prevents Foundry's RPC cache from working reliably — every run resolves "latest" to a new block, generating a fresh cache key and requiring a full RPC call. All other 27 fork test files pin specific block numbers. This task pins the Gyro fork to a known-good block for consistent caching.

## Dependencies

- None

## User Stories

### US-CRANE-228.1: Pin Gyro Fork Block for Cache Reliability

As a developer, I want all fork tests to specify a fixed block number so that Foundry's RPC cache works reliably and tests don't require fresh RPC calls on every run.

**Acceptance Criteria:**
- [ ] `TestBase_BalancerV3GyroFork.sol` uses a specific `FORK_BLOCK` value (not 0)
- [ ] The conditional `if (FORK_BLOCK == 0)` branch is removed from `setUp()`
- [ ] `setUp()` uses the same `vm.createSelectFork(rpcAlias, blockNumber)` pattern as other fork test bases
- [ ] Both `BalancerV3Gyro2CLP_Fork.t.sol` and `BalancerV3GyroECLP_Fork.t.sol` still pass
- [ ] No other fork test files are modified

## Technical Details

### Root Cause

In `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3GyroFork.sol` (line 35):
```solidity
uint256 internal constant FORK_BLOCK = 0; // 0 = latest block
```

And the conditional in `setUp()` (lines 77-81):
```solidity
if (FORK_BLOCK == 0) {
    vm.createSelectFork("ethereum_mainnet_infura");
} else {
    vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);
}
```

### Fix

1. Change `FORK_BLOCK` to a specific block number where the Gyro pools are known to exist and have liquidity. Use `21_700_000` to match the Balancer V3 Weighted pool fork tests (same era, known-good).

2. Simplify `setUp()` to remove the conditional:
```solidity
uint256 internal constant FORK_BLOCK = 21_700_000;

// In setUp():
vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);
```

3. Update the comment on `FORK_BLOCK` to remove the "use 0 for latest" language.

### Block Number Choice

`21_700_000` is recommended because:
- It matches `TestBase_BalancerV3WeightedFork.sol` (same Balancer V3 era)
- It's within the range used by other Ethereum mainnet forks (21M-21.9M)
- Gyro pools were deployed before this block (confirmed by CRANE-206 parity tests passing)

If `21_700_000` causes test skips (pool not found), try `21_900_000` (latest block used by any fork test).

### Affected Files

Only 1 file needs modification. The 2 inheriting test files require no changes:
- `BalancerV3Gyro2CLP_Fork.t.sol` — inherits `TestBase_BalancerV3GyroFork`, no fork setup of its own
- `BalancerV3GyroECLP_Fork.t.sol` — inherits `TestBase_BalancerV3GyroFork`, no fork setup of its own

## Files to Create/Modify

**Modified Files:**
- `test/foundry/fork/ethereum_main/balancerV3/TestBase_BalancerV3GyroFork.sol` - Pin FORK_BLOCK, remove conditional setUp branch

## Inventory Check

Before starting, verify:
- [ ] `TestBase_BalancerV3GyroFork.sol` still has `FORK_BLOCK = 0`
- [ ] No other fork test bases use `FORK_BLOCK = 0` (this should be the only one)
- [ ] The chosen block number (21_700_000) is used by other tests already

## Completion Criteria

- [ ] `FORK_BLOCK` is set to a specific non-zero block number
- [ ] The `if (FORK_BLOCK == 0)` conditional is removed from `setUp()`
- [ ] `BalancerV3Gyro2CLP_Fork.t.sol` tests pass (or skip gracefully if pool not initialized at that block)
- [ ] `BalancerV3GyroECLP_Fork.t.sol` tests pass (or skip gracefully if pool not initialized at that block)
- [ ] No regressions in other fork tests
- [ ] Build succeeds with no new warnings

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
