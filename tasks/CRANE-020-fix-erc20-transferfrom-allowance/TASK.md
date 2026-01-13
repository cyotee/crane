# Task CRANE-020: Fix Critical ERC20 transferFrom Allowance Bypass

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-005
**Worktree:** `fix/erc20-transferfrom-allowance`
**Origin:** Code review suggestion from CRANE-005

---

## Description

`ERC20Target.transferFrom()` currently calls `ERC20Repo._transfer()` instead of `ERC20Repo._transferFrom()`, bypassing the allowance check entirely. This is a **critical security vulnerability** allowing unauthorized token transfers.

(Created from code review of CRANE-005)

## Dependencies

- CRANE-005: Token Standards Review (parent task - Complete)

## User Stories

### US-CRANE-020.1: Fix transferFrom Allowance Enforcement

As a token holder, I want transferFrom to enforce allowance checks so that my tokens cannot be transferred without my approval.

**Acceptance Criteria:**
- [ ] `ERC20Target.transferFrom()` calls `ERC20Repo._transferFrom()` instead of `_transfer()`
- [ ] Allowance is properly deducted after successful transfer
- [ ] Transfer reverts when allowance is insufficient
- [ ] Existing tests pass
- [ ] New test verifies unauthorized transfer reverts

## Technical Details

**Current Code (contracts/tokens/ERC20/ERC20Target.sol:37-39):**
```solidity
function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
    ERC20Repo._transfer(owner, recipient, amount);  // BUG: bypasses allowance
    return true;
}
```

**Fix:**
```solidity
function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
    ERC20Repo._transferFrom(msg.sender, owner, recipient, amount);  // FIXED: checks allowance
    return true;
}
```

**Why `_transferFrom` is correct:**
- `ERC20Repo._transferFrom()` (lines 131-140) calls `_spendAllowance()` on line 133
- `ERC20Repo._transfer()` (lines 114-129) does NOT call `_spendAllowance()`

## Files to Create/Modify

**Modified Files:**
- `contracts/tokens/ERC20/ERC20Target.sol` (line 38)

**Test Files:**
- Add test to verify unauthorized transfer reverts in `test/foundry/spec/tokens/ERC20/`

## Inventory Check

Before starting, verify:
- [x] CRANE-005 is complete
- [ ] `contracts/tokens/ERC20/ERC20Target.sol` exists
- [ ] `contracts/tokens/ERC20/ERC20Repo.sol` has `_transferFrom()` function

## Completion Criteria

- [ ] `transferFrom` calls `_transferFrom` with correct parameters
- [ ] Unauthorized transfer test added and passes
- [ ] All existing ERC20 tests pass
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
