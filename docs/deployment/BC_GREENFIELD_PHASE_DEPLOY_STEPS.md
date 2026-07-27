---
project: BattleChain greenfield — all phase deploy steps
version: 1.0
status: active
created: 2026-07-23
last_updated: 2026-07-23
purpose: Implementation-plan source of truth for every phase
related:
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
  - docs/deployment/BC_GREENFIELD_MASTER_PLAN.md
  - docs/deployment/BC_GREENFIELD_COMMANDS.md
  - docs/deployment/BC_GREENFIELD_X_POSTS.md
  - docs/deployment/BC_AAVE_V4_DEPLOY_STEPS.md
  - docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md
---

# BC greenfield — deploy steps for all phases

**Use this file** (plus the Aave V4 deep-dive) for step detail.  
**Formal implementation plan:** [`../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md`](../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md) (goal: one script per phase, all compiling; X posts separate).

**Global rules (every phase):**

1. Scripts hardcode **all** options — operator runs one command only ([`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md)).  
2. **Bind** BC-provided deps; never redeploy them ([research §1](./BC_GREENFIELD_DEPLOY_RESEARCH.md)).  
3. Crane-owned code deploys via Phase 1 **Create3Factory** (CREATE3 / packages) unless noted.  
4. After live: agent updates docs addresses → post pre-drafted X.  
5. No live BC until master plan §0 gate (all scripts + all X drafts).  
6. Phase **11 Resupply = dropped**.

**Shared operator prelude:**

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane
export DEPLOYER=$(cast wallet address --account deployer)
```

**Shared forge flags:**  
`--rpc-url battlechain-sepolia --broadcast --skip-simulation --account deployer --sender "$DEPLOYER" -g 400`

---

## Phase 0 — Prerequisites (local; no BC broadcast)

### Goal
Idempotent factory + shared script base so all phase scripts can re-run safely.

### Steps

| # | Step | Detail | Done |
|---|------|--------|:----:|
| 0.1 | Fix `_create3WithArgs` | Early-return if predicted address has code (mirror `_create3`) in Create3FactoryService (+ factory path if needed) | [ ] |
| 0.2 | Registration safety | Double package/facet deploy does not corrupt registries | [ ] |
| 0.3 | Unit tests | Double deploy same salt → same address, no revert | [ ] |
| 0.4 | Shared base | `BCPhaseScriptBase`: sender ≠ 0x1804…, bind priority, abandoned factory hard-revert, manifest JSON/table write, docs handoff log | [ ] |
| 0.5 | Abandoned constant | `ABANDONED_CREATE3_FACTORY = 0xC8E93C3c…AD3A` | [ ] |
| 0.6 | Expand `BC_TESTNET` | Add Euler, Venus, Morpho, Safe, Kyber binds (addresses from research) | [ ] |

### Script / test

- Tests: `forge test --match-contract Create3Factory`  
- Code: `Create3FactoryService`, `scripts/foundry/bc/BCPhaseScriptBase.s.sol`

### Exit criteria

- [ ] Idempotency tests green  
- [ ] Base compiles; phase scripts can extend it  

---

## Phase 1 — Crane factory system

### Goal
New Create3Factory root + diamond factory + permit surface + Uni V2/V4 stubs + Permit2 + Safe Harbor + attack mode.

### Baseline
`Script_Promo_BC_Launch.s.sol` → rename/port to `Script_BC_Phase1_Factories.s.sol`

### Bind (never deploy)

| Asset | Address |
|-------|---------|
| WETH | `0x4CAc…1f42` |
| Uni V3 Factory / Router / NPM | BC mocks (research §1.3) |
| SafeHarbor / AttackRegistry / BC Deployer | `BC_TESTNET` |

### Deploy order (fixed)

| # | Step | How | Salt / note |
|---|------|-----|-------------|
| 1.1 | Create3Factory + DiamondPackageCallBackFactory | `InitBcService.initEnvBc(owner, _bcDeployer())` | BC Deployer lineage |
| 1.2 | ERC20Facet | `deployFacet` | name hash salt |
| 1.3 | ERC5267Facet | `deployFacet` | |
| 1.4 | ERC2612Facet | `deployFacet` | |
| 1.5 | ERC20PermitDFPkg | `deployPackageWithArgs` with facet init | |
| 1.6 | Sample ERC20Permit diamond | `diamondFactory.deploy` | CBCP name/symbol/supply hardcoded |
| 1.7 | UniV2Factory | `create3` | `keccak256("bc-promo-UniV2Factory-v1")` |
| 1.8 | UniV2Router02 | `create3` (factory, weth) | `bc-promo-UniV2Router02-v1` |
| 1.9 | Uni V4 PoolManager | `create3` | `bc-promo-UniV4PoolManager-v1` |
| 1.10 | BetterPermit2 | `create3` | `bc-promo-BetterPermit2-v1` |
| 1.11 | Safe Harbor agreement | Scope = Create3Factory only, `ChildContractScope.All` | new salt for greenfield gen |
| 1.12 | `requestAttackMode` | On that agreement only | Phase 1 only |

### Hardcoded constants

- Sample token: name/symbol/decimals/supply as current Launch script  
- Security contact: real value before public attack-mode marketing (placeholder allowed until then)  
- Recovery = deployer  

### Post-steps

| # | Action |
|---|--------|
| 1.A | Write `battlechain-sepolia.json` + table + runtime JSON |
| 1.B | Agent: `BC_TESTNET` + `deployed-addresses.md` |
| 1.C | X: Phase 1 draft |

### Exit criteria

- [ ] Factory ≠ abandoned gen-1  
- [ ] All 1.1–1.12 have code / agreement live  
- [ ] Re-broadcast is no-op success  

---

## Phase 2 — Balancer V3

### Goal
Full Balancer surface under Phase 1 factory: TimelockAuthorizer, vault, router, all pool packages (2a then 2b in script; both before live gate).

### Baseline
`Script_Promo_BC_BalancerV3.s.sol` → `Script_BC_Phase2_BalancerV3.s.sol`  
**Changes:** TimelockAuthorizer (not Null); bind Phase 1 via manifest (not abandoned constants); no second agreement/attack mode; add 2b packages + rate provider DFPkg.

### Bind

| Role | Source |
|------|--------|
| Create3Factory, DiamondFactory | Phase 1 manifest |
| WETH, Permit2 | Phase 1 / BC |

### Deploy order — 2a (core)

| # | Step |
|---|------|
| 2a.1 | Deploy vault facets (transient, swap, liquidity, buffer, poolToken, query, registration, admin, recovery) |
| 2a.2 | Deploy `BalancerV3VaultDFPkg` |
| 2a.3 | Deploy **TimelockAuthorizer** (`minDelay = 1 hours`, admin = deployer) |
| 2a.4 | Deploy Vault instance via package |
| 2a.5 | Deploy ProtocolFeeController; `setProtocolFeeController` |
| 2a.6 | Deploy router facets (swap, add/remove liq, init, common, batch, buffer, composite×2) |
| 2a.7 | Deploy `BalancerV3RouterDFPkg` + Router instance |
| 2a.8 | Shared pool facets as required by packages |
| 2a.9–11 | Weighted / Stable / ConstProd DFPkgs |
| 2a.12 | `ERC4626RateProviderFacetDFPkg` |

Hardcoded vault params (from Wave B): `MINIMUM_TRADE_AMOUNT`, `MINIMUM_WRAP_AMOUNT`, pause window 365d, buffer 90d.

### Deploy order — 2b (pool types)

| # | Step | Source |
|---|------|--------|
| 2b.1 | Gyro 2-CLP DFPkg | package tree + integration tests |
| 2b.2 | Gyro E-CLP DFPkg | |
| 2b.3 | LBP DFPkg | |
| 2b.4–5 | CowPool + CowRouter DFPkgs | |
| 2b.6 | ReClamm factory + pool impl | `ReClammPoolContractsDeployer` / tests |

### Must not

- Create agreement or `requestAttackMode` (factory already linked)  
- Use NullAuthorizer  
- Bind abandoned factory  

### FullStack

`Script_BC_FullStack`: run Phase 1 `_runDeploy` then Phase 2 `_runDeploy` in one broadcast; write both manifests.

### Post-steps

Manifest `battlechain-sepolia-balancer-v3.json` → docs → X Phase 2.

### Exit criteria

- [ ] Vault loupe OK; router `getVault()` = vault  
- [ ] All 2a+2b packages have code  
- [ ] Timelock minDelay = 1h  

---

## Phase 3a — Aave V3

### Goal
Usable Aave V3 market on BC using vendored procedures.

### Source
`contracts/protocols/lending/aave/v3.6/deployments/procedures/*`  
`IMarketReportTypes.sol` (`MarketReport`, `InitialReport`, `SetupReport`)

### Bind
BC WETH, USDC, DAI (min); BC Chainlink ETH/USD, USDC/USD, etc.

### Deploy order (fixed)

| # | Step | Procedure / action |
|---|------|-------------------|
| 3a.1 | Initial | `_initialDeployment` → PoolAddressesProvider, DefaultReserveInterestRateStrategyV2, ProviderRegistry |
| 3a.2 | Pool impls | `_deployAaveV3Pool` → PoolInstance + PoolConfigurator impl |
| 3a.3 | Treasury | `AaveV3TreasuryProcedure` |
| 3a.4 | Oracle | `AaveV3OracleProcedure` — sources = **BC Chainlink** |
| 3a.5 | Token impls | aToken + VariableDebtToken |
| 3a.6 | Rewards (if enabled) | EmissionManager + RewardsController |
| 3a.7 | Wire market | `_setupAaveV3Market` → ACLManager, proxies, set implementations |
| 3a.8 | Init reserves | WETH, USDC, DAI (hardcoded LTV/caps/IR from script constants) |
| 3a.9 | Optional periphery | ProtocolDataProvider, UI providers, WrappedTokenGateway |

Prefer CREATE3 under Phase 1 factory for each `new` where practical; otherwise document plain create under factory ownership.

### Hardcoded roles
All admins = deployer.

### Post / exit
Manifest aave section; supply/borrow smoke; docs + X (with 3b if same phase post).

---

## Phase 3b — Aave V4

**Authoritative detail:** [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md)

| # | Step | Summary |
|---|------|---------|
| 3b.A | CREATE2 gate | Safe Singleton `0x914d…` on BC **or** Path B (CreateX/CREATE3 adapter) — currently empty on BC |
| 3b.B | LiquidationLogic | Precompile + Crane-path `FOUNDRY_LIBRARIES` + recompile |
| 3b.C | Orchestration | `deployAaveV4` batch order (AccessManager → … → position managers) |
| 3b.D | Configure | Hub assets, addSpoke, reserves, BC oracles (min WETH+USDC) |
| 3b.E–F | Verify + docs + X | |

**Do not start 3b live until 3b.A resolved.**

---

## Phase 4 — Euler (bind only)

### Goal
Document BC mock Euler for integrators; no Crane redeploy.

### Bind

| Contract | Address |
|----------|---------|
| EVC | `0xB5D56dECA76e65cC9332Af01971bC8ad018a1Fc1` |
| eUSDC | `0x9a6fb480a74e6BAEE31EAbe297384ceA1EBb4d81` |
| eWETH | `0x38aF9d1C638C43d4340a700A854721dD5cdCf974` |

### Steps

| # | Step |
|---|------|
| 4.1 | Script requires `code.length > 0` on each bind |
| 4.2 | Write manifest + `BC_TESTNET` constants |
| 4.3 | Docs + X |

### Exit

- [ ] No CREATE3 of EVC/vaults  
- [ ] Addresses published  

---

## Phase 5 — Compound-style / Venus (bind only)

### Bind
Comptroller `0xAE582334…` + vUSDC, vWETH, vWBTC, vDAI, vBNB, vUSDT (full table in research §1.5).

### Steps

| # | Step |
|---|------|
| 5.1 | Require code on Comptroller + vTokens |
| 5.2 | Manifest + `BC_TESTNET` |
| 5.3 | Docs + X |

### Exit

- [ ] No Venus/Comet redeploy  

---

## Phase 6 — Aerodrome + Slipstream

### Goal
Full ve(3,3) + Slipstream CL factory path on BC.

### Source
`TestBase_Aerodrome.setUp` order; Slipstream fork parity for CLFactory.

### Bind
WETH; BC tokens for pools as needed.

### Deploy order — Aerodrome (fixed; match TestBase)

| # | Step |
|---|------|
| 6.1 | AERO token |
| 6.2 | Pool implementation |
| 6.3 | PoolFactory(impl) |
| 6.4 | VotingRewardsFactory |
| 6.5 | GaugeFactory |
| 6.6 | ManagedRewardsFactory |
| 6.7 | FactoryRegistry(poolFactory, votingRewards, gauge, managed) |
| 6.8 | Forwarder (GSN) |
| 6.9 | VotingEscrow(forwarder, AERO, factoryRegistry) |
| 6.10 | VeArtProxy + `setArtProxy` |
| 6.11 | RewardsDistributor(escrow) |
| 6.12 | Voter(forwarder, escrow, factoryRegistry) |
| 6.13 | `escrow.setVoterAndDistributor` |
| 6.14 | Router(forwarder, registry, poolFactory, voter, WETH) |
| 6.15 | Minter(voter, escrow, distributor); wire distributor + AERO.minter |
| 6.16 | AirdropDistributor(escrow) |
| 6.17 | `voter.initialize(gaugeTokens, minter)` — gauge token list hardcoded (e.g. empty or fixed set) |
| 6.18 | Role wiring: team, feeManager, emergencyCouncil, ownership transfers (hardcoded = deployer-controlled addrs) |
| 6.19 | ProtocolGovernor + EpochGovernor (if required by product; TestBase deploys pattern — include) |

### Deploy order — Slipstream

| # | Step |
|---|------|
| 6.20 | CLPool implementation |
| 6.21 | CLFactory(voter, …, poolImpl) |
| 6.22 | CustomSwapFeeModule / CustomUnstakedFeeModule if factory requires |
| 6.23 | CL gauge path if staking CL LPs is in scope |

All via CREATE3 under Phase 1 factory.

### Post / exit
Manifest; optional create volatile pool smoke; docs + X.

---

## Phase 7 — Uniswap extras

### Bind (never deploy V3)

BC Uni V3 Factory, SwapRouter, NPM.

### Already from Phase 1
Uni V2 factory/router, Uni V4 PoolManager, Permit2, WETH.

### Deploy order

| # | Step | Ctor notes |
|---|------|------------|
| 7.1 | PositionDescriptor | as ported |
| 7.2 | PositionManager | `(PoolManager, Permit2, unsubscribeGasLimit, descriptor, WETH)` — gas limit hardcoded |
| 7.3 | V4Router | PoolManager + … |
| 7.4 | StateView | PoolManager |
| 7.5 | V4Quoter | PoolManager |
| 7.6 | Manifest | Phase 1 Uni + 7.x + BC V3 binds |

### Exit
- [ ] V3 only bound  
- [ ] V4 periphery has code  

---

## Phase 8 — Camelot V2

### Source
`TestBase_CamelotV2`

### Deploy order

| # | Step |
|---|------|
| 8.1 | CamelotFactory(feeToSetter = deployer) |
| 8.2 | CamelotRouter(factory, WETH) |
| 8.3 | Manifest |

CREATE3 under Phase 1 factory.

### Exit
- [ ] createPair path viable  

---

## Phase 9 — Liquity / BOLD

### Source
`AddressesRegistry` fields; bold tree under `cdps/liquity/v2/bold/`

### Bind
BC WETH; BC Chainlink ETH/USD; Phase 1 factory. Uni V3 for zappers = BC (optional zappers off by default).

### Deploy order (one WETH collateral branch)

| # | Step |
|---|------|
| 9.1 | BoldToken |
| 9.2 | CollateralRegistry |
| 9.3 | AddressesRegistry(owner, CCR, MCR, BCR, SCR, liq penalties) — **constants hardcoded** from bold defaults / test suite |
| 9.4 | ActivePool, DefaultPool, GasPool, CollSurplusPool |
| 9.5 | StabilityPool |
| 9.6 | SortedTroves, TroveManager, TroveNFT, MetadataNFT |
| 9.7 | BorrowerOperations |
| 9.8 | PriceFeed → BC ETH/USD (adapter if needed) |
| 9.9 | HintHelpers, MultiTroveGetter, RedemptionHelper, InterestRouter as required by branch |
| 9.10 | `AddressesRegistry.setAddresses(AddressVars{…})` full wiring |
| 9.11 | Register collateral branch / open market as bold requires |
| 9.12 | Manifest |

### Exit
- [x] Open-trove path possible in principle (docs note any min debt) — hermetic `BC_Phase9_Liquity_Hermetic` openTrove PASS; `MIN_DEBT=2000e18`, `ETH_GAS_COMPENSATION=0.0375e18` WETH. **Not live.**

---

## Phase 10 — Sky / DSS

### Source
`SkyDssFactoryService.deployDss` + `TestBase_SkyDss`

### Deploy order

| # | Step |
|---|------|
| 10.1 | Call `SkyDssFactoryService.deployDss(chainId=627)` under CREATE3-friendly wrapper **or** create3 each piece in service order: Vat, Dai, DaiJoin, Jug, Pot, Spotter, Flapper, Flopper, Vow, Dog, End, Chainlog |
| 10.2 | `_wireSystem` + chainlog registration (as service does) |
| 10.3 | `setDefaultParameters` |
| 10.4 | Collateral: use BC WETH or mintable BC token as gem; pip = BC Chainlink or DSValue with fixed poke |
| 10.5 | `initIlk` for one ilk |
| 10.6 | Manifest |

### Exit
- [ ] openCdp-style path works in principle  

---

## Phase 11 — Resupply

**DROPPED.** No steps.

---

## Phase 12 — Reliquary

### Source
`TestBase_Reliquary`

### Bind
Reward + pool tokens: BC mocks or Phase 1 sample / LP.

### Deploy order

| # | Step |
|---|------|
| 12.1 | Reward ERC20 (or bind BC token) |
| 12.2 | Pool/deposit ERC20 (or bind) |
| 12.3 | Reliquary(reward, emission, name, symbol) — emission hardcoded |
| 12.4 | LinearCurve (+ LinearPlateau, Polynomial if exposing full set) |
| 12.5 | Fund Reliquary with rewards if needed |
| 12.6 | `addPool(allocPoint, poolToken, rewarder=0, curve, …)` |
| 12.7 | Manifest |

### Exit
- [ ] createRelicAndDeposit path viable  

---

## Phase 13a — Pendle

### Source
`PendlePoolDeployHelper`; factories under `perps/pendle/`

### Bind
BC tokens for seed liquidity.

### Deploy order

| # | Step |
|---|------|
| 13a.1 | Pendle Router (AllAction V3) |
| 13a.2 | PendleYieldContractFactory |
| 13a.3 | PendleMarketFactoryV3 |
| 13a.4 | PendlePoolDeployHelper(router, ycf, marketFactory) |
| 13a.5 | Deploy/choose one SY for BC asset (hardcoded SY type + underlying) |
| 13a.6 | `createYieldContract` → PT/YT |
| 13a.7 | `createNewMarket` with hardcoded `PoolDeploymentParams` |
| 13a.8 | Optional seed liquidity |
| 13a.9 | Oracle helpers if required |
| 13a.10 | Manifest |

### Exit
- [ ] Market + SY/PT/YT addresses in manifest  

---

## Phase 13b — Frax (minimal)

### Source
`TestBase_FraxBAMM`, Fraxswap TestBases

### Deploy order

| # | Step |
|---|------|
| 13b.1 | FraxswapFactory(owner = deployer) |
| 13b.2 | Create pair path (or deploy pair via factory for fixed token pair using BC tokens) |
| 13b.3 | BAMM contracts required by TestBase_FraxBAMM (enumerate exact list when implementing from that TestBase) |
| 13b.4 | Manifest |

### Exit
- [ ] Fraxswap factory + at least one pair address  

---

## Cross-phase implementation plan skeleton

Use this as the **implementation plan DAG** (depends-on):

```text
0 Prerequisites
 └── 1 Factories  (root)
      ├── 2 Balancer (+ optional FullStack = 1∥2 single script)
      ├── 3a Aave V3
      ├── 3b Aave V4  (needs CREATE2 gate / Path B)
      ├── 4 Euler bind
      ├── 5 Venus bind
      ├── 6 Aerodrome+Slipstream
      ├── 7 Uniswap extras
      ├── 8 Camelot
      ├── 9 Liquity
      ├── 10 Sky
      ├── 12 Reliquary
      ├── 13a Pendle
      └── 13b Frax
```

**Parallelizable after Phase 1:** all of 2–10, 12–13 (no mutual on-chain deps except shared factory).  
**Before any live:** all scripts + X drafts + commands file final.  
**Live order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 12 → 13a → 13b (or FullStack for 1+2).

Each implementation task for a phase:

1. Implement script per steps above  
2. Local/hermetic verify  
3. Update `BC_GREENFIELD_COMMANDS.md` if paths differ  
4. Tick master plan  
5. (Live later) command → docs → X  

---

## Document index

| Doc | Role |
|-----|------|
| **This file** | Per-phase deploy steps for implementation planning |
| [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md) | Deep dive Phase 3b |
| [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md) | Requirements / decisions |
| [`BC_GREENFIELD_MASTER_PLAN.md`](./BC_GREENFIELD_MASTER_PLAN.md) | Checkboxes |
| [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md) | Operator commands |
| [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md) | Pre-deploy X drafts |
| [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md) | BC binds + research notes |

---

## Change log

| Date | Change |
|------|--------|
| 2026-07-23 | Initial all-phase deploy steps for implementation planning |
