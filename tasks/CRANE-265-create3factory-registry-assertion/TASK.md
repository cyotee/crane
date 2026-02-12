# Task CRANE-265: Add Create3Factory Registry Verification Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-118
**Worktree:** `test/CRANE-265-create3factory-registry-assertion`
**Origin:** Code review suggestion from CRANE-118 (Suggestion 2)

---

## Description

Add explicit assertions that facet addresses deployed via `create3Factory.deployFacet()` are registered in the Create3Factory's internal registry. Currently, tests verify that facets work correctly on the deployed proxy but don't explicitly assert registry registration (e.g., querying `create3Factory.getDeployedFacet(salt)` or equivalent).

The existing tests indirectly prove registry behavior works (deployment succeeds and proxy uses the facets). An explicit registry check would be a minor hardening.

(Created from code review of CRANE-118)

## Dependencies

- CRANE-118: Make Integration Test Truly Factory-Stack E2E (parent task)

## User Stories

### US-CRANE-265.1: Assert facet registry entries

As a developer, I want explicit assertions that deployed facets are registered in the Create3Factory so that registry behavior is directly validated.

**Acceptance Criteria:**
- [ ] Test asserts each deployed facet can be looked up by salt in Create3Factory
- [ ] Test asserts the DFPkg can be looked up by salt in Create3Factory
- [ ] Assertions verify returned addresses match the deployed facet/package addresses
- [ ] All existing tests pass
- [ ] `forge build` succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-118 is complete
- [ ] Create3Factory has a registry query method (e.g., getDeployedFacet or similar)
- [ ] Integration test file exists with factory-deployed facets

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
