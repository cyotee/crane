# Task CRANE-059: Add ERC165Repo Storage Overload Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-015
**Worktree:** `test/erc165-storage-overload`
**Origin:** Code review suggestion from CRANE-015

---

## Description

Add an explicit test for `_supportsInterface(Storage, bytes4)` to fully cover the ERC165Repo's overload surface.

Current tests validate `ERC165Repo._supportsInterface(bytes4)` via the stub. Adding one call-path test for the storage-parameterized overload would ensure complete coverage of all Repo overloads.

(Created from code review of CRANE-015)

## Dependencies

- CRANE-015: Fix ERC165Repo Overload Bug (parent task - complete)

## User Stories

### US-CRANE-059.1: Storage Overload Test Coverage

As a developer, I want explicit test coverage for the `_supportsInterface(Storage, bytes4)` overload so that all ERC165Repo public API surfaces are verified.

**Acceptance Criteria:**
- [ ] Test calls `_supportsInterface(Storage, bytes4)` directly
- [ ] Test verifies correct behavior for registered interfaces
- [ ] Test verifies correct behavior for unregistered interfaces
- [ ] All existing tests continue to pass

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-015 is complete
- [x] ERC165Repo.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-path "test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol"`
- [ ] Build succeeds: `forge build`

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
