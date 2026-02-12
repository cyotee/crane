# Task CRANE-175: Consolidate Router Facet Size Checks

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-167
**Worktree:** `refactor/router-facet-size-consolidation`
**Origin:** Code review suggestion from CRANE-167

---

## Description

Remove duplication between `TestBase_BalancerV3Router._validateFacetSizes()` and `Behavior_IRouter.isValid_facetSize/areValid_facetSizes`. Currently, the TestBase has an internal facet size validation that duplicates logic in the Behavior library. Routing TestBase checks through the Behavior library creates a single source of truth.

(Created from code review of CRANE-167)

## Dependencies

- CRANE-167: Add TestBase and Behavior Patterns to Router Tests (parent task - Complete)

## User Stories

### US-CRANE-175.1: Consolidate Facet Size Validation

As a developer, I want facet size validation to use the Behavior library so that there is a single source of truth for this logic.

**Acceptance Criteria:**
- [ ] Remove or refactor `TestBase_BalancerV3Router._validateFacetSizes()`
- [ ] Route facet size checks through `Behavior_IRouter.areValid_facetSizes()`
- [ ] No duplication of facet size validation logic
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol` (if needed)

## Inventory Check

Before starting, verify:
- [ ] CRANE-167 is complete
- [ ] TestBase_BalancerV3Router._validateFacetSizes() exists
- [ ] Behavior_IRouter.areValid_facetSizes() exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No duplicated facet size validation logic
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
