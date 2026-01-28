# Task CRANE-147: Refactor Balancer V3 Pool Hooks Package

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-pool-hooks`

---

## Description

Refactor the Balancer V3 Pool Hooks package (pkg/pool-hooks) to ensure all contracts are deployable within the 24KB limit. This package contains various hook implementations including StableSurge, MEV Capture, Exit Fee, and other hook examples.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Hooks integrate with Vault callbacks

## User Stories

### US-CRANE-147.1: StableSurgeHook Deployment

As a deployer, I want StableSurgeHook to be deployable for dynamic fee pools.

**Acceptance Criteria:**
- [ ] StableSurgeHook compiles to <24KB
- [ ] StableSurgePoolFactory compiles to <24KB
- [ ] Hook integrates with Diamond Vault
- [ ] Surge pricing mechanism works

### US-CRANE-147.2: MevCaptureHook Deployment

As a deployer, I want MevCaptureHook to be deployable for MEV protection.

**Acceptance Criteria:**
- [ ] MevCaptureHook compiles to <24KB
- [ ] Hook integrates with Diamond Vault
- [ ] MEV capture mechanism works

### US-CRANE-147.3: Other Hook Examples

As a deployer, I want other hook examples deployable.

**Acceptance Criteria:**
- [ ] ExitFeeHookExample deployable
- [ ] DirectionalFeeHookExample deployable
- [ ] VeBALFeeDiscountHookExample deployable
- [ ] ECLPSurgeHook deployable

### US-CRANE-147.4: MinimalRouter

As a deployer, I want MinimalRouter deployable for hook testing.

**Acceptance Criteria:**
- [ ] MinimalRouter compiles to <24KB
- [ ] Works with Diamond Vault

### US-CRANE-147.5: Test Suite

As a developer, I want comprehensive tests for hooks.

**Acceptance Criteria:**
- [ ] Fork Balancer's hook tests
- [ ] All original tests pass
- [ ] Integration with Diamond Vault verified

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── hooks/
│   ├── StableSurgeHook.sol
│   ├── StableSurgePoolFactory.sol
│   ├── MevCaptureHook.sol
│   ├── ExitFeeHookExample.sol
│   ├── DirectionalFeeHookExample.sol
│   ├── VeBALFeeDiscountHookExample.sol
│   ├── ECLPSurgeHook.sol
│   ├── NftLiquidityPositionExample.sol
│   ├── MinimalRouter.sol
│   └── utils/
│       └── StableSurgeMedianMath.sol
```

### Key Contracts

| Contract | Analysis Needed |
|----------|-----------------|
| StableSurgeHook.sol | Check size |
| MevCaptureHook.sol | Check size |
| StableSurgePoolFactory.sol | Check size |

## Files to Create/Modify

**New/Modified Files:**
- `contracts/protocols/dexes/balancer/v3/hooks/*.sol`
- `test/foundry/protocols/balancer/v3/hooks/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/pool-hooks/contracts/*.sol`

## Completion Criteria

- [ ] All hook contracts compile to <24KB
- [ ] Hooks work with Diamond Vault
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
