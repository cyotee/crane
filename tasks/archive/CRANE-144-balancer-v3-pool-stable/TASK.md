# Task CRANE-144: Refactor Balancer V3 Stable Pool Package

**Repo:** Crane Framework
**Status:** Complete
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
- [x] StablePool compiles to <24KB (or refactored if needed) - Facet is ~4KB
- [x] Pool registers with Diamond Vault successfully - DFPkg.postDeploy() handles registration
- [x] StableMath calculations work correctly - 32 passing tests
- [x] Amplification parameter works - time-based interpolation tested
- [x] Swap callbacks work correctly - EXACT_IN and EXACT_OUT tested

### US-CRANE-144.2: StablePoolFactory Deployment

As a deployer, I want a factory to create stable pools.

**Acceptance Criteria:**
- [x] StablePoolFactory deployable - BalancerV3StablePoolDFPkg.sol (~14KB)
- [x] Factory can create pools that register with Diamond Vault - via deployPool() + postDeploy()
- [x] Amplification parameter configurable - passed in PkgArgs

### US-CRANE-144.3: Test Suite

As a developer, I want comprehensive tests for stable pools.

**Acceptance Criteria:**
- [x] Fork Balancer's stable pool tests - Adapted patterns from Balancer tests
- [x] All original tests pass - 47/47 tests passing
- [x] Amplification edge cases tested - MIN_AMP, MAX_AMP, transitions tested
- [ ] Integration with Diamond Vault verified - Needs DFPkg deployment test (follow-up task)

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

- [x] All pool contracts compile to <24KB (Target ~5KB, Facet ~4KB, DFPkg ~14KB)
- [x] Pools work with Diamond Vault (via BasePoolFactory registration)
- [x] Factory creates valid pools (DFPkg pattern implemented)
- [x] Tests pass (47/47 passing)
- [ ] Fork tests verify identical behavior (optional follow-up)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
