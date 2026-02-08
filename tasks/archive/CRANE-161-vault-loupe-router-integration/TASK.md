# Task CRANE-161: Resolve Vault Loupe and Router Integration

**Repo:** Crane Framework
**Status:** In Progress
**Created:** 2026-01-29
**Dependencies:** CRANE-159
**Worktree:** `feature/CRANE-161-vault-loupe-router-integration`
**Origin:** Code review suggestion from CRANE-159

---

## Description

Resolve the mismatch between CRANE-159 TASK.md requirements and the actual implementation.

### Architectural Decision: No VaultLoupeFacet

**Decision:** The Vault Diamond MUST use the default Diamond Loupe provided by the Diamond Factory. A custom `VaultLoupeFacet.sol` is NOT needed and MUST NOT be created.

**Rationale:** The factory-provided `DiamondLoupeFacet` already handles all EIP-2535 introspection requirements. DFPkg packages add application-specific facets; the loupe is infrastructure that the factory provides universally to all diamonds. Creating a vault-specific loupe would duplicate functionality and deviate from the standard Crane Diamond Factory pattern.

### Remaining Work: Router Integration

The CRANE-159 task required updating Router tests to deploy/use the real `BalancerV3VaultDFPkg`. Current tests use `MockVault` and do not exercise end-to-end Router-Vault integration. This task should:

1. Update the archived CRANE-159 TASK.md to document the factory-provided loupe decision
2. Integrate the real Vault DFPkg into Router tests for end-to-end coverage

(Created from code review of CRANE-159)

## Dependencies

- CRANE-159: Fix Balancer V3 Vault Diamond with DFPkg Pattern (parent task) - Complete

## User Stories

### US-CRANE-161.1: Document Factory-Provided Loupe Decision

As a developer, I want the archived CRANE-159 TASK.md updated to reflect that the Vault Diamond uses the factory-provided DiamondLoupeFacet (not a custom VaultLoupeFacet) so that the architecture is documented accurately.

**Acceptance Criteria:**
- [ ] Archived CRANE-159 TASK.md updated: US-CRANE-159.5 notes that factory-provided loupe is the correct approach
- [ ] No `VaultLoupeFacet.sol` exists in the codebase
- [ ] Any references to a custom vault loupe facet are removed or corrected

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
- `tasks/archive/CRANE-159-balancer-v3-vault-dfpkg-fix/TASK.md` - Update loupe facet notes
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol` - Add real Vault integration

**No New Contract Files** - VaultLoupeFacet.sol must NOT be created.

## Inventory Check

Before starting, verify:
- [ ] CRANE-159 is complete
- [ ] Confirm factory-provided DiamondLoupeFacet is already deployed with Vault diamonds
- [ ] Review existing Router test structure to understand MockVault usage

## Completion Criteria

- [ ] Factory-provided loupe decision documented in archived CRANE-159 TASK.md
- [ ] No custom VaultLoupeFacet exists
- [ ] Router tests use real Vault Diamond
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
