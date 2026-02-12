# Task CRANE-064: Adopt IFacet TestBase Pattern for ERC5267

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-14
**Dependencies:** CRANE-023
**Worktree:** `refactor/erc5267-testbase`
**Origin:** Code review suggestion from CRANE-023

---

## Description

Refactor the ERC5267Facet tests to use the existing `TestBase_IFacet` + `Behavior_IFacet` patterns used elsewhere in the codebase for consistency.

(Created from code review of CRANE-023)

## Dependencies

- CRANE-023: Add ERC-5267 Test Coverage (parent task) - Complete

## User Stories

### US-CRANE-064.1: Consistent Test Patterns

As a developer, I want the ERC5267Facet tests to follow the same TestBase_IFacet pattern as other facets so that test organization is consistent across the codebase.

**Acceptance Criteria:**
- [x] ERC5267Facet.t.sol refactored to use TestBase_IFacet
- [x] Facet metadata tests use Behavior_IFacet pattern
- [x] All existing tests still pass
- [x] No functionality changes, only structural refactoring
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/cryptography/ERC5267/ERC5267Facet.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-023 is complete
- [x] TestBase_IFacet pattern exists in codebase
- [x] Behavior_IFacet pattern exists in codebase
- [x] ERC5267Facet.t.sol exists

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
