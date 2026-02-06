# Task CRANE-227: Fix StableSurgeHook Error Expectation (1 test)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/stablesurgehook-error-expectation`

---

## Description

`testUnbalancedAddLiquidityWhenSurging` in StableSurgeHook.t.sol expects `AfterAddLiquidityHookFailed()` but receives `MaxImbalanceRatioExceeded()`. This indicates that StableMath's imbalance ratio check reverts the transaction BEFORE the hook's `onAfterAddLiquidity` has a chance to return `(false, ...)`. The test expectation needs to be updated, or the execution order needs investigation.

## Dependencies

- None

## User Stories

### US-CRANE-227.1: Resolve StableSurgeHook Revert Path

As a developer, I want the StableSurgeHook test to correctly expect the actual revert that occurs so that the test validates the real execution flow.

**Acceptance Criteria:**
- [ ] `testUnbalancedAddLiquidityWhenSurging` passes
- [ ] The fix correctly reflects the actual execution path (either update test or fix hook ordering)
- [ ] The reason for the change is documented in a test comment

## Technical Details

### Root Cause

The execution flow appears to be:
1. User calls addLiquidity (unbalanced)
2. The Vault's internal computation calls into StableMath
3. StableMath detects the imbalance ratio exceeds `MAX_IMBALANCE_RATIO` (10,000)
4. StableMath reverts with `MaxImbalanceRatioExceeded()` BEFORE the hook runs
5. The hook never gets to return `false` (which would trigger `AfterAddLiquidityHookFailed`)

### Options

**Option A:** Update the test to expect `StableMath.MaxImbalanceRatioExceeded.selector` — this is correct if StableMath is supposed to revert before hooks run.

**Option B:** Investigate whether the test's input parameters should create a surging condition without hitting the imbalance guard. This would mean the test setup is wrong, not the expectation.

**Option C:** If hooks should run before StableMath checks, this is a contract logic issue that needs deeper investigation.

### Affected Test (1 total)

**pool-hooks/test/foundry/StableSurgeHook.t.sol:**
- `testUnbalancedAddLiquidityWhenSurging` - expects `AfterAddLiquidityHookFailed()`, gets `MaxImbalanceRatioExceeded()`

## Files to Create/Modify

**Modified Files:**
- `contracts/external/balancer/v3/pool-hooks/test/foundry/StableSurgeHook.t.sol` - Update error expectation or fix test setup

**Files to Read (for context):**
- `contracts/external/balancer/v3/pool-hooks/contracts/SurgeHookCommon.sol` - Hook implementation
- `contracts/external/balancer/v3/solidity-utils/contracts/math/StableMath.sol` - Where MaxImbalanceRatioExceeded is defined
- The Vault's addLiquidity flow to understand hook vs math ordering

## Inventory Check

Before starting, verify:
- [ ] StableMath.MaxImbalanceRatioExceeded error exists
- [ ] Understand the Vault's addLiquidity execution order (math first or hooks first?)
- [ ] Check if the test's pool setup creates conditions that hit the imbalance guard

## Completion Criteria

- [ ] `testUnbalancedAddLiquidityWhenSurging` passes
- [ ] Comment explains why the expected error changed
- [ ] No regression in other StableSurgeHook tests

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
