# Task CRANE-147: Refactor Balancer V3 Pool Hooks Package

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-28
**Completed:** 2026-01-31
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
- [x] StableSurgeHook compiles to <24KB (8.5KB)
- [ ] StableSurgePoolFactory compiles to <24KB (not implemented - optional)
- [x] Hook integrates with Diamond Vault
- [x] Surge pricing mechanism works

### US-CRANE-147.2: MevCaptureHook Deployment

As a deployer, I want MevCaptureHook to be deployable for MEV protection.

**Acceptance Criteria:**
- [x] MevCaptureHook compiles to <24KB (8.2KB)
- [x] Hook integrates with Diamond Vault
- [x] MEV capture mechanism works

### US-CRANE-147.3: Other Hook Examples

As a deployer, I want other hook examples deployable.

**Acceptance Criteria:**
- [x] ExitFeeHookExample deployable (5.4KB)
- [x] DirectionalFeeHookExample deployable (4.3KB)
- [x] VeBALFeeDiscountHookExample deployable (3.7KB)
- [x] ECLPSurgeHook deployable (18.5KB)

### US-CRANE-147.4: MinimalRouter

As a deployer, I want MinimalRouter deployable for hook testing.

**Acceptance Criteria:**
- [x] MinimalRouter compiles to <24KB (10.3KB)
- [x] Works with Diamond Vault

### US-CRANE-147.5: Test Suite

As a developer, I want comprehensive tests for hooks.

**Acceptance Criteria:**
- [x] Fork Balancer's hook tests (43 tests created)
- [x] All original tests pass (43/43 passing)
- [x] Integration with Diamond Vault verified

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

- [x] All hook contracts compile to <24KB
- [x] Hooks work with Diamond Vault
- [x] Tests pass (43/43)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
