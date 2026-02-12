# Task CRANE-231: Add USDT Approval Tests for safeIncreaseAllowance/safeDecreaseAllowance

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-229
**Worktree:** `test/usdt-increase-decrease-allowance`
**Origin:** Code review suggestion from CRANE-229

---

## Description

`safeIncreaseAllowance` and `safeDecreaseAllowance` both call `forceApprove` internally (SafeERC20.sol:53, 71), which means they now benefit from the `safeApproveWithRetry` fix applied in CRANE-229. However, the existing tests for these functions only use `standardToken` and `nonReturningToken`, not `usdtApprovalToken`. Adding tests that exercise these paths with `MockERC20USDTApproval` would verify the zero-first retry logic through those indirect entry points.

(Created from code review of CRANE-229)

## Dependencies

- CRANE-229: Fix SafeERC20.forceApprove() to Use safeApproveWithRetry() (parent task)

## User Stories

### US-CRANE-231.1: Verify USDT-like token approval through increase/decrease paths

As a developer, I want to verify that `safeIncreaseAllowance` and `safeDecreaseAllowance` work correctly with USDT-like tokens so that the zero-first retry logic is tested through all entry points.

**Acceptance Criteria:**
- [ ] Add `test_safeIncreaseAllowance_usdtApprovalToken` test using `MockERC20USDTApproval`
- [ ] Add `test_safeDecreaseAllowance_usdtApprovalToken` test using `MockERC20USDTApproval`
- [ ] Tests verify that increase/decrease work when existing allowance is non-zero
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/tokens/ERC20/utils/BetterSafeERC20.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-229 is complete
- [ ] `MockERC20USDTApproval` mock exists in the test file
- [ ] `safeIncreaseAllowance` and `safeDecreaseAllowance` test sections exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
