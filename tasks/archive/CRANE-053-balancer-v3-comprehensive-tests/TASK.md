# Task CRANE-053: Create Comprehensive Test Suite for Balancer V3

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-013
**Worktree:** `test/balancer-v3-comprehensive`
**Origin:** Code review suggestion from CRANE-013

---

## Description

Add comprehensive unit, fuzz, and integration tests for Balancer V3 utilities. While initial coverage exists (64 tests pass), additional coverage is needed for TokenConfigUtils sorting, package deployment paths, vault-aware/auth facets, and rounding/edge-case invariants.

(Created from code review of CRANE-013)

## Dependencies

- CRANE-013: Balancer V3 Utilities Review (parent task)

## User Stories

### US-CRANE-053.1: Add TokenConfigUtils sorting tests

As a developer, I want tests for TokenConfigUtils sorting so that struct field alignment is verified.

**Acceptance Criteria:**
- [ ] Test sorting with 2, 3, and 4 token configurations
- [ ] Test that all struct fields remain aligned after sorting
- [ ] Fuzz tests with random token orderings

### US-CRANE-053.2: Add package deployment path tests

As a deployer, I want tests for DFPkg deployment so that facet composition is verified.

**Acceptance Criteria:**
- [ ] Test full diamond deployment via DFPkg
- [ ] Verify no selector collisions in facetCuts
- [ ] Test vault registration flow

### US-CRANE-053.3: Add rounding invariant tests

As a pool operator, I want rounding invariant tests so that pool-favorable rounding is verified.

**Acceptance Criteria:**
- [ ] Test swap rounding with small amounts (1 wei, dust amounts)
- [ ] Test computeBalance rounding
- [ ] Verify pool never loses value due to rounding

## Files to Create/Modify

**New Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/utils/TokenConfigUtils.t.sol
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-013 is complete
- [ ] Existing test directory: test/foundry/spec/protocols/dexes/balancer/v3/
- [ ] Review PROGRESS.md from CRANE-013 for recommended test suites

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All new tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
