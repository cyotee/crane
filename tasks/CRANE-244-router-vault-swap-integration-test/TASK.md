# Task CRANE-244: Add End-to-End Swap Integration Test for Router-Vault

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-161
**Worktree:** `test/CRANE-244-router-vault-swap-integration-test`
**Origin:** Code review suggestion from CRANE-161

---

## Description

Add an integration test that performs an actual swap through the Router->Vault path. The current `BalancerV3RouterVaultIntegration.t.sol` validates wiring (selector resolution, storage init, loupe introspection) but doesn't attempt a real swap or addLiquidity call. This task adds a test that deploys mock ERC20 tokens, registers a pool on the vault, and calls the router to execute a swap end-to-end.

(Created from code review of CRANE-161)

## Dependencies

- CRANE-161: Resolve Vault Loupe and Router Integration (parent task) - Complete

## User Stories

### US-CRANE-244.1: Add End-to-End Swap Through Router-Vault

As a developer, I want at least one integration test that performs an actual token swap through the Router->Vault Diamond path so that I have confidence the full swap execution works, not just the wiring.

**Acceptance Criteria:**
- [ ] Test deploys real Vault and Router DFPkg packages
- [ ] Test deploys mock ERC20 tokens
- [ ] Test registers a pool on the vault
- [ ] Test executes a swap through the router that routes to the vault
- [ ] Test asserts token balances changed correctly
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol` - Add swap integration test(s)

## Inventory Check

Before starting, verify:
- [ ] CRANE-161 is complete
- [ ] `BalancerV3RouterVaultIntegration.t.sol` exists with the wiring tests
- [ ] Understand Vault pool registration interface
- [ ] Understand Router swap interface

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] At least one end-to-end swap test exists
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
