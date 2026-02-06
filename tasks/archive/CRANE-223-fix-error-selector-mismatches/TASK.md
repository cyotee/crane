# Task CRANE-223: Fix Error Selector Mismatches After OZ Removal (4 tests)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/error-selector-mismatches`

---

## Description

4 tests fail because they expect OpenZeppelin error selectors that no longer exist after OZ was replaced with native Crane utilities. The tests need their `vm.expectRevert()` calls updated to use the new error selectors from Crane's replacement libraries (SafeCastLib.Overflow, Create2.Create2FailedDeployment, etc.).

## Dependencies

- None

## User Stories

### US-CRANE-223.1: Update Error Selector Expectations

As a developer, I want test assertions to match the actual error selectors thrown by Crane's native utility libraries so that the tests correctly validate revert behavior.

**Acceptance Criteria:**
- [ ] All 4 error selector mismatch tests pass
- [ ] Tests import the correct error definitions from Crane libraries
- [ ] No other tests are broken by the changes

## Technical Details

### Root Cause

Commits `8f797ba5` and `509366a9` removed `@openzeppelin` and `@solady` dependencies, replacing them with native Crane implementations. The replacement libraries use different error names/signatures:

| Old Error (OZ/Solady) | New Error (Crane) | Affected Library |
|---|---|---|
| `SafeCast.SafeCastOverflowedUintDowncast(uint8,uint256)` | `SafeCastLib.Overflow()` | SafeCast → SafeCastLib |
| `Errors.FailedDeployment()` | `Create2.Create2FailedDeployment()` | OZ Errors → Crane Create2 |

### Affected Tests (4 total)

**vault/test/foundry/BufferVaultPrimitive.t.sol (1 test):**
- `testExactInOverflow` - expects `SafeCastOverflowedUintDowncast(160, ...)`, gets `Overflow()`
- **Fix:** Change `vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 160, ...))` to `vm.expectRevert(SafeCastLib.Overflow.selector)`

**vault/test/foundry/RouterCommon.t.sol (1 test):**
- `testTakeTokenInTooLarge` - expects `SafeCastOverflowedUintDowncast(160, ...)`, gets `Overflow()`
- **Fix:** Same as above

**pool-weighted/test/foundry/WeightedPool8020Factory.t.sol (1 test):**
- `testPoolUniqueness` - expects `FailedDeployment()`, gets `Create2FailedDeployment()`
- **Fix:** Change to `vm.expectRevert(Create2.Create2FailedDeployment.selector)`

**pool-hooks/test/foundry/StableSurgeHook.t.sol (1 test):**
- `testUnbalancedAddLiquidityWhenSurging` - expects `AfterAddLiquidityHookFailed()`, gets `MaxImbalanceRatioExceeded()`
- **Note:** This may be a deeper issue — see CRANE-227 if StableMath reverts BEFORE the hook return is processed. If so, update the test to expect `StableMath.MaxImbalanceRatioExceeded.selector`. If the hook should catch this, it's a contract logic issue.

## Files to Create/Modify

**Modified Files:**
- `contracts/external/balancer/v3/vault/test/foundry/BufferVaultPrimitive.t.sol` - Update error selector
- `contracts/external/balancer/v3/vault/test/foundry/RouterCommon.t.sol` - Update error selector
- `contracts/external/balancer/v3/pool-weighted/test/foundry/WeightedPool8020Factory.t.sol` - Update error selector and import

## Inventory Check

Before starting, verify:
- [ ] `SafeCastLib.sol` defines `error Overflow()`
- [ ] `Create2.sol` defines `error Create2FailedDeployment()`
- [ ] Confirm which contracts the test subjects actually import

## Completion Criteria

- [ ] All 4 affected tests pass (or 3 if StableSurgeHook is deferred to CRANE-227)
- [ ] No regression in other tests
- [ ] Test imports are updated to reference Crane libraries, not OZ

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
