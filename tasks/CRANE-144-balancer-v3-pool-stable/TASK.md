# Task CRANE-144: Refactor Balancer V3 Stable Pool Package

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-pool-stable`

---

## Description

Refactor the Balancer V3 Stable Pool package (pkg/pool-stable) to ensure all contracts are deployable within the 24KB limit. Stable pools use the StableMath library for stablecoin-optimized constant sum/product hybrid curve.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Pools register with and interact with Vault

## User Stories

### US-CRANE-144.1: StablePool Deployment

As a deployer, I want StablePool to be deployable so that I can create stable pools.

**Acceptance Criteria:**
- [ ] StablePool compiles to <24KB (or refactored if needed)
- [ ] Pool registers with Diamond Vault successfully
- [ ] StableMath calculations work correctly
- [ ] Amplification parameter works
- [ ] Swap callbacks work correctly

### US-CRANE-144.2: StablePoolFactory Deployment

As a deployer, I want a factory to create stable pools.

**Acceptance Criteria:**
- [ ] StablePoolFactory deployable
- [ ] Factory can create pools that register with Diamond Vault
- [ ] Amplification parameter configurable

### US-CRANE-144.3: Test Suite

As a developer, I want comprehensive tests for stable pools.

**Acceptance Criteria:**
- [ ] Fork Balancer's stable pool tests
- [ ] All original tests pass
- [ ] Amplification edge cases tested
- [ ] Integration with Diamond Vault verified

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── pools/
│   └── stable/
│       ├── StablePool.sol (or facets if needed)
│       └── StablePoolFactory.sol
```

### Key Contracts

| Contract | Source Size | Analysis Needed |
|----------|-------------|-----------------|
| StablePool.sol | ~TBD | Check if <24KB compiled |
| StablePoolFactory.sol | ~TBD | Check if <24KB compiled |

## Files to Create/Modify

**New/Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/stable/*.sol`
- `test/foundry/protocols/balancer/v3/pools/stable/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/pool-stable/contracts/*.sol`

## Completion Criteria

- [ ] All pool contracts compile to <24KB
- [ ] Pools work with Diamond Vault
- [ ] Factory creates valid pools
- [ ] Tests pass
- [ ] Fork tests verify identical behavior

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
