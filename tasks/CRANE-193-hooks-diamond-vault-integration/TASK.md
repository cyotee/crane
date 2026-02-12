# Task CRANE-193: Add Diamond-Vault Integration Tests for Hooks

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-147
**Worktree:** `test/hooks-diamond-vault-integration`
**Origin:** Code review suggestion from CRANE-147

---

## Description

Add integration tests that deploy Crane's Balancer V3 Diamond Vault and validate hook registration plus core operations (swap, proportional add/remove) with each hook implementation.

Currently, the hook tests use Balancer's `BaseVaultTest` harness and do not explicitly deploy/exercise Crane's Diamond Vault implementation. The acceptance criterion "Works with Diamond Vault" is only indirectly satisfied through `IVault` interface usage and `onlyVault` gating.

This task adds end-to-end integration tests that prove hooks work correctly when registered with the actual Diamond Vault implementation.

(Created from code review of CRANE-147)

## Dependencies

- CRANE-147: Refactor Balancer V3 Pool Hooks Package (parent task, complete)

## User Stories

### US-CRANE-193.1: Diamond Vault Hook Registration

As a developer, I want to verify that hooks can be registered with Crane's Diamond Vault implementation so that I know the hook system is fully integrated.

**Acceptance Criteria:**
- [ ] Deploy Diamond Vault using existing DFPkg infrastructure
- [ ] Register each hook type with the vault
- [ ] Verify hook callbacks are triggered correctly

### US-CRANE-193.2: Hook Integration with Swaps

As a developer, I want to verify that hooks correctly intercept and modify swaps on the Diamond Vault.

**Acceptance Criteria:**
- [ ] Execute swap through Diamond Vault with each hook
- [ ] Verify fee modifications are applied correctly
- [ ] Verify hook state is updated as expected

### US-CRANE-193.3: Hook Integration with Liquidity Operations

As a developer, I want to verify that hooks work with proportional add/remove operations.

**Acceptance Criteria:**
- [ ] Execute proportional add with each relevant hook
- [ ] Execute proportional remove with each relevant hook
- [ ] Verify hook-specific logic (e.g., exit fees) is applied

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/hooks/DiamondVaultIntegration.t.sol`

**May Reference:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/**`
- Existing hook test setup: `BaseHooksTestSetup.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-147 is complete
- [ ] Diamond Vault contracts exist
- [ ] Hook contracts exist

## Implementation Notes

1. Build on existing `BaseHooksTestSetup.sol` patterns where possible
2. Deploy Diamond Vault using the factory/DFPkg infrastructure
3. Test at minimum one hook from each category:
   - Fee modification (DirectionalFeeHook or VeBALFeeDiscountHook)
   - Surge pricing (StableSurgeHook)
   - Exit fee (ExitFeeHookExample)
4. If Diamond Vault has gaps, document them for follow-up

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
