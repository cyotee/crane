# Task CRANE-222: Fix Internal expectRevert Depth Failures (24 tests)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/internal-expect-revert-depth`

---

## Description

24 tests across the Balancer V3 solidity-utils and vault test suites fail with "call didn't revert at a lower depth than cheatcode call depth". This is caused by Foundry v1.0+ disabling `vm.expectRevert()` for internal/library function calls by default. The fix is adding `allow_internal_expect_revert = true` to foundry.toml, OR wrapping library calls in external helper contracts.

## Dependencies

- None

## User Stories

### US-CRANE-222.1: Enable Internal expectRevert Support

As a developer, I want all `vm.expectRevert()` calls that target library/internal functions to work correctly so that the existing test suite passes without modifications.

**Acceptance Criteria:**
- [ ] All 24 "call didn't revert at a lower depth" failures are resolved
- [ ] The fix does not break any currently passing tests
- [ ] The approach is documented (either foundry.toml flag or wrapper pattern)

## Technical Details

### Root Cause

Foundry v1.0 (PR #9537) changed `vm.expectRevert()` to require reverts at a "lower depth" than the cheatcode call. Library functions called directly are at the same depth as the test, causing the mismatch.

### Recommended Fix

**Option A (Preferred - minimal change):** Add to `foundry.toml` under `[profile.default]`:
```toml
allow_internal_expect_revert = true
```

**Option B (Per-test wrappers):** Create external helper contracts that wrap library calls, adding a call depth. This is more work but more explicit.

### Affected Tests (24 total)

**solidity-utils/test/foundry/FixedPoint.t.sol (4 tests):**
- testDivDown__Fuzz
- testDivUp__Fuzz
- testMulDown__Fuzz
- testMulUp__Fuzz

**solidity-utils/test/foundry/RevertCodec.t.sol (3 tests):**
- testCatchEncodedResultCustomError
- testCatchEncodedResultNoSelector
- testParseSelectorNoData

**solidity-utils/test/foundry/TransientEnumerableSet.t.sol (6 tests):**
- testAtRevertAfterRemove
- testAtRevertEmptyArray
- testAtRevertOutOfBounds
- testIndexOfRevertEmptyArray
- testIndexOfRevertNotExistentElement
- testIndexOfRevertRemovedElement

**solidity-utils/test/foundry/TransientStorageHelpers.t.sol (3 tests):**
- testTransientArrayFailures
- testTransientDecrementUnderflow
- testTransientIncrementOverflow

**solidity-utils/test/foundry/PackedTokenBalance.t.sol (1 test):**
- testOverflow__Fuzz

**solidity-utils/test/foundry/StableMath.t.sol (1 test):**
- testEnsureBalancesWithinMaxImbalanceRange__Fuzz

**solidity-utils/test/foundry/WordCodec.t.sol (2 tests):**
- testInsertInt__Fuzz
- testInsertUint__Fuzz

**solidity-utils/test/foundry/ScalingHelpers.t.sol (1 test):**
- testCopyToArrayLengthMismatch

**vault/test/foundry/unit/PoolConfigLib.t.sol (7 tests):**
- testRequireAddLiquidityCustomRevertIfIsDisabled
- testRequireDonationRevertIfIsDisabled
- testRequireRemoveLiquidityCustomReveryIfIsDisabled
- testRequireUnbalancedLiquidityRevertIfIsDisabled
- testSetAggregateSwapFeePercentageAboveMax
- testSetAggregateYieldFeePercentageAboveMax
- testSetStaticSwapFeePercentageAboveMax

**vault/test/foundry/RouterWethLib.t.sol (1 test):**
- testWrapEthAndSettleInsufficientBalance

## Files to Create/Modify

**Modified Files:**
- `foundry.toml` - Add `allow_internal_expect_revert = true`

## Inventory Check

Before starting, verify:
- [ ] `forge --version` confirms Foundry >= v1.0
- [ ] Current foundry.toml does NOT have this setting

## Completion Criteria

- [ ] All 24 affected tests pass
- [ ] No regression in other tests
- [ ] `forge test --no-match-path "test/foundry/fork/**"` passes these 24 tests

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
