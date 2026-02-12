# Task CRANE-267: Add Double-Initialization Documentation Test for VaultAwareRepo

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-119
**Worktree:** `test/CRANE-267-vault-aware-double-init-test`
**Origin:** Code review suggestion from CRANE-119 (Suggestion 2)

---

## Description

Add a test that documents the behavior of calling `BalancerV3VaultAwareRepo._initialize()` in the `postDeploy()` execution flow. The key pattern to document:

1. The Factory calls `package.postDeploy(proxy)` — execution context is the Package itself (`address(this) == package`)
2. The Package calls `PostDeployHookFacet` on the proxy, which DELEGATECALLs back to `package.postDeploy(proxy)`
3. Now execution context is the proxy (`address(this) == proxy`), so Repo `_initialize()` writes go to proxy storage
4. The Package uses an `address(this) == proxy` conditional to branch between these two contexts

**Important context from user:** Repos are not typically used in constructors. They are for updating storage in a proxy. Values set in a constructor should typically be immutable so they are available regardless of execution context (i.e., retrievable while inside a proxy via delegatecall). The `postDeploy()` hook uses the `address(this)` check to determine whether it's being called directly by the Factory or via DELEGATECALL from the proxy, and only writes Repo storage in the proxy context.

(Created from code review of CRANE-119)

## Dependencies

- CRANE-119: Add Proxy-State Assertions for Pool/Vault-Aware Repos (parent task)

## User Stories

### US-CRANE-267.1: Document double-initialization behavior

As a developer, I want a test that explicitly documents the `postDeploy()` DELEGATECALL pattern — where the Package's `postDeploy()` is called twice (once by Factory, once via proxy DELEGATECALL) — so that future developers understand how Repo storage is initialized in the proxy context.

**Acceptance Criteria:**
- [ ] Test documents the `postDeploy()` flow: Factory call → Package calls PostDeployHookFacet → proxy DELEGATECALLs Package
- [ ] Test NatSpec documents the `address(this)` conditional pattern that distinguishes direct vs delegatecall context
- [ ] Test verifies Repo storage is written to proxy storage (not Package storage) after the DELEGATECALL path
- [ ] All existing tests pass
- [ ] `forge build` succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/balancer/v3/repos/BalancerV3VaultAwareRepo.sol (review for guard consideration)
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-119 is complete
- [ ] `BalancerV3VaultAwareRepo._initialize()` exists and has no re-initialization guard

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
