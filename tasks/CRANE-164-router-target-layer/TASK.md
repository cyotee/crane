# Task CRANE-164: Add Target Layer to Router Facets

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `refactor/router-target-layer`
**Origin:** Code review finding 8 from CRANE-142

---

## Description

Refactor Balancer V3 Router facets to follow Crane's three-tier Facet-Target-Repo architecture.

**Problem:**
AGENTS.md requires a three-tier architecture where:
- **Target** contracts contain business logic
- **Facet** contracts are thin wrappers that extend Targets
- **Repo** contracts handle storage

Current implementation places all business logic directly in Facet contracts (e.g., `RouterSwapFacet` contains swap logic instead of extending a `RouterSwapTarget`). This violates the core Crane architectural separation.

**Solution:**
Extract business logic from facets into corresponding Target contracts:
- `RouterSwapFacet` -> extends `RouterSwapTarget`
- `RouterBatchFacet` -> extends `RouterBatchTarget`
- etc.

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-164.1: Create Target Contracts for Router Facets

As a developer, I want Target contracts containing business logic so that the codebase follows Crane's three-tier architecture.

**Acceptance Criteria:**
- [ ] `RouterSwapTarget.sol` with swap logic
- [ ] `RouterBatchTarget.sol` with batch logic
- [ ] `BufferRouterTarget.sol` with buffer logic
- [ ] `CompositeLiquidityNestedTarget.sol` with nested logic
- [ ] `CompositeLiquidityERC4626Target.sol` with ERC4626 logic
- [ ] All Targets compile successfully

### US-CRANE-164.2: Refactor Facets as Thin Wrappers

As a developer, I want Facets to be thin wrappers extending Targets so that the architecture is consistent.

**Acceptance Criteria:**
- [ ] Each Facet extends its corresponding Target
- [ ] Facets contain only IFacet metadata and minimal glue code
- [ ] Business logic resides in Targets
- [ ] All existing tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/targets/RouterSwapTarget.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/targets/RouterBatchTarget.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/targets/BufferRouterTarget.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/targets/CompositeLiquidityNestedTarget.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/targets/CompositeLiquidityERC4626Target.sol`

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterSwapFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterBatchFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/BufferRouterFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityNestedFacet.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityERC4626Facet.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 is complete
- [ ] Review existing Crane Target examples (e.g., in ERC20 or Diamond packages)
- [ ] Understand business logic in each facet

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Three-tier architecture followed
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
