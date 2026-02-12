# Task CRANE-153: Port Resupply Protocol to Local Contracts

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/resupply-port`

---

## Description

Port the Resupply protocol contracts into `contracts/protocols/cdps/resupply/`.

Resupply is a CDP (Collateralized Debt Position) protocol with a large surface area (DAO/governance, staking, emissions, lending pairs, oracles, and integrations with Curve/Frax/Convex/Prisma).

Important: follow the temporary dependency workflow. After creating the worktree, install upstream in the worktree via `forge install <URL>`, pin to the commit recorded below, port, then remove the installed dependency once validation/tests pass.

## Goal

Vendor Resupply locally (pin + port + tests) so Crane does not rely on an external Resupply source.

## Source Analysis

**Source:** https://github.com/resupplyfi/resupply
**Pinned upstream commit:** 71e01acf3e40f5ff2888afc9e6a73d6079a2f71f
**Temporary install (run inside worktree):** `forge install https://github.com/resupplyfi/resupply`
**Target Location:** `contracts/protocols/cdps/resupply/`
**Current Local Port:** none
**Estimated Scope:** large (original task assumed ~160 Solidity files)

### Source Structure (to be confirmed once upstream is pinned)

```
src/
├── Constants.sol
├── dao/ (27 files)
│   ├── Core.sol, GovToken.sol, Voter.sol, Treasury.sol
│   ├── CurveLendMinterFactory.sol, CurveLendOperator.sol
│   ├── RetentionIncentives.sol
│   ├── emissions/
│   │   ├── EmissionsController.sol
│   │   └── receivers/ (4 files)
│   ├── operators/ (7 files)
│   │   ├── BaseUpgradeableOperator.sol, Guardian.sol
│   │   ├── BorrowLimitController.sol, PairAdder.sol
│   │   └── TreasuryManager*.sol
│   ├── staking/ (4 files)
│   │   ├── GovStaker.sol, GovStakerEscrow.sol
│   │   ├── AutoStakeCallback.sol, MultiRewardsDistributor.sol
│   └── tge/ (3 files)
│       ├── PermaStaker.sol, VestManager.sol, VestManagerBase.sol
├── dependencies/ (3 files)
│   ├── CoreOwnable.sol, DelegatedOps.sol, EpochTracker.sol
├── helpers/ (4 files)
│   ├── VestManagerHarness.sol
│   └── keepers/ (Keeper, KeeperV1, KeeperV2)
├── interfaces/ (~90 files)
│   ├── Core interfaces (ICore, IGovToken, IVoter, etc.)
│   ├── Protocol interfaces (IResupplyPair, IOracle, etc.)
│   ├── chainlink/ (IChainlinkOracle)
│   ├── convex/ (4 files)
│   ├── curve/ (13 files)
│   ├── frax/ (2 files)
│   ├── operators/ (2 files)
│   ├── oracles/abstracts/ (5 files)
│   └── prisma/ (3 files)
├── libraries/ (9 files)
│   ├── BytesLib.sol, MathUtil.sol, SafeERC20.sol, VaultAccount.sol
│   └── solmate/ (ERC20, ERC4626, FixedPointMathLib, SafeCastLib, SafeTransferLib)
└── protocol/ (27 files)
    ├── Core: ResupplyPair.sol, ResupplyPairDeployer.sol, ResupplyRegistry.sol
    ├── Handlers: LiquidationHandler.sol, RedemptionHandler.sol, RewardHandler.sol
    ├── Oracles: BasicVaultOracle.sol, ReusdOracle.sol, UnderlyingOracle.sol
    ├── Interest: InterestRateCalculator.sol, InterestRateCalculatorV2.sol
    ├── Fees: FeeDeposit.sol, FeeDepositController.sol, FeeLogger.sol
    ├── Stablecoin: Stablecoin.sol, WriteOffToken.sol
    ├── Insurance: InsurancePool.sol, PriceWatcher.sol
    ├── Rewards: RewardDistributorMultiEpoch.sol, SimpleRewardStreamer.sol
    ├── Swapping: Swapper.sol, SwapperOdos.sol
    ├── Utilities.sol
    ├── pair/ (3 files)
    │   ├── IResupplyPairErrors.sol, ResupplyPairConstants.sol, ResupplyPairCore.sol
    └── sreusd/ (2 files)
        ├── LinearRewardsErc4626.sol, sreUSD.sol
```

## Dependencies

Pinned upstream source recorded above (repo + commit).

**External Protocol Dependencies (interfaces only):**
- Curve Finance (lending, pools, gauges)
- Convex Finance (staking wrappers)
- Frax Finance (lending)
- Prisma Finance (voter proxy)
- Chainlink (oracles)

