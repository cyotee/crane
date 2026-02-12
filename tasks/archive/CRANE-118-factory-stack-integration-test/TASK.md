# Task CRANE-118: Make Integration Test Truly Factory-Stack End-to-End

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-061
**Worktree:** `feature/factory-stack-integration-test`
**Origin:** Code review suggestion from CRANE-061 (Suggestion 1)

---

## Description

Deploy all real facets and the DFPkg via `ICreate3Factory` (instead of `new`) so the test validates deterministic deployment + registry behavior. This is required to satisfy US-CRANE-061.1 as written.

Currently, the integration test uses `CraneTest.setUp()` (good: uses `InitDevService`), and deploys the proxy via `diamondFactory.deploy(pkg, pkgArgs)` (good). However, the test deploys facets and the package with `new` rather than deploying facets/packages through `ICreate3Factory`.

(Created from code review of CRANE-061)

## Dependencies

- CRANE-061: Add DFPkg Deployment Integration Test (parent task)

## User Stories

### US-CRANE-118.1: Deploy facets via Create3Factory

As a developer, I want the integration test to deploy facets via `create3Factory.deployFacet(...)` so that the deterministic CREATE3 path is validated.

**Acceptance Criteria:**
- [ ] Test deploys all facets via `ICreate3Factory.deployFacet(...)` instead of `new`
- [ ] Facet addresses are deterministic and verifiable
- [ ] Tests pass with factory-deployed facets

### US-CRANE-118.2: Deploy package via Create3Factory

As a developer, I want the integration test to deploy the DFPkg via `create3Factory.deployPackageWithArgs(...)` so that the package deployment path is validated.

**Acceptance Criteria:**
- [ ] Test deploys BalancerV3ConstantProductPoolDFPkg via `ICreate3Factory.deployPackageWithArgs(...)`
- [ ] Package address is deterministic
- [ ] Tests pass with factory-deployed package

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-061 is complete
- [ ] ICreate3Factory.deployFacet() and deployPackageWithArgs() exist
- [ ] Existing integration test file exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
