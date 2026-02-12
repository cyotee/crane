# Progress Log: CRANE-222

## Current Checkpoint

**Last checkpoint:** Task complete
**Build status:** Passing
**Test status:** All 24 affected tests pass; 12 pre-existing failures unrelated to this change

---

## Session Log

### 2026-02-06 - Task Completed

**Change made:** Added `allow_internal_expect_revert = true` to `foundry.toml` under `[profile.default]`.

**Verification:**
- All 24 previously failing tests now pass:
  - FixedPoint.t.sol: 4/4 pass (testDivDown__Fuzz, testDivUp__Fuzz, testMulDown__Fuzz, testMulUp__Fuzz)
  - RevertCodec.t.sol: 3/3 pass (testCatchEncodedResultCustomError, testCatchEncodedResultNoSelector, testParseSelectorNoData)
  - TransientEnumerableSet.t.sol: 6/6 pass (testAtRevert*, testIndexOfRevert*)
  - TransientStorageHelpers.t.sol: 3/3 pass (testTransientArrayFailures, testTransientDecrementUnderflow, testTransientIncrementOverflow)
  - PackedTokenBalance.t.sol: 1/1 pass (testOverflow__Fuzz)
  - StableMath.t.sol: 1/1 pass (testEnsureBalancesWithinMaxImbalanceRange__Fuzz)
  - WordCodec.t.sol: 2/2 pass (testInsertInt__Fuzz, testInsertUint__Fuzz)
  - ScalingHelpers.t.sol: 1/1 pass (testCopyToArrayLengthMismatch)
  - PoolConfigLib.t.sol: 7/7 pass (testRequire*RevertIfIsDisabled, testSet*AboveMax)
  - RouterWethLib.t.sol: 1/1 pass (testWrapEthAndSettleInsufficientBalance)
- Full test suite: 4549 passed, 12 failed (pre-existing), 5 skipped
- No regressions introduced

**Pre-existing failures (not related to this task):**
- StableSurgeHook.t.sol: error selector mismatch (MaxImbalanceRatioExceeded vs AfterAddLiquidityHookFailed)
- E2eErc4626Swaps.t.sol (2): MaxImbalanceRatioExceeded fuzz failures
- WeightedPool8020Factory.t.sol: Create2FailedDeployment vs FailedDeployment
- BufferVaultPrimitive.t.sol: Overflow vs SafeCastOverflowedUintDowncast
- RouterCommon.t.sol: Overflow vs SafeCastOverflowedUintDowncast
- BetterSafeERC20.t.sol (5): various error selector mismatches from library version differences
- BetterStrings.t.sol: hex string format assertion mismatch

**Note:** forge panics with `Attempted to create a NULL object` in `system-configuration` when running without FOUNDRY_OFFLINE=true (Foundry v1.5.1 bug with OpenChain signature lookup). Use `FOUNDRY_OFFLINE=true` to work around.

### 2026-02-05 - Task Created

- Task designed via /design
- TASK.md populated with requirements
- Ready for agent assignment via /backlog:launch
