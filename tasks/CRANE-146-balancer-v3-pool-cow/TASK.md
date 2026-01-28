# Task CRANE-146: Refactor Balancer V3 CoW Pool Package

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-pool-cow`

---

## Description

Refactor the Balancer V3 CoW Pool package (pkg/pool-cow) to ensure all contracts are deployable within the 24KB limit. CoW (Coincidence of Wants) pools are specialized pools that integrate with CoW Protocol for MEV protection.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Pools register with and interact with Vault

## User Stories

### US-CRANE-146.1: CowPool Deployment

As a deployer, I want CowPool to be deployable so that I can create CoW-integrated pools.

**Acceptance Criteria:**
- [ ] CowPool compiles to <24KB (or refactored if needed)
- [ ] Pool registers with Diamond Vault successfully
- [ ] CoW Protocol integration works

### US-CRANE-146.2: CowPoolFactory Deployment

As a deployer, I want a factory to create CoW pools.

**Acceptance Criteria:**
- [ ] CowPoolFactory deployable
- [ ] Factory creates pools that register with Diamond Vault

### US-CRANE-146.3: CowRouter

As a user, I want to interact with CoW pools through the CowRouter.

**Acceptance Criteria:**
- [ ] CowRouter deployable
- [ ] Router works with Diamond Vault

### US-CRANE-146.4: Test Suite

As a developer, I want comprehensive tests for CoW pools.

**Acceptance Criteria:**
- [ ] Fork Balancer's CoW pool tests
- [ ] All original tests pass
- [ ] Integration with Diamond Vault verified

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── pools/
│   └── cow/
│       ├── CowPool.sol
│       ├── CowPoolFactory.sol
│       └── CowRouter.sol
```

### Key Contracts

| Contract | Source Size | Analysis Needed |
|----------|-------------|-----------------|
| CowPool.sol | TBD | Check if <24KB compiled |
| CowPoolFactory.sol | TBD | Check if <24KB compiled |
| CowRouter.sol | TBD | Check if <24KB compiled |

## Files to Create/Modify

**New/Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/*.sol`
- `test/foundry/protocols/balancer/v3/pools/cow/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/pool-cow/contracts/*.sol`

## Completion Criteria

- [ ] All pool contracts compile to <24KB
- [ ] Pools work with Diamond Vault
- [ ] Factory creates valid pools
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
