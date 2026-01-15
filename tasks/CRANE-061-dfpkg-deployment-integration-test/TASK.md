# Task CRANE-061: Add DFPkg Deployment Integration Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-053
**Worktree:** `test/dfpkg-deployment-integration`
**Origin:** Code review suggestion from CRANE-053 (Suggestion 2)

---

## Description

Add an integration-style test that deploys the BalancerV3ConstantProductPoolDFPkg and a proxy via the actual factory stack (`Create3Factory` + `DiamondPackageCallBackFactory` via `InitDevService`) and asserts that:
- Proxy has expected facets/selectors
- `initAccount` initializes ERC20/EIP712/pool state as expected
- `postDeploy` performs Balancer Vault registration (or is at least invoked and makes expected calls)

This addresses the gap in US-CRANE-053.2 acceptance criteria:
- "Test full diamond deployment via DFPkg"
- "Test vault registration flow"

(Created from code review of CRANE-053)

## Dependencies

- CRANE-053: Create Comprehensive Test Suite for Balancer V3 (parent task)

## User Stories

### US-CRANE-061.1: Add full deployment test via real factory stack

As a developer, I want an integration test that deploys the DFPkg via the real factory stack so that the entire deployment flow is verified.

**Acceptance Criteria:**
- [ ] Test uses `InitDevService` to set up `Create3Factory` and `DiamondPackageCallBackFactory`
- [ ] Test deploys BalancerV3ConstantProductPoolDFPkg via the factory
- [ ] Test deploys a proxy using the package
- [ ] Test asserts proxy has expected facets and selectors

### US-CRANE-061.2: Verify initAccount initialization

As a developer, I want to verify that `initAccount` correctly initializes the proxy state.

**Acceptance Criteria:**
- [ ] Test asserts ERC20 metadata (name, symbol, decimals) is initialized
- [ ] Test asserts EIP712 domain is initialized
- [ ] Test asserts pool state is initialized correctly

### US-CRANE-061.3: Verify postDeploy vault registration

As a developer, I want to verify that `postDeploy` performs Balancer Vault registration.

**Acceptance Criteria:**
- [ ] Test verifies `postDeploy` is called
- [ ] Test asserts expected calls to Balancer Vault registration

## Files to Create/Modify

**New Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

**Reference Files:**
- contracts/InitDevService.sol
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-053 is complete
- [ ] InitDevService exists and provides factory setup
- [ ] BalancerV3ConstantProductPoolDFPkg.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
