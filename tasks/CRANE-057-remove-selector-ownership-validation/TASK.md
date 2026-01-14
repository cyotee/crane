# Task CRANE-057: Fix Remove Selector Ownership Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-014
**Worktree:** `fix/remove-selector-ownership`
**Origin:** Code review suggestion from CRANE-014

---

## Description

Add validation in `_removeFacet()` that each selector in `facetCut.functionSelectors` actually maps to `facetCut.facetAddress` before clearing. Revert if mismatch detected.

**Current Risk:** If a caller specifies selectors that belong to a different facet, the code will:
1. Clear the selectors to address(0) (correct)
2. Delete the wrong facet's selector set (incorrect)
3. Remove the wrong facet from facetAddresses (incorrect)

This prevents owner error from corrupting loupe bookkeeping.

(Created from code review of CRANE-014)

## Dependencies

- CRANE-014: Fix ERC2535 Remove/Replace Correctness (parent task)

## User Stories

### US-CRANE-057.1: Validate selector ownership before removal

As a diamond owner, I want selector removal to validate that each selector belongs to the specified facet so that owner errors don't corrupt the diamond state.

**Acceptance Criteria:**
- [ ] `_removeFacet()` validates each selector maps to `facetCut.facetAddress`
- [ ] Revert with descriptive error if selector doesn't belong to specified facet
- [ ] Negative test: attempt to remove selector belonging to different facet
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol

**New/Modified Test Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol (add negative test)

## Inventory Check

Before starting, verify:
- [ ] CRANE-014 is complete
- [ ] contracts/introspection/ERC2535/ERC2535Repo.sol exists
- [ ] `_removeFacet()` function identified (lines 130-145)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Selector ownership validation implemented
- [ ] Negative test added
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