## User Stories

### US-CRANE-153.M1: Milestone - Minimal Compile + Proof-of-Use + Dependency Removal

As a developer, I want a clear first milestone that proves the port is viable end-to-end (install upstream temporarily, port into Crane-owned paths, compile, run at least one meaningful test), then removes the upstream dependency before merging.

**Acceptance Criteria:**
- [ ] Create worktree `feature/resupply-port`
- [ ] In the worktree, install upstream Resupply for reference only: `forge install https://github.com/resupplyfi/resupply`
- [ ] Checkout pinned commit `71e01acf3e40f5ff2888afc9e6a73d6079a2f71f`
- [ ] Port Resupply sources into `contracts/protocols/cdps/resupply/` (initial milestone scope: enough files to `forge build` the ported tree)
- [ ] Add a minimal compile/deploy test that exercises at least one Resupply core contract interaction (smoke test; can use stubs/mocks for external integrations)
- [ ] Remove the installed upstream dependency (`lib/resupply` and any remappings/lock entries it introduced)
- [ ] Verify no lingering dependency remains:
  - [ ] `rg "lib/resupply" -n .` has no matches
  - [ ] `forge build` succeeds
  - [ ] The new Resupply smoke test passes

### US-CRANE-153.0: Pin Upstream Source

As a developer, I want the Resupply source pinned so porting is deterministic.

**Acceptance Criteria:**
- [ ] Record upstream repo URL
- [ ] Record pinned commit hash or release tag
- [ ] Record the exact upstream source root we are porting from (e.g. `src/`)
- [ ] Add a short note on license and any required attributions

### US-CRANE-153.1: Port DAO Core Contracts

As a developer, I want Resupply DAO contracts available locally.

**Acceptance Criteria:**
- [ ] Core.sol ported
- [ ] GovToken.sol ported
- [ ] Voter.sol ported
- [ ] Treasury.sol ported
- [ ] CurveLendMinterFactory.sol ported
- [ ] CurveLendOperator.sol ported
- [ ] RetentionIncentives.sol ported

### US-CRANE-153.2: Port Emissions System

As a developer, I want emissions contracts ported.

**Acceptance Criteria:**
- [ ] EmissionsController.sol ported
- [ ] All receiver contracts ported (Example, Retention, Simple, Factory)

### US-CRANE-153.3: Port Operators

As a developer, I want operator contracts ported.

**Acceptance Criteria:**
- [ ] BaseUpgradeableOperator.sol ported
- [ ] Guardian.sol and GuardianUpgradeable.sol ported
- [ ] BorrowLimitController.sol ported
- [ ] PairAdder.sol ported
- [ ] TreasuryManager.sol and TreasuryManagerUpgradeable.sol ported

### US-CRANE-153.4: Port Staking System

As a developer, I want staking contracts ported.

**Acceptance Criteria:**
- [ ] GovStaker.sol ported
- [ ] GovStakerEscrow.sol ported
- [ ] AutoStakeCallback.sol ported
- [ ] MultiRewardsDistributor.sol ported

### US-CRANE-153.5: Port TGE Contracts

As a developer, I want token generation event contracts ported.

**Acceptance Criteria:**
- [ ] PermaStaker.sol ported
- [ ] VestManager.sol ported
- [ ] VestManagerBase.sol ported

### US-CRANE-153.6: Port Protocol Core

As a developer, I want core lending protocol contracts ported.

**Acceptance Criteria:**
- [ ] ResupplyPair.sol ported
- [ ] ResupplyPairDeployer.sol ported
- [ ] ResupplyRegistry.sol ported
- [ ] ResupplyPairCore.sol, ResupplyPairConstants.sol ported

### US-CRANE-153.7: Port Handlers

As a developer, I want protocol handler contracts ported.

**Acceptance Criteria:**
- [ ] LiquidationHandler.sol ported
- [ ] RedemptionHandler.sol ported
- [ ] RewardHandler.sol ported

### US-CRANE-153.8: Port Oracles

As a developer, I want oracle contracts ported.

**Acceptance Criteria:**
- [ ] BasicVaultOracle.sol ported
- [ ] ReusdOracle.sol ported
- [ ] UnderlyingOracle.sol ported

### US-CRANE-153.9: Port Interest Rate System

As a developer, I want interest rate contracts ported.

**Acceptance Criteria:**
- [ ] InterestRateCalculator.sol ported
- [ ] InterestRateCalculatorV2.sol ported

### US-CRANE-153.10: Port Fee System

As a developer, I want fee management contracts ported.

