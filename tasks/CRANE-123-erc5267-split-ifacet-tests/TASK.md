# Task CRANE-123: Split ERC5267 IFacet Tests into Dedicated File

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-064
**Worktree:** `refactor/erc5267-split-ifacet`
**Origin:** Code review suggestion from CRANE-064

---

## Description

Many facets keep `*_IFacet.t.sol` separate from behavior/feature tests (e.g., `ERC165Facet_IFacet.t.sol`). Move `ERC5267Facet_IFacet_Test` to its own file for consistency and quicker `--match-path` targeting.

(Created from code review of CRANE-064)

## Dependencies

- CRANE-064: Adopt IFacet TestBase Pattern for ERC5267 (parent task) - Complete

## User Stories

### US-CRANE-123.1: Separate IFacet Test File

As a developer, I want the ERC5267 IFacet tests in a separate file so that they follow the same pattern as other facets and can be targeted independently with `--match-path`.

**Acceptance Criteria:**
- [ ] Create `ERC5267Facet_IFacet.t.sol` in the same directory
- [ ] Move `ERC5267Facet_IFacet_Test` to the new file
- [ ] Keep `ERC5267Facet.t.sol` for behavior/feature tests only
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- test/foundry/spec/utils/cryptography/ERC5267/ERC5267Facet_IFacet.t.sol

**Modified Files:**
- test/foundry/spec/utils/cryptography/ERC5267/ERC5267Facet.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-064 is complete
- [ ] ERC5267Facet.t.sol exists with IFacet tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
