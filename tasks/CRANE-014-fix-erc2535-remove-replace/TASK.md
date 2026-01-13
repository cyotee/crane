# Task CRANE-014: Fix ERC2535 Remove/Replace Correctness

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** CRANE-002
**Worktree:** `fix/erc2535-remove-replace`
**Origin:** Code review suggestion from CRANE-002

---

## Description

Fix two critical correctness issues in ERC2535Repo that affect proxy routing:

1. **Remove issue:** `_removeFacet()` sets `layout.facetAddress[selector] = facetCut.facetAddress` instead of `address(0)`, causing removed selectors to remain routable
2. **Replace issue:** `_replaceFacet()` calls `layout.facetAddresses._remove(facetCut.facetAddress)` (the new facet) instead of removing the old facet when it becomes empty

These bugs directly undermine selector management, post-deploy hook removal safety, and loupe accuracy.

(Created from code review of CRANE-002)

## Dependencies

- CRANE-002: Diamond Package and Proxy Architecture Review (parent task)

## User Stories

### US-CRANE-014.1: Fix selector removal routing

As a developer, I want removed selectors to become unroutable so that the Diamond proxy correctly reflects the current facet configuration.

**Acceptance Criteria:**
- [ ] `_removeFacet()` sets `layout.facetAddress[selector] = address(0)`
- [ ] Removed selectors return `address(0)` from `_facetAddress()`
- [ ] `MinimalDiamondCallBackProxy._getTarget()` reverts for removed selectors
- [ ] Unit test verifies selector becomes unroutable after removal
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-014.2: Fix replace facet bookkeeping

As a developer, I want facet address set to correctly track which facets have selectors so that loupe functions return accurate information.

**Acceptance Criteria:**
- [ ] `_replaceFacet()` removes the old facet address when it becomes empty (not the new one)
- [ ] Old facet's selector set is deleted when empty
- [ ] Unit test verifies facet address set consistency after replace
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-014.3: Add comprehensive remove/replace tests

As a maintainer, I want unit tests that validate remove and replace operations so that future changes don't reintroduce these bugs.

**Acceptance Criteria:**
- [ ] Test: remove selector makes it unroutable
- [ ] Test: remove updates facet address set correctly
- [ ] Test: replace updates facet address set correctly (old facet removed, new facet present)
- [ ] Test: replace with empty old facet removes old facet from set
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol

**New Test Files:**
- test/foundry/spec/introspection/ERC2535/ERC2535Repo_Remove.t.sol (or add to existing test)
- test/foundry/spec/introspection/ERC2535/ERC2535Repo_Replace.t.sol (or add to existing test)

## Inventory Check

Before starting, verify:
- [ ] CRANE-002 is complete or in progress
- [ ] contracts/introspection/ERC2535/ERC2535Repo.sol exists
- [ ] MinimalDiamondCallBackProxy._getTarget() exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Unit tests added that would have caught both bugs
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