**Acceptance Criteria:**
- [ ] FeeDeposit.sol ported
- [ ] FeeDepositController.sol ported
- [ ] FeeLogger.sol ported

### US-CRANE-153.11: Port Stablecoin Contracts

As a developer, I want stablecoin contracts ported.

**Acceptance Criteria:**
- [ ] Stablecoin.sol ported (reUSD)
- [ ] WriteOffToken.sol ported
- [ ] sreUSD.sol (staked reUSD) ported
- [ ] LinearRewardsErc4626.sol ported

### US-CRANE-153.12: Port Supporting Contracts

As a developer, I want supporting infrastructure ported.

**Acceptance Criteria:**
- [ ] InsurancePool.sol ported
- [ ] PriceWatcher.sol ported
- [ ] Swapper.sol and SwapperOdos.sol ported
- [ ] RewardDistributorMultiEpoch.sol ported
- [ ] SimpleRewardStreamer.sol ported
- [ ] Utilities.sol ported

### US-CRANE-153.13: Port Dependencies

As a developer, I want dependency contracts ported.

**Acceptance Criteria:**
- [ ] CoreOwnable.sol ported
- [ ] DelegatedOps.sol ported
- [ ] EpochTracker.sol ported
- [ ] Constants.sol ported

### US-CRANE-153.14: Port Libraries

As a developer, I want all libraries ported.

**Acceptance Criteria:**
- [ ] BytesLib.sol ported
- [ ] MathUtil.sol ported
- [ ] SafeERC20.sol ported
- [ ] VaultAccount.sol ported
- [ ] solmate/ libraries ported (ERC20, ERC4626, FixedPointMathLib, SafeCastLib, SafeTransferLib)

### US-CRANE-153.15: Port All Interfaces

As a developer, I want all ~90 interface files available.

**Acceptance Criteria:**
- [ ] Core interfaces ported (~40 files)
- [ ] Chainlink interface ported
- [ ] Convex interfaces ported (4 files)
- [ ] Curve interfaces ported (13 files)
- [ ] Frax interfaces ported (2 files)
- [ ] Operator interfaces ported (2 files)
- [ ] Oracle abstract interfaces ported (5 files)
- [ ] Prisma interfaces ported (3 files)

### US-CRANE-153.16: Port Helpers

As a developer, I want helper contracts ported.

**Acceptance Criteria:**
- [ ] VestManagerHarness.sol ported
- [ ] Keeper contracts ported (Keeper, KeeperV1, KeeperV2)

### US-CRANE-153.17: Test Suite Adaptation

As a developer, I want comprehensive tests for ported contracts.

**Acceptance Criteria:**
- [ ] Fork/adapt Resupply's test suite
- [ ] All critical path tests pass
- [ ] Integration tests verified

## Technical Details

### Key Considerations

1. **CDP Protocol:** Resupply is a collateralized debt position system - different from DEX protocols. Focus on lending pair mechanics, liquidations, and stablecoin minting.
2. **External Integrations:** Heavy integration with Curve, Convex, Frax, Prisma, and Chainlink via interfaces.
3. **ERC-4626 Vaults:** Uses vault pattern for yield-bearing positions.
4. **Governance:** Full DAO with voting, staking, emissions, and vesting.
5. **Solmate Dependencies:** Uses solmate's ERC20, ERC4626, and math libraries.

### File Structure After Port

```
contracts/protocols/cdps/resupply/
├── Constants.sol
├── dao/
│   ├── Core.sol, GovToken.sol, Voter.sol, Treasury.sol
│   ├── emissions/
│   ├── operators/
│   ├── staking/
│   └── tge/
├── dependencies/
├── helpers/
├── interfaces/
│   ├── (core interfaces)
│   ├── chainlink/, convex/, curve/, frax/, prisma/
│   ├── operators/, oracles/
├── libraries/
│   └── solmate/
└── protocol/
    ├── (core protocol contracts)
    ├── pair/
    └── sreusd/
```

## Files to Create/Modify

**New Files:**
- All required Resupply contracts copied from the pinned upstream source

**Tests:**
- `test/foundry/protocols/cdps/resupply/*.t.sol`

## Completion Criteria

- [ ] Pinned upstream source recorded in this task (repo URL + commit/tag)
- [ ] Temporary upstream dependency removed after validation (no lingering `lib/resupply` usage)
- [ ] All required source files ported (count depends on upstream)
- [ ] Directory structure preserved
- [ ] All interfaces available
- [ ] Import paths use local contracts only
- [ ] Adapted test suite passes
- [ ] No dependency on an external `lib/resupply` source remains

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
