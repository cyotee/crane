# Progress Log: CRANE-223

## Current Checkpoint

**Last checkpoint:** TASK COMPLETE
**Next step:** Ready for code review
**Build status:** PASS
**Test status:** 4/4 targeted tests PASS; 4745/4787 full suite pass (42 pre-existing failures unrelated to this task)

---

## Session Log

### 2026-02-06 - Error Selector Fixes Applied

**Inventory check (completed):**
- `SafeCastLib.Overflow()` confirmed at `contracts/utils/SafeCastLib.sol:14`
- `Create2.Create2FailedDeployment()` confirmed at `contracts/utils/Create2.sol:24`
- `StableMath.MaxImbalanceRatioExceeded()` confirmed at `contracts/external/balancer/v3/solidity-utils/contracts/math/StableMath.sol:22`

**Root cause analysis:**
- `SafeCast.sol` is a wrapper that delegates to `SafeCastLib`. The wrapper declares `SafeCastOverflowedUintDowncast` but never throws it — `SafeCastLib` uses `Overflow()` via assembly. So runtime reverts use `SafeCastLib.Overflow` selector.
- `Errors.FailedDeployment()` from OZ's Errors.sol is dead code — the actual `Create2.sol` library now uses `Create2FailedDeployment()`.
- `StableMath.MaxImbalanceRatioExceeded()` fires before the hook callback, so the vault never wraps it as `AfterAddLiquidityHookFailed`.

**Changes made:**

1. **BufferVaultPrimitive.t.sol** (line 6, 113):
   - Import: `SafeCast` → `SafeCastLib`
   - `vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 160, overflowAmount))` → `vm.expectRevert(SafeCastLib.Overflow.selector)`

2. **RouterCommon.t.sol** (line 8, 120):
   - Import: `SafeCast` → `SafeCastLib`
   - `vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 160, amountToDeposit))` → `vm.expectRevert(SafeCastLib.Overflow.selector)`

3. **WeightedPool8020Factory.t.sol** (line 10, 120, 134):
   - Removed: `import { Errors } from "@crane/contracts/external/openzeppelin/utils/Errors.sol";`
   - `vm.expectRevert(Errors.FailedDeployment.selector)` → `vm.expectRevert(Create2.Create2FailedDeployment.selector)` (2 occurrences)

4. **StableSurgeHook.t.sol** (line 146):
   - `vm.expectRevert(IVaultErrors.AfterAddLiquidityHookFailed.selector)` → `vm.expectRevert(StableMath.MaxImbalanceRatioExceeded.selector)`

**Test results (individual):**
- `testExactInOverflow` - PASS
- `testTakeTokenInTooLarge` - PASS
- `testPoolUniqueness` - PASS
- `testUnbalancedAddLiquidityWhenSurging` - PASS

**Full regression test results:** 4745 passed, 42 failed (all pre-existing, unrelated to this task):
- `PoolConfigLib.t.sol` (7) - cheatcode depth issues
- `OpenGSNForwarder_Fork.t.sol` (5) - fork test failures
- `BetterSafeERC20.t.sol` (5) - separate error selector issues (other task)
- `BetterStrings.t.sol` (1) - hex formatting issue
- Other pre-existing failures (24) - not in any files we modified

### 2026-02-05 - Task Created

- Task designed via /design
- TASK.md populated with requirements
- Ready for agent assignment via /backlog:launch
