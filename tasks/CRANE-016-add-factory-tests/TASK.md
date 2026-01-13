# Task CRANE-016: Add End-to-End Factory Deployment Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** CRANE-002
**Worktree:** `test/factory-e2e`
**Origin:** Code review suggestion from CRANE-002

---

## Description

Add comprehensive end-to-end Foundry tests for `DiamondPackageCallBackFactory.deploy()` to validate the most critical integration path:
- CREATE2 deployment with deterministic addresses
- Constructor callback mechanism
- Base facet installation
- Package facet installation
- Post-deploy hook execution and removal

The test file `test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol` exists but is effectively empty (only pragma/license), leaving this critical path unvalidated.

(Created from code review of CRANE-002)

## Dependencies

- CRANE-002: Diamond Package and Proxy Architecture Review (parent task)

## User Stories

### US-CRANE-016.1: Test deterministic deployment

As a developer, I want to verify that factory deployment produces deterministic addresses so that cross-chain deployments work correctly.

**Acceptance Criteria:**
- [ ] Test deploys minimal package twice with same args
- [ ] Asserts both deployments return same address
- [ ] Asserts second deployment is idempotent (no-op)
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-016.2: Test base facet installation

As a developer, I want to verify that base facets are installed correctly so that all proxies have required core functionality.

**Acceptance Criteria:**
- [ ] Test deploys minimal package
- [ ] Asserts base facets are present in proxy
- [ ] Asserts base facet selectors route correctly
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-016.3: Test package facet installation

As a developer, I want to verify that package-specific facets are installed correctly so that custom functionality is available.

**Acceptance Criteria:**
- [ ] Test deploys package with custom facets
- [ ] Asserts package facets are present in proxy
- [ ] Asserts package facet selectors route correctly
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-016.4: Test postDeploy hook removal

As a developer, I want to verify that the postDeploy hook is removed after deployment so that it cannot be called again.

**Acceptance Criteria:**
- [ ] Test deploys minimal package
- [ ] Asserts `postDeploy()` selector is NOT routable after deployment
- [ ] Asserts calling `postDeploy()` reverts
- [ ] Asserts postDeploy facet is removed from facet address set
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-016.5: Test initAccount delegatecall

As a developer, I want to verify that initAccount is called correctly during deployment so that proxy storage is initialized properly.

**Acceptance Criteria:**
- [ ] Test deploys package with initialization logic
- [ ] Asserts storage is initialized correctly
- [ ] Asserts initialization happened via delegatecall (proxy context)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol

**Supporting Files (may need to create):**
- contracts/test/stubs/MinimalTestPackage.sol (minimal package for testing)
- contracts/test/stubs/MinimalTestFacet.sol (minimal facet for testing)

## Inventory Check

Before starting, verify:
- [ ] CRANE-002 is complete or in progress
- [ ] contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol exists
- [ ] test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol exists (currently empty)
- [ ] Understand DiamondPackageCallBackFactory.deploy() flow

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Comprehensive end-to-end tests added
- [ ] Tests cover: deterministic deploy, facet installation, postDeploy removal, initAccount
- [ ] `forge test --match-path test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
