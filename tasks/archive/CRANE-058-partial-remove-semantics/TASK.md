# Task CRANE-058: Implement Correct Partial Remove or Enforce Whole-Facet Removal

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-014
**Worktree:** `fix/partial-remove-semantics`
**Origin:** Code review suggestion from CRANE-014

---

## Description

Decide on partial remove semantics for `_removeFacet()`. Currently, the function always deletes `facetFunctionSelectors[facetCut.facetAddress]` and removes the facet from `facetAddresses`, even if `facetCut.functionSelectors` is a subset of the facet's selectors.

EIP-2535 doesn't explicitly define partial remove behavior, so either approach is valid:

**Option A: Enforce whole-facet removal**
- Revert unless all selectors belonging to `facetCut.facetAddress` are included in the removal
- Simpler implementation, prevents partial state

**Option B: Support partial remove**
- Remove selectors from the set individually
- Only remove facet from `facetAddresses` when its selector set becomes empty
- More flexible but more complex

(Created from code review of CRANE-014)

## Dependencies

- CRANE-014: Fix ERC2535 Remove/Replace Correctness (parent task)
- CRANE-057: Remove Selector Ownership Validation (related - should be completed first)

## User Stories

### US-CRANE-058.1: Define partial remove behavior

As a diamond maintainer, I want clear semantics for partial selector removal so that the behavior is predictable and documented.

**Acceptance Criteria:**
- [x] Design decision documented (Option A or B)
- [x] Implementation matches chosen design
- [x] Tests cover both full and attempted partial removal
- [x] Error messages are clear if partial removal is rejected
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol

**New/Modified Test Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-014 is complete
- [x] CRANE-057 is complete (selector ownership validation) - Note: soft dependency, not blocking
- [x] contracts/introspection/ERC2535/ERC2535Repo.sol exists

## Design Decision Required

Before implementing, clarify with user:
- Option A: Enforce whole-facet removal (simpler)
- Option B: Support partial remove (more flexible)

## Completion Criteria

- [x] Design decision made and documented
- [x] Implementation complete
- [x] All acceptance criteria met
- [x] `forge test` passes
- [x] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
