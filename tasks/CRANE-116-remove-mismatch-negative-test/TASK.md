# Task CRANE-116: Add Negative Test for Facet/Selector Mismatch During Remove

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-058
**Worktree:** `test/remove-mismatch-negative`
**Origin:** Code review suggestion from CRANE-058

---

## Description

Add a negative test that registers two facets, then attempts a remove cut where `facetAddress` is facet A but selectors belong to facet B.

The test should assert either:
- It reverts with an appropriate error (preferred), OR
- State remains consistent (selector removed from the correct facet set, and events reflect reality)

This locks in the intended API semantics for `Remove` and prevents future regressions.

(Created from code review of CRANE-058)

## Dependencies

- CRANE-058: Implement Partial Remove Semantics (parent task)

## User Stories

### US-CRANE-116.1: Negative Test for Facet/Selector Mismatch

As a diamond proxy developer, I want a negative test that verifies behavior when `facetCut.facetAddress` doesn't match the actual owner of the selectors so that the intended API semantics are documented and regressions are prevented.

**Acceptance Criteria:**
- [ ] Test registers two distinct facets with different selectors
- [ ] Test attempts a remove cut with mismatched facet address
- [ ] Test asserts expected behavior (revert or consistent state)
- [ ] Test documents the intended API semantics via clear assertions
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-058 is complete
- [ ] test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol exists
- [ ] Understand existing test patterns in the file

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Test clearly documents expected API behavior
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
