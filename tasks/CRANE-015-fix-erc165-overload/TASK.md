# Task CRANE-015: Fix ERC165Repo Overload Bug

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** CRANE-002
**Worktree:** `fix/erc165-overload`
**Origin:** Code review suggestion from CRANE-002

---

## Description

Fix latent defect in ERC165Repo: the `_registerInterface(bytes4)` overload assigns `false` instead of `true`, causing interfaces to be unregistered rather than registered.

While current codepaths appear to call the correct storage-parameterized overload `_registerInterfaces(bytes4[])`, this public overload is likely to be used in the future and will cause incorrect behavior.

(Created from code review of CRANE-002)

## Dependencies

- CRANE-002: Diamond Package and Proxy Architecture Review (parent task)

## User Stories

### US-CRANE-015.1: Fix registerInterface overload

As a developer, I want `_registerInterface(bytes4)` to register interfaces correctly so that ERC165 compliance works as expected.

**Acceptance Criteria:**
- [ ] `_registerInterface(bytes4)` sets `layout.supportedInterfaces[interfaceId] = true`
- [ ] Registered interfaces return `true` from `supportsInterface()`
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-015.2: Add test coverage for both overloads

As a maintainer, I want unit tests covering both `_registerInterface(bytes4)` and `_registerInterfaces(bytes4[])` overloads so that the bug cannot recur.

**Acceptance Criteria:**
- [ ] Test: `_registerInterface(bytes4)` correctly registers single interface
- [ ] Test: `_registerInterfaces(bytes4[])` correctly registers multiple interfaces
- [ ] Test: `supportsInterface()` returns true for registered interfaces
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC165/ERC165Repo.sol

**New/Modified Test Files:**
- test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol (or add to existing test)

## Inventory Check

Before starting, verify:
- [ ] CRANE-002 is complete or in progress
- [ ] contracts/introspection/ERC165/ERC165Repo.sol exists
- [ ] Both overloads exist: `_registerInterface(bytes4)` and `_registerInterfaces(bytes4[])`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Unit tests added for both overloads
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
