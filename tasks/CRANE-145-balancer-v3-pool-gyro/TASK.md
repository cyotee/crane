# Task CRANE-145: Refactor Balancer V3 Gyro Pool Package

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-pool-gyro`

---

## Description

Refactor the Balancer V3 Gyro Pool package (pkg/pool-gyro) to ensure all contracts are deployable within the 24KB limit. Gyro pools include ECLP (Elliptic Concentrated Liquidity Pool) and 2CLP variants with complex mathematical invariants.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Pools register with and interact with Vault

## User Stories

### US-CRANE-145.1: GyroECLPPool Deployment

As a deployer, I want GyroECLPPool to be deployable so that I can create ECLP pools.

**Acceptance Criteria:**
- [ ] GyroECLPPool compiles to <24KB (or refactored if needed)
- [ ] GyroECLPMath library works correctly
- [ ] Pool registers with Diamond Vault successfully
- [ ] Elliptic curve math works correctly

### US-CRANE-145.2: Gyro2CLPPool Deployment

As a deployer, I want Gyro2CLPPool to be deployable.

**Acceptance Criteria:**
- [ ] Gyro2CLPPool compiles to <24KB
- [ ] Gyro2CLPMath library works correctly
- [ ] Pool registers with Diamond Vault

### US-CRANE-145.3: Gyro Factories

As a deployer, I want factories to create Gyro pools.

**Acceptance Criteria:**
- [ ] GyroECLPPoolFactory deployable
- [ ] Gyro2CLPPoolFactory deployable
- [ ] Factories create pools that register with Diamond Vault

### US-CRANE-145.4: Test Suite

As a developer, I want comprehensive tests for Gyro pools.

**Acceptance Criteria:**
- [ ] Fork Balancer's Gyro pool tests
- [ ] All original tests pass
- [ ] Complex math edge cases tested
- [ ] Integration with Diamond Vault verified

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── pools/
│   └── gyro/
│       ├── GyroECLPPool.sol
│       ├── GyroECLPPoolFactory.sol
│       ├── Gyro2CLPPool.sol
│       ├── Gyro2CLPPoolFactory.sol
│       └── lib/
│           ├── GyroECLPMath.sol
│           ├── Gyro2CLPMath.sol
│           ├── GyroPoolMath.sol
│           └── SignedFixedPoint.sol
```

### Key Contracts

| Contract | Source Size | Analysis Needed |
|----------|-------------|-----------------|
| GyroECLPPool.sol | TBD | Check if <24KB compiled |
| Gyro2CLPPool.sol | TBD | Check if <24KB compiled |
| GyroECLPMath.sol | TBD | Complex math library |

## Files to Create/Modify

**New/Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/gyro/*.sol`
- `test/foundry/protocols/balancer/v3/pools/gyro/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/pool-gyro/contracts/*.sol`

## Completion Criteria

- [ ] All pool contracts compile to <24KB
- [ ] Pools work with Diamond Vault
- [ ] Factories create valid pools
- [ ] Tests pass
- [ ] Fork tests verify identical behavior

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
