# Task CRANE-153: Port Resupply Protocol to Local Contracts

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/resupply-port`

---

## Description

Port the Resupply protocol contracts from `lib/resupply/src/` into `contracts/protocols/cdps/resupply/`. Resupply is a CDP (Collateralized Debt Position) protocol with 160 source files covering DAO governance, staking, emissions, lending pairs, oracles, and integrations with Curve, Frax, Convex, and Prisma. The ported contracts must be behavior and interface equivalent as drop-in replacements, enabling eventual removal of the submodule.

## Goal

Enable removal of `lib/resupply` submodule by having a complete local port with functional test suite.

## Source Analysis

**Submodule Location:** `lib/resupply/src/`
**Target Location:** `contracts/protocols/cdps/resupply/`
**Current Local Port:** Empty directory (0 files)
**Total Files to Port:** 160

### Source Structure

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

None — this is a port task.

**External Protocol Dependencies (interfaces only):**
- Curve Finance (lending, pools, gauges)
- Convex Finance (staking wrappers)
- Frax Finance (lending)
- Prisma Finance (voter proxy)
- Chainlink (oracles)

## User Stories

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

**New Files (160):**
- All contracts from lib/resupply/src/

**Tests:**
- `test/foundry/protocols/cdps/resupply/*.t.sol`

## Completion Criteria

- [ ] All 160 source files ported
- [ ] Directory structure preserved
- [ ] All interfaces available
- [ ] Import paths use local contracts only
- [ ] Adapted test suite passes
- [ ] Submodule can be safely removed

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
