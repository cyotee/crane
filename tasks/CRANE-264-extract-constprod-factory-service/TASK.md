# Task CRANE-264: Extract ConstantProductPoolFactoryService

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-118
**Worktree:** `refactor/CRANE-264-extract-constprod-factory-service`
**Origin:** Code review suggestion from CRANE-118 (Suggestion 1)

---

## Description

Extract the inlined deployment logic from `_deployRealFacets()` and `_deployPkg()` in the integration test into a reusable `ConstantProductPoolFactoryService.sol` library, mirroring the existing `GyroPoolFactoryService.sol` pattern. This would make the deployment logic reusable across tests and deployment scripts.

The current inline approach is functionally correct and follows the same patterns. The GyroPoolFactoryService exists because it's used across multiple test files; extracting a ConstantProductPool equivalent prepares for multiple consumers.

(Created from code review of CRANE-118)

## Dependencies

- CRANE-118: Make Integration Test Truly Factory-Stack E2E (parent task)

## User Stories

### US-CRANE-264.1: Create ConstantProductPoolFactoryService library

As a developer, I want a reusable FactoryService library for deploying constant product pool facets and DFPkg so that deployment logic is centralized and consistent.

**Acceptance Criteria:**
- [ ] New `ConstantProductPoolFactoryService.sol` library created following `GyroPoolFactoryService.sol` pattern
- [ ] Library deploys all 5 facets via `create3Factory.deployFacet()` with deterministic salts
- [ ] Library deploys DFPkg via `create3Factory.deployPackageWithArgs()`
- [ ] Integration test updated to use the new service
- [ ] All existing tests pass
- [ ] `forge build` succeeds

## Files to Create/Modify

**New Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/ConstantProductPoolFactoryService.sol

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-118 is complete
- [ ] GyroPoolFactoryService.sol exists as reference pattern
- [ ] Integration test file exists with inline deployment logic

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
