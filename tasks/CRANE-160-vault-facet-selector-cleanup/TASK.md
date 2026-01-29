# Task CRANE-160: Remove Non-Routed Duplicate Selectors from Vault Facets

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-159
**Worktree:** `fix/vault-facet-selector-cleanup`
**Origin:** Code review suggestion from CRANE-159

---

## Description

Align facet code with `facetFuncs()` intent: keep pool-token reads/approve only in `VaultQueryFacet`, keep `IVaultMain` write funcs only in `VaultPoolTokenFacet`, and avoid extra duplicate public/external functions that are not routed.

Currently:
- `VaultPoolTokenFacet` defines `totalSupply`, `balanceOf`, `allowance`, `approve` which are NOT included in `facetFuncs()` and belong in `VaultQueryFacet`
- `VaultQueryFacet` defines `isVaultPaused()` and `isQueryDisabled()` which are NOT returned by `facetFuncs()` and similar functionality exists on the admin facet

These non-routed/duplicate functions increase confusion and create future collision risk.

(Created from code review of CRANE-159)

## Dependencies

- CRANE-159: Fix Balancer V3 Vault Diamond with DFPkg Pattern (parent task) - Complete

## User Stories

### US-CRANE-160.1: Remove Duplicate Pool Token Functions from VaultPoolTokenFacet

As a developer, I want to remove `totalSupply`, `balanceOf`, `allowance`, `approve` from `VaultPoolTokenFacet` so that there is a single canonical location for these functions (VaultQueryFacet).

**Acceptance Criteria:**
- [ ] `VaultPoolTokenFacet` contains only `transfer` and `transferFrom` implementations
- [ ] All pool-token read functions exist only in `VaultQueryFacet`
- [ ] No selector collisions in Diamond
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-160.2: Remove Duplicate Admin Functions from VaultQueryFacet

As a developer, I want to remove `isVaultPaused()` and `isQueryDisabled()` from `VaultQueryFacet` so that admin-ish functions have a single canonical home (VaultAdminFacet).

**Acceptance Criteria:**
- [ ] `isVaultPaused()` and `isQueryDisabled()` are only in `VaultAdminFacet`
- [ ] `VaultQueryFacet.facetFuncs()` returns only query-related selectors
- [ ] No selector collisions in Diamond
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol` (if needed)
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-159 is complete
- [ ] Affected facet files exist
- [ ] Understand which selectors are routed via `facetFuncs()`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No duplicate function implementations across facets
- [ ] All routed selectors match `facetFuncs()` return values
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
