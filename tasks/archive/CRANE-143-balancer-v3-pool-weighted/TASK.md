# Task CRANE-143: Refactor Balancer V3 Weighted Pool Package

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-pool-weighted`

---

## Description

Refactor the Balancer V3 Weighted Pool package (pkg/pool-weighted) to ensure all contracts are deployable within the 24KB limit. This includes WeightedPool, WeightedPoolFactory, and the LBP (Liquidity Bootstrapping Pool) contracts.

The pools must work with the Diamond Vault from CRANE-141.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Pools register with and interact with Vault

## User Stories

### US-CRANE-143.1: WeightedPool Deployment

As a deployer, I want WeightedPool to be deployable so that I can create weighted pools.

**Acceptance Criteria:**
- [ ] WeightedPool compiles to <24KB (or refactored if needed)
- [ ] Pool registers with Diamond Vault successfully
- [ ] All weighted math functions work
- [ ] Swap callbacks work correctly

### US-CRANE-143.2: WeightedPoolFactory Deployment

As a deployer, I want a factory to create weighted pools.

**Acceptance Criteria:**
- [ ] WeightedPoolFactory deployable
- [ ] Factory can create pools that register with Diamond Vault
- [ ] All factory parameters work

### US-CRANE-143.3: LBP Contracts (if oversized)

As a deployer, I want LBP functionality available.

**Acceptance Criteria:**
- [ ] LBPool deployable
- [ ] LBPoolFactory deployable
- [ ] Weight update mechanism works
- [ ] Time-based weight transitions work

### US-CRANE-143.4: Test Suite

As a developer, I want comprehensive tests for weighted pools.

**Acceptance Criteria:**
- [ ] Fork Balancer's weighted pool tests
- [ ] All original tests pass
- [ ] Integration with Diamond Vault verified

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── pools/
│   └── weighted/
│       ├── WeightedPool.sol (or facets if needed)
│       ├── WeightedPoolFactory.sol
│       └── lbp/
│           ├── LBPool.sol
│           └── LBPoolFactory.sol
```

### Key Contracts

| Contract | Source Size | Analysis Needed |
|----------|-------------|-----------------|
| WeightedPool.sol | TBD | Check if <24KB compiled |
| WeightedPoolFactory.sol | TBD | Check if <24KB compiled |
| LBPool.sol | TBD | Check if <24KB compiled |

## Files to Create/Modify

**New/Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/weighted/*.sol`
- `test/foundry/protocols/balancer/v3/pools/weighted/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/pool-weighted/contracts/*.sol`

## Completion Criteria

- [ ] All pool contracts compile to <24KB
- [ ] Pools work with Diamond Vault
- [ ] Factory creates valid pools
- [ ] Tests pass
- [ ] Fork tests verify identical behavior

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
