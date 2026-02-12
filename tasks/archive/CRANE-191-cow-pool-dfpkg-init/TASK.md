# Task CRANE-191: Add DFPkg for CoW Pool and Router Initialization

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-31
**Dependencies:** CRANE-146
**Worktree:** `feature/cow-pool-dfpkg`
**Origin:** Code review suggestion from CRANE-146

---

## Description

Add proper deployment story that wires required storage in `CowPoolRepo` and `CowRouterRepo` during diamond initialization via `IDiamondFactoryPackage.initAccount()`.

Currently:
- `CowPoolRepo._initialize(...)` and `CowRouterRepo._initialize(...)` are internal-only
- No on-chain/external entrypoints call them during deployment
- `CowPoolTarget.onRegister(...)` will always fail (stored `cowPoolFactory` defaults to `address(0)`)
- `CowRouterTarget.withdrawCollectedProtocolFees(...)` depends on a configured `feeSweeper` which is unset

This task creates DFPkg contracts that properly initialize:
- `CowPoolRepo`: `cowPoolFactory`, `trustedCowRouter`
- `CowRouterRepo`: `protocolFeePercentage`, `feeSweeper`

(Created from code review of CRANE-146)

## Dependencies

- CRANE-146: Refactor Balancer V3 CoW Pool Package (parent task, complete)

## User Stories

### US-CRANE-191.1: CoW Pool DFPkg with Proper Initialization

As a deployer, I want a DFPkg that initializes CoW pool storage so that pool registration succeeds against the Vault.

**Acceptance Criteria:**
- [x] `CowPoolDFPkg` implements `IDiamondFactoryPackage`
- [x] `initAccount()` calls `CowPoolRepo._initialize(cowPoolFactory, trustedCowRouter)`
- [x] `calcSalt()` includes relevant config in deterministic address calculation
- [x] Pool can successfully register with Vault after deployment

### US-CRANE-191.2: CoW Router DFPkg with Proper Initialization

As a deployer, I want a DFPkg that initializes CoW router storage so that fee collection works correctly.

**Acceptance Criteria:**
- [x] `CowRouterDFPkg` implements `IDiamondFactoryPackage`
- [x] `initAccount()` calls `CowRouterRepo._initialize(protocolFeePercentage, feeSweeper)`
- [x] `calcSalt()` includes relevant config in deterministic address calculation
- [x] Fee sweeper is correctly configured after deployment

### US-CRANE-191.3: Integration Tests for DFPkg Deployment

As a developer, I want integration tests verifying the DFPkg deployment flow.

**Acceptance Criteria:**
- [x] Test deploys CoW pool via DFPkg and verifies storage initialization
- [x] Test deploys CoW router via DFPkg and verifies storage initialization
- [x] Test verifies Vault registration succeeds after initialization

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg.sol`
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg_Integration.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg_Integration.t.sol`

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolRepo.sol` (if visibility changes needed)
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterRepo.sol` (if visibility changes needed)

## Inventory Check

Before starting, verify:
- [x] CRANE-146 is complete
- [x] CowPoolRepo.sol exists with _initialize function
- [x] CowRouterRepo.sol exists with _initialize function

## Implementation Notes

1. Follow the DFPkg pattern from `BalancerV3GyroECLPPoolDFPkg` (CRANE-145)
2. The `calcSalt()` should include factory address and router address for determinism
3. Consider whether pool and router need separate DFPkgs or can share one
4. Ensure `postDeploy()` is used appropriately for any post-initialization steps

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass: `forge test --match-path 'test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/**/*.t.sol'`
- [x] Build succeeds
- [x] Contract sizes within limits

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
