# Task CRANE-249: Add Zero-Selector and Collision Guards to Behavior_IFacet

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-110
**Worktree:** `feature/CRANE-249-behavior-ifacet-selector-guard`
**Origin:** Code review suggestion from CRANE-110 (modified by user)

---

## Description

Add reusable zero-selector detection and duplicate selector collision checks to the existing `Behavior_IFacet` library (`contracts/factories/diamondPkg/Behavior_IFacet.sol`). Currently, the zero-selector guard and duplicate detection logic is implemented inline in individual DFPkg test files (e.g., `BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol`). As more DFPkg tests are added, this logic would be duplicated. By moving it into `Behavior_IFacet`, all IFacet implementations automatically get these validations.

(Created from code review of CRANE-110, modified per user direction to implement in Behavior_IFacet)

## Dependencies

- CRANE-110: Add Non-Zero Selector Guard to DFPkg Tests (parent task)

## User Stories

### US-CRANE-249.1: Reusable selector validation in Behavior_IFacet

As a developer, I want Behavior_IFacet to include zero-selector and collision checks so that all IFacet implementations are validated without duplicating test logic.

**Acceptance Criteria:**
- [ ] `Behavior_IFacet` includes a function that checks no selector equals `bytes4(0)` across all facet cuts
- [ ] `Behavior_IFacet` includes a function that checks for duplicate selectors across all facet cuts
- [ ] Both checks produce clear diagnostic output (facet address, selector index) on failure
- [ ] Existing Behavior_IFacet tests still pass
- [ ] DFPkg tests that inline this logic can be simplified to use the Behavior helper
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/factories/diamondPkg/Behavior_IFacet.sol

**Test Files:**
- Existing Behavior_IFacet tests (verify compatibility)

## Inventory Check

Before starting, verify:
- [ ] CRANE-110 is complete
- [ ] `Behavior_IFacet.sol` exists at contracts/factories/diamondPkg/
- [ ] Inline zero-selector guard pattern exists in DFPkg test for reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
