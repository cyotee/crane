# Progress Log: CRANE-227

## Current Checkpoint

**Last checkpoint:** COMPLETE
**Next step:** N/A - all acceptance criteria met
**Build status:** Passing (compiler warnings only, pre-existing)
**Test status:** 7/7 StableSurgeHook tests pass (including `testUnbalancedAddLiquidityWhenSurging`)

---

## Completion Criteria Checklist

- [x] `testUnbalancedAddLiquidityWhenSurging` passes
- [x] Comment explains why the expected error changed
- [x] No regression in other StableSurgeHook tests (all 7 pass)

## Session Log

### 2026-02-06 - Investigation & Fix

**Finding:** The error expectation fix was already applied in commit `8cc185bb` as part of CRANE-223. The selector was changed from `IVaultErrors.AfterAddLiquidityHookFailed.selector` to `StableMath.MaxImbalanceRatioExceeded.selector`.

**Root cause confirmed:** StableMath's `ensureBalancesWithinMaxImbalanceRange()` fires during the Vault's computation phase, BEFORE `onAfterAddLiquidity` hook executes. The 10:100,000 pool ratio (10,000x) hits `MAX_IMBALANCE_RATIO` guard first.

**Action taken:** Added explanatory 4-line comment documenting WHY the expected error is `MaxImbalanceRatioExceeded` instead of `AfterAddLiquidityHookFailed` (acceptance criteria #3).

**Modified file:**
- `contracts/external/balancer/v3/pool-hooks/test/foundry/StableSurgeHook.t.sol:146` - Added comment before `vm.expectRevert`

**Test results (7/7 pass):**
- `testRemoveLiquidityWhenSurging` - PASS
- `testSuccessfulRegistry` - PASS
- `testSwap__Fuzz` (256 runs) - PASS
- `testUnbalancedAddLiquidityWhenNotSurging` - PASS
- `testUnbalancedAddLiquidityWhenSurging` - PASS
- `testUnbalancedRemoveLiquidityWhenNotSurging` - PASS
- `testValidVault` - PASS

### 2026-02-05 - Task Created

- Task designed via /design
- TASK.md populated with requirements
- Ready for agent assignment via /backlog:launch
