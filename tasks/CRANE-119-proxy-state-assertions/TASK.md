# Task CRANE-119: Add Proxy-State Assertions for Pool and Vault-Aware Repos

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-061
**Worktree:** `feature/proxy-state-assertions`
**Origin:** Code review suggestion from CRANE-061 (Suggestion 2)

---

## Description

Initialize `BalancerV3VaultAwareRepo` during `initAccount()` and add assertions that:
- `IBalancerV3VaultAware(proxy).balV3Vault()` equals the configured vault
- The pool's token list/state is correctly stored/accessible after deployment

Currently, `initAccount()` does not initialize `BalancerV3VaultAwareRepo` in the proxy storage. Since `BalancerV3VaultAwareFacet` reads from proxy storage, `balV3Vault()` will return `address(0)` unless something else initializes it.

This closes the gap in US-CRANE-061.2 and strengthens US-CRANE-061.3.

(Created from code review of CRANE-061)

## Dependencies

- CRANE-061: Add DFPkg Deployment Integration Test (parent task)

## User Stories

### US-CRANE-119.1: Initialize VaultAwareRepo in initAccount

As a developer, I want `BalancerV3VaultAwareRepo` initialized in `initAccount()` so that the proxy can access vault info.

**Acceptance Criteria:**
- [ ] `initAccount()` initializes `BalancerV3VaultAwareRepo._initialize(vault, authorizer)`
- [ ] `IBalancerV3VaultAware(proxy).balV3Vault()` returns the expected vault address
- [ ] `IBalancerV3VaultAware(proxy).getAuthorizer()` returns the expected authorizer

### US-CRANE-119.2: Add pool state assertions

As a developer, I want assertions that validate pool state is correctly stored after deployment.

**Acceptance Criteria:**
- [ ] Test asserts pool token list is stored correctly
- [ ] Test uses real PoolInfo facet (or minimal target+facet that reads from pool repo)
- [ ] Tests pass with pool state validation

## Files to Create/Modify

**Modified Contract Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-061 is complete
- [ ] BalancerV3VaultAwareRepo exists
- [ ] initAccount() implementation exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
