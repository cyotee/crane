# Task CRANE-166: Refactor Router Guards to Follow Repo Pattern

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `refactor/router-guard-pattern`
**Origin:** Code review finding 10 from CRANE-142

---

## Description

Refactor router guard functions to follow Crane's Repo pattern where guard logic resides in Repos and Modifiers are thin delegators.

**Problem:**
AGENTS.md specifies that Repos should contain `_onlyXxx()` guard functions with actual check logic, and Modifiers should be thin delegators:

```solidity
// In Repo
function _onlyVault() internal view {
    require(msg.sender == address(_vault()), "Only vault");
}

// In Modifiers
modifier onlyVault() {
    BalancerV3RouterStorageRepo._onlyVault();
    _;
}
```

Current implementation places guard logic directly in `BalancerV3RouterModifiers` instead of the Repo.

**Solution:**
Move guard function implementations from Modifiers to StorageRepo, keeping Modifiers as thin delegators.

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-166.1: Move Guard Logic to Repo

As a developer, I want guard logic in the Repo so that the pattern is consistent with Crane conventions.

**Acceptance Criteria:**
- [ ] `_onlyVault()` implementation in `BalancerV3RouterStorageRepo`
- [ ] `_onlyWhenNotPaused()` implementation in Repo
- [ ] `_isPrepaid()` implementation in Repo
- [ ] All guard checks in Repo
- [ ] Build succeeds

### US-CRANE-166.2: Refactor Modifiers as Delegators

As a developer, I want Modifiers to be thin delegators so that they only call Repo functions.

**Acceptance Criteria:**
- [ ] Modifiers contain only `Repo._onlyXxx(); _;` pattern
- [ ] No guard logic in Modifiers
- [ ] All existing tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterStorageRepo.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterModifiers.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 is complete
- [ ] Review AGENTS.md Repo pattern
- [ ] Identify all guard functions in current Modifiers

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Guard logic in Repo, not Modifiers
- [ ] Modifiers are thin delegators
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
