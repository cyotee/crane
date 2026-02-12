# Task CRANE-016: Add End-to-End Factory Deployment Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-12
**Completed:** 2026-01-15
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
- [x] Test deploys minimal package twice with same args
- [x] Asserts both deployments return same address
- [x] Asserts second deployment is idempotent (no-op)
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-016.2: Test base facet installation

As a developer, I want to verify that base facets are installed correctly so that all proxies have required core functionality.

**Acceptance Criteria:**
- [x] Test deploys minimal package
- [x] Asserts base facets are present in proxy
- [x] Asserts base facet selectors route correctly
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-016.3: Test package facet installation

As a developer, I want to verify that package-specific facets are installed correctly so that custom functionality is available.

**Acceptance Criteria:**
- [x] Test deploys package with custom facets
- [x] Asserts package facets are present in proxy
- [x] Asserts package facet selectors route correctly
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-016.4: Test postDeploy hook removal

As a developer, I want to verify that the postDeploy hook is removed after deployment so that it cannot be called again.

**Acceptance Criteria:**
- [x] Test deploys minimal package
- [x] Asserts `postDeploy()` selector is NOT routable after deployment
- [x] Asserts calling `postDeploy()` reverts
- [x] Asserts postDeploy facet is removed from facet address set
- [x] Tests pass
- [x] Build succeeds

### US-CRANE-016.5: Test initAccount delegatecall

As a developer, I want to verify that initAccount is called correctly during deployment so that proxy storage is initialized properly.

**Acceptance Criteria:**
- [x] Test deploys package with initialization logic
- [x] Asserts storage is initialized correctly
- [x] Asserts initialization happened via delegatecall (proxy context)
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol

**Supporting Files (may need to create):**
- contracts/test/stubs/MinimalTestPackage.sol (minimal package for testing) - CREATED INLINE
- contracts/test/stubs/MinimalTestFacet.sol (minimal facet for testing) - NOT NEEDED

## Inventory Check

Before starting, verify:
- [x] CRANE-002 is complete or in progress
- [x] contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol exists
- [x] test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol exists (currently empty)
- [x] Understand DiamondPackageCallBackFactory.deploy() flow

## Completion Criteria

- [x] All acceptance criteria met
- [x] Comprehensive end-to-end tests added
- [x] Tests cover: deterministic deploy, facet installation, postDeploy removal, initAccount
- [x] `forge test --match-path test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol` passes
- [x] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
