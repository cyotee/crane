# Task CRANE-079: Remove Unused `using` Directive in ERC165Repo Stub

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-059
**Worktree:** `fix/erc165-unused-using`
**Origin:** Code review suggestion from CRANE-059

---

## Description

Remove the unused `using ERC165Repo for ERC165Repo.Storage;` directive from the ERC165RepoStub test contract.

(Created from code review of CRANE-059)

## Dependencies

- CRANE-059: Add ERC165Repo Storage Overload Test (Complete - parent task)

## User Stories

### US-CRANE-079.1: Remove Unused Using Directive

As a developer, I want to remove unused `using` directives from test stubs so that the code remains minimal and clean.

**Acceptance Criteria:**
- [ ] `using ERC165Repo for ERC165Repo.Storage;` removed from ERC165RepoStub
- [ ] Tests still pass after removal
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-059 is complete
- [x] ERC165Repo.t.sol exists with the ERC165RepoStub contract

## Completion Criteria

- [ ] Unused using directive removed
- [ ] `forge build` succeeds
- [ ] `forge test --match-path test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
