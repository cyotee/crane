# Task CRANE-161: Resolve Vault Loupe and Router Integration

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-159
**Worktree:** `fix/vault-loupe-router-integration`
**Origin:** Code review suggestion from CRANE-159

---

## Description

Resolve the mismatch between CRANE-159 TASK.md requirements and the actual implementation:

1. **Loupe Facet (US-CRANE-159.5):** The task required creating `VaultLoupeFacet.sol` and bundling it in the Vault DFPkg. The implementation uses the factory-provided `DiamondLoupeFacet` instead.

2. **Router Integration (US-CRANE-159.7):** The task required updating Router tests to deploy/use the real `BalancerV3VaultDFPkg`. Current tests use `MockVault` and do not exercise end-to-end Router-Vault integration.

This task should either:
- (A) Update archived TASK.md to reflect the factory-provided loupe facet approach and document router tests as deferred, OR
- (B) Implement the missing pieces (VaultLoupeFacet + router integration tests)

(Created from code review of CRANE-159)

## Dependencies

- CRANE-159: Fix Balancer V3 Vault Diamond with DFPkg Pattern (parent task) - Complete

## User Stories

### US-CRANE-161.1: Resolve Loupe Facet Strategy

As a developer, I want clarity on whether the Vault Diamond should bundle its own loupe facet or rely on the factory-provided one so that the architecture is documented and consistent.

**Acceptance Criteria:**
- [ ] Decision documented: factory-provided loupe OR custom VaultLoupeFacet
- [ ] If factory-provided: archived TASK.md updated to reflect this approach
- [ ] If custom: VaultLoupeFacet.sol created and included in DFPkg
- [ ] Tests validate loupe functionality

### US-CRANE-161.2: Integrate Real Vault in Router Tests

As a developer, I want Router tests to deploy and use the real BalancerV3VaultDFPkg so that Router-Vault integration is exercised end-to-end.

**Acceptance Criteria:**
- [ ] `BalancerV3RouterDFPkg.t.sol` imports and deploys real Vault DFPkg
- [ ] Router points to real Vault Diamond (not MockVault)
- [ ] At least one end-to-end Router->Vault interaction test exists
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `tasks/archive/CRANE-159-balancer-v3-vault-dfpkg-fix/TASK.md` (if updating requirements)
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`

**Potentially Created Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLoupeFacet.sol` (if option B)

## Inventory Check

Before starting, verify:
- [ ] CRANE-159 is complete
- [ ] Understand current factory-provided loupe behavior
- [ ] Review existing Router test structure

## Completion Criteria

- [ ] Loupe facet strategy documented and implemented
- [ ] Router tests use real Vault Diamond
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
