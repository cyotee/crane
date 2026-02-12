# Task CRANE-250: Create Behavior_IDiamondFactoryPackage Test Library

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-110
**Worktree:** `feature/CRANE-250-behavior-idiamondFactoryPackage`
**Origin:** Code review suggestion from CRANE-110 (modified by user)

---

## Description

Create a new `Behavior_IDiamondFactoryPackage` test library for validating IDiamondFactoryPackage implementations. This library should follow the same pattern as `Behavior_IFacet` and provide reusable test behaviors for DFPkg contracts, including:

- Zero-selector guard (no facet returns `bytes4(0)`)
- Duplicate selector collision detection across all facet cuts
- Factory deployment validation via `DiamondPackageCallBackFactory`
- Post-deploy state assertions (vault-aware storage, token configs)

This complements CRANE-249 (which adds guards to Behavior_IFacet) by creating a dedicated Behavior library for the DFPkg/factory deployment test pattern.

(Created from code review of CRANE-110, per user direction to create Behavior_IDiamondFactoryPackage)

## Dependencies

- CRANE-110: Add Non-Zero Selector Guard to DFPkg Tests (parent task)

## User Stories

### US-CRANE-250.1: Reusable DFPkg test behaviors

As a developer, I want a Behavior_IDiamondFactoryPackage library so that all DFPkg implementations can be tested with standard behavioral assertions without duplicating test logic.

**Acceptance Criteria:**
- [ ] `Behavior_IDiamondFactoryPackage` library created following Behavior_IFacet patterns
- [ ] Library includes zero-selector guard behavior
- [ ] Library includes duplicate selector collision detection behavior
- [ ] Library includes factory deployment validation behavior
- [ ] At least one existing DFPkg test is refactored to use the new Behavior library as proof
- [ ] Existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- contracts/factories/diamondPkg/Behavior_IDiamondFactoryPackage.sol

**Test Files:**
- New or modified DFPkg test files using the Behavior library

## Inventory Check

Before starting, verify:
- [ ] CRANE-110 is complete
- [ ] `Behavior_IFacet.sol` exists for pattern reference
- [ ] `IDiamondFactoryPackage` interface exists
- [ ] Existing DFPkg tests exist for refactoring reference

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
