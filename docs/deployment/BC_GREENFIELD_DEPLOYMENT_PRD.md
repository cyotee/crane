---
project: BattleChain greenfield deployment
version: 1.0
status: active
created: 2026-07-23
last_updated: 2026-07-23
owner: TBD
test_crosscheck: 2026-07-23
related:
  - docs/deployment/BC_GREENFIELD_INVENTORY.md
  - docs/deployment/BC_GREENFIELD_MASTER_PLAN.md
  - docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_SCRIPTS_PRD.md
  - docs/superpowers/plans/2026-07-23-create3-package-idempotency-and-bc-redeploy.md
  - docs/deployment/battlechain.md
---

# PRD: BattleChain greenfield deployment

## 1. Purpose

Deploy the **entire Crane greenfield stack** on BattleChain testnet (chain ID `627`) under a **new Create3Factory root**, phase by phase, with Foundry scripts, address manifests, and docs handoff.

This PRD is the **authoritative definition of what must be deployed**.  
The master plan is the **checklist** used to track plan → implement → verify → live work.

## 2. Non-negotiable policy

1. **Scope = inventory phases 1–10 and 12–13.** Phase **11 Resupply is dropped** (not ported). There is no further optional subset.
2. **Plan and implement scripts for every phase before any live BattleChain broadcast.** No greenfield phase is broadcast until:
   - factory idempotency is done,
   - the shared script platform is done,
   - **every phase’s deployment script is planned and implemented**,
   - local verification for those scripts is complete,
   - **X announcement drafts for every phase are written and reviewed** (see [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md)),
   - **operator command list is frozen** (see [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md)).
3. **New Create3Factory root only.** No `diamondCut` of the abandoned factory. Old Wave A/B Crane addresses are abandoned.
4. **Bind, never redeploy** anything BattleChain already provides (full list §5 and [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md)). That includes BC mock **Euler**, **Venus**, **Morpho**, **Uni V3**, tokens, Chainlink, Safe, etc.
5. **One Safe Harbor agreement per generation**, created in Phase 1 only, scoped to Create3Factory with `ChildContractScope.All`. Later phases do not create agreements and do not re-request attack mode for the same factory root.
6. Where BC already provides the protocol role, **bind** — do not re-port for the sake of deploying. Protocols not ported (e.g. former Phase 11 Resupply) are **out of scope**, not open-ended port work in this program.

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Greenfield Create3Factory + full Phase 1 factory/token/DEX stubs + Permit2 + Safe Harbor + attack mode. |
| G2 | Full Balancer V3 surface (vault, TimelockAuthorizer, routers, all listed pool types). |
| G3 | Phases 3–10 and 12–13 complete as specified in §6 (Crane CREATE3 deploy **or** BC bind-only where BC provides the protocol). Phase 11 out of scope. |
| G4 | One Foundry script (or tightly scoped script family) per phase, plus FullStack for Phase 1→2. |
| G5 | Manifest JSON + table per phase; `BC_TESTNET` + Deployed Addresses updated after live deploy. |
| G6 | Idempotent CREATE3 (including `*WithArgs`) so broadcasts are resume-safe. |
| G7 | Zero live BC deploys until §2 policy item 2 is satisfied. |
| G8 | Operator runs **fixed** forge commands only — no env knobs, no interactive options. |
| G9 | After each phase: agent updates docs-site addresses; operator posts the pre-drafted X announcement. |

## 3.1 Operator workflow (locked)

| Who | Does |
|-----|------|
| **Scripts** | Encode **all** deploy parameters (salts, Timelock delay, markets, binds). **No** CLI/env configuration at run time for product choices. |
| **Human operator** | Runs the **one command per phase** from [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md) (plus shared `DEPLOYER` export). |
| **Agent (post-phase)** | Updates docs site: phase JSON/table, `deployed-addresses.md`, `BC_TESTNET.sol` as needed. |
| **Human or agent** | Posts the matching draft from [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md) — **docs links only, no hex addresses**. |

Resume after partial failure: re-run the **same** command (idempotent CREATE3). Optional `-g` increase only for OOG — not a product option.

## 4. Non-goals

| Non-goal | Notes |
|----------|--------|
| IndexedEx product (DETF, CCA, RICH) | Separate program |
| NullAuthorizer as Balancer auth | Phase 2 uses TimelockAuthorizer only |
| Mainnet / Base promote | Same salts later; out of this PRD |
| diamondCut of gen-1 factory | Forbidden |
| Redeploying BC-provided WETH / Uni V3 / mocks / SafeHarbor stack | Bind only |
| Migrating state from abandoned addresses | Greenfield only |
| **Resupply (Phase 11)** | Not ported; dropped until a future port |

## 5. Always bind (never deploy)

Authoritative address tables: [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md) §1 and [BC mock-contracts docs](https://docs.battlechain.com/battlechain/reference/mock-contracts).

| Surface | Action |
|---------|--------|
| SafeHarborRegistry, AgreementFactory, AttackRegistry, BattleChainDeployer, CreateX | Bind BC core |
| WETH, USDC, USDT, DAI, WBTC, LINK, MTK | Bind BC test tokens |
| Chainlink mock feeds (ETH/USD, BTC/USD, LINK/USD, USDC/USD) | Bind |
| Uniswap V3 Factory, SwapRouter, NPM | Bind — **never** redeploy V3 |
| **Euler V2 mock** (EVC, eUSDC, eWETH) | Bind — **Phase 4 default** |
| **Venus mock** (Comptroller + vTokens) | Bind — **Phase 5 default** (Compound-style) |
| **Morpho Blue mock** | Bind if needed (not a numbered phase) |
| KyberSwap mock router, CCIP mock router | Bind if needed |
| Safe (Gnosis) stack | Bind |

Abandoned Create3Factory (hard-revert if used as live factory):

`0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A`

## 6. What must be deployed (by phase)

Every phase below is **required**. Each has:

- **Deploy** — Crane-owned contracts the phase script must place on BC under Phase 1’s Create3Factory (unless noted).
- **Bind** — addresses the script consumes but does not deploy.
- **Script** — required deliverable name.
- **Manifest** — address book artifact.
- **Done when** — acceptance for implementation (local); live is later.

CREATE3 salts: **reuse existing salt strings** from Launch / Wave B / protocol conventions. New factory address namespaces addresses.

---

### Phase 0 — Prerequisites (not a BC phase; blocks all scripts)

| Work | Deliverable |
|------|-------------|
| Idempotent `create3WithArgs` / package / facet-with-args | Factory service (+ factory path if needed) returns existing code when predicted address has code |
| Tests | Double deploy same salt → same address, no revert |
| Shared script base | `scripts/foundry/bc/BCPhaseScriptBase.s.sol` (or equivalent): sender guard, bind helpers, abandoned-factory revert, manifest write, docs handoff log |

**Bind sources (all phase scripts) — amended 2026-07-25 (G-3):**

1. **Explicit FullStack / `deployForFullStack` handoff** (preferred for multi-phase local tests and in-session composition).  
2. **`BC_TESTNET` greenfield constants** after Phase 1 live fills zeros (never the abandoned gen-1 factory).  

**Not used:** env-based product or factory config (conflicts with fixed-script / no-env-product-knobs policy). Optional future: read prior-phase manifest JSON for operator resume only — not required for greenfield DoD.

---

### Phase 1 — Crane factory system

**Script:** `Script_BC_Phase1_Factories.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia.json` (+ `.table.md`)  
**Baseline:** `Script_Promo_BC_Launch.s.sol`

| # | Deploy | How |
|---|--------|-----|
| 1.1 | Create3Factory | `InitBcService.initEnvBc` via BattleChainDeployer lineage |
| 1.2 | DiamondPackageCallBackFactory | Same init; wired to Create3Factory |
| 1.3 | ERC20Facet | `deployFacet` |
| 1.4 | ERC5267Facet | `deployFacet` |
| 1.5 | ERC2612Facet | `deployFacet` |
| 1.6 | ERC20PermitDFPkg | `deployPackageWithArgs` |
| 1.7 | Sample ERC20Permit diamond (CBCP-style) | Diamond factory `deploy` — **required** |
| 1.8 | Uni V2 Factory | CREATE3 stub |
| 1.9 | Uni V2 Router02 | CREATE3; constructor factory + WETH |
| 1.10 | Uni V4 PoolManager | CREATE3 |
| 1.11 | BetterPermit2 | CREATE3 |
| 1.12 | Safe Harbor agreement | Scope: Create3Factory only; `ChildContractScope.All`; new salt |
| 1.13 | `requestAttackMode` | On the Phase 1 agreement only |

**Bind:** WETH, Uni V3 Factory / SwapRouter / NPM, BC SafeHarbor stack.

**Done when (implementation):** script compiles; `_runDeploy` path exists; deploys 1.1–1.13 in order; writes manifest; re-run is resume-safe after Phase 0.

**X (after live):** Crane factories + core stubs live on BattleChain.

---

### Phase 2 — Balancer V3

**Scripts:**

- `Script_BC_Phase2_BalancerV3.s.sol` — full Phase 2 (2a + 2b in one script, or 2a body + 2b sections/flags)
- Optional split: `Script_BC_Phase2b_BalancerPools.s.sol` if size requires it  
- `Script_BC_FullStack.s.sol` — Phase 1 then Phase 2 in **one** forge broadcast  

**Manifest:** `docs/deployment/addresses/battlechain-sepolia-balancer-v3.json` (+ table)  
**Baseline:** `Script_Promo_BC_BalancerV3.s.sol`  
**Auth:** TimelockAuthorizer only — **minDelay = 1 hour**, **admin = deployer**. No NullAuthorizer.  
**Agreement:** none (Phase 1 covers factory children).

#### 2a — Core (required subset, implement first inside Phase 2)

| # | Deploy |
|---|--------|
| 2a.1 | Vault facets (transient, swap, liquidity, buffer, pool token, query, registration, admin, recovery) |
| 2a.2 | BalancerV3VaultDFPkg |
| 2a.3 | TimelockAuthorizer |
| 2a.4 | Vault instance (via package) |
| 2a.5 | ProtocolFeeController + set on vault |
| 2a.6 | Router facets (swap, add/remove liquidity, initialize, common, batch, buffer, composite ERC4626, composite nested) — match current Wave B surface |
| 2a.7 | BalancerV3RouterDFPkg + Router instance (`getVault()` = vault) |
| 2a.8 | Shared pool facets needed by packages (vault-aware, pool token, auth, pool info, weighted/stable/constProd facets as required) |
| 2a.9 | BalancerV3WeightedPoolDFPkg |
| 2a.10 | BalancerV3StablePoolDFPkg |
| 2a.11 | BalancerV3ConstantProductPoolDFPkg |
| 2a.12 | ERC4626RateProviderFacetDFPkg (+ shared facets it needs) — used by vault TestBase rate-provider path |

#### 2b — Remaining pool types (required; same generation, scripts complete before any live deploy)

| # | Deploy |
|---|--------|
| 2b.1 | BalancerV3Gyro2CLPPoolDFPkg |
| 2b.2 | BalancerV3GyroECLPPoolDFPkg |
| 2b.3 | BalancerV3LBPoolDFPkg (+ LBP facet/target as required by package) |
| 2b.4 | CowPoolDFPkg |
| 2b.5 | CowRouterDFPkg |
| 2b.6 | ReClammPoolFactory + ReClamm pool implementation (see `ReClammPoolContractsDeployer` / `BaseReClammTest`) |

**Bind:** Phase 1 Create3Factory, DiamondPackageCallBackFactory, WETH, BetterPermit2.

**Done when (implementation):** full 2a+2b deploy path in scripts; TimelockAuthorizer wired; manifests include all addresses; FullStack chains 1→2; no agreement creation.

**X (after live):** Balancer V3 (vault, routers, TimelockAuthorizer, all pool types) ready on BattleChain.

---

### Phase 3 — Aave

**Script:** `Script_BC_Phase3_Aave.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-aave.json`  
**Research:** [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md) §2.1  
**BC does not provide Aave** — full Crane deploy via vendored procedures.

#### 3a — Aave V3 (required)

Follow `AaveV3*Procedure` order under CREATE3 / Phase 1 factory:

| # | Deploy (from procedures + `MarketReport`) |
|---|-------------------------------------------|
| 3a.1 | PoolAddressesProvider + DefaultReserveInterestRateStrategyV2 + ProviderRegistry (`_initialDeployment`) |
| 3a.2 | Pool implementation (`PoolInstance`) + PoolConfigurator implementation |
| 3a.3 | Treasury / collector |
| 3a.4 | AaveOracle (**assets → BC Chainlink mocks**) |
| 3a.5 | aToken + VariableDebtToken implementations |
| 3a.6 | RewardsController + EmissionManager if incentives enabled |
| 3a.7 | ACLManager + pool/configurator proxies (`_setupAaveV3Market`) |
| 3a.8 | `initReserves` for ≥ WETH, USDC, DAI (BC tokens) |
| 3a.9 | Optional: ProtocolDataProvider, UI providers, WrappedTokenGateway |

#### 3b — Aave V4 Hub/Spoke

**Code status:** Fully vendored. Provenance: `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md`.

**Complete step list (authoritative):** [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md)

Summary:

| Step | Action |
|------|--------|
| A | Ensure Safe Singleton CREATE2 factory `0x914d…` on BC **or** Path B (CreateX/Crane CREATE3 adapter) — **as of 2026-07-23 factory is empty on BC testnet** |
| B | Deploy `LiquidationLogic` + set `FOUNDRY_LIBRARIES` (Crane path) + recompile Spoke |
| C | `AaveV4DeployOrchestration.deployAaveV4` with hardcoded `FullDeployInputs` (see steps doc defaults) |
| D | Configure: hub `addAsset`, `addSpoke`, spoke reserves + **BC Chainlink** sources (min WETH+USDC) |
| E | Verify + manifest |
| F | Docs + X |

**Bind:** BC WETH / tokens / Chainlink. Never redeploy.

**Done when:** Steps A–F complete per `BC_AAVE_V4_DEPLOY_STEPS.md`; usable supply path on BC.

**X:** Aave on BattleChain.

---

### Phase 4 — Euler (**bind BC mock; do not redeploy**)

**Script:** `Script_BC_Phase4_Euler.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-euler.json`  
**Research:** §2.2  

BattleChain **already provides** mock Euler V2:

| Bind | Address |
|------|---------|
| EVC | `0xB5D56dECA76e65cC9332Af01971bC8ad018a1Fc1` |
| eUSDC | `0x9a6fb480a74e6BAEE31EAbe297384ceA1EBb4d81` |
| eWETH | `0x38aF9d1C638C43d4340a700A854721dD5cdCf974` |

| # | Action |
|---|--------|
| 4.1 | **Bind** EVC + vaults; write manifest (no CREATE3 of EVC/vaults) |
| 4.2 | Optional only: Crane EVK factory / perspectives for *additional* vaults — only if product requires beyond BC mocks |

**Done when:** manifest + `BC_TESTNET` list BC Euler addresses; script does not deploy replacements.

**X:** Euler on BattleChain (BC-provided mocks + Crane docs).

---

### Phase 5 — Compound-style lending (**bind BC Venus; default not Comet**)

**Script:** `Script_BC_Phase5_Compound.s.sol` (name may stay Comet only if product overrides to true Comet)  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-compound.json`  
**Research:** §2.3  

BC provides **Venus** (Compound V2-style Comptroller + vTokens), **not** Comet.

| # | Action |
|---|--------|
| 5.1 | **Bind** Comptroller `0xAE582334…` + vUSDC/vWETH/vWBTC/vDAI/vBNB/vUSDT |
| 5.2 | Write manifest + docs |
| 5.3 | **Do not** port/deploy Comet unless product explicitly requires Comet bytecode (override) |

**Done when:** addresses committed; no Venus redeploy.

**X:** Compound-style lending (Venus mock) on BattleChain.

---

### Phase 6 — Aerodrome + Slipstream

**Script:** `Script_BC_Phase6_Aerodrome.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-aerodrome.json`

| # | Deploy | Evidence |
|---|--------|----------|
| 6.1 | AERO (`Aero`) | `TestBase_Aerodrome` |
| 6.2 | Pool implementation (`Pool`) | same — factory needs impl |
| 6.3 | PoolFactory | same |
| 6.4 | VotingRewardsFactory | same |
| 6.5 | GaugeFactory | same |
| 6.6 | ManagedRewardsFactory | same |
| 6.7 | FactoryRegistry | same |
| 6.8 | Forwarder (GSN) | same — VE + Voter + Router ctor |
| 6.9 | VotingEscrow | same |
| 6.10 | VeArtProxy + `setArtProxy` | same |
| 6.11 | RewardsDistributor | same |
| 6.12 | Voter + `initialize` + minter/gauge token wiring | same |
| 6.13 | Router | same |
| 6.14 | Minter + wire distributor/AERO | same |
| 6.15 | AirdropDistributor | same |
| 6.16 | ProtocolGovernor | deployed in fuller aero setups; include for protocol completeness |
| 6.17 | EpochGovernor | same |
| 6.18 | Post-deploy role wiring (team, feeManager, emergencyCouncil, factory registry ownership) as in TestBase | same |
| 6.19 | Slipstream `CLPool` implementation | `SlipstreamForkParity.t.sol` local factory path |
| 6.20 | Slipstream `CLFactory` (voter + pool impl) | same |
| 6.21 | Slipstream fee modules (CustomSwapFeeModule, CustomUnstakedFeeModule) if factory requires | port tree |
| 6.22 | Slipstream gauge path when required for staking emissions on CL pools | **WAIVED (2026-07-26):** no `CLGauge` in Crane slipstream port — product non-goal until gauge contracts are ported; greenfield deploys CLPool+CLFactory+fee modules only |

**Source:** `TestBase_Aerodrome.sol`, `…/slipstream/`, fork parity tests; `BcAerodromePhase6Deploy.sol`.

**Bind:** WETH, Phase 1 factory.

**Done when:** script deploys volatile/stable pool path + Slipstream factory path + governors + fee modules; manifest complete. CL gauge deferred (6.22 waived).

**X:** Aerodrome + Slipstream on BattleChain.

---

### Phase 7 — Uniswap (beyond Phase 1 stubs)

**Script:** `Script_BC_Phase7_Uniswap.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-uniswap.json`  
**Research:** §2.5  

| # | Action |
|---|--------|
| 7.0 | **Bind** BC Uni V3 Factory / SwapRouter / NPM — never deploy V3 |
| 7.1 | **Deploy** PositionDescriptor |
| 7.2 | **Deploy** PositionManager (ctor: PoolManager, Permit2, unsubscribeGasLimit, descriptor, WETH) |
| 7.3 | **Deploy** concrete V4Router (`BcV4Router` — abstract `V4Router` is not deployable alone) |
| 7.4 | **Deploy** StateView + V4Quoter |
| 7.5 | Manifest includes Phase 1 Uni V2 + V4 PoolManager + 7.1–7.4 + BC V3 binds |

**Bind:** Phase 1 PoolManager, Permit2, WETH; BC Uni V3.

**Done when:** V4 periphery + concrete router scripted; V3 only bound.

**X:** Uniswap ports complete on BattleChain.

---

### Phase 8 — Camelot V2

**Script:** `Script_BC_Phase8_Camelot.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-camelot.json`

| # | Deploy |
|---|--------|
| 8.1 | CamelotFactory |
| 8.2 | CamelotRouter (WETH-aware) |
| 8.3 | Pair init code / libraries as required for factory |

**Source:** `contracts/protocols/dexes/camelot/v2/stubs/`.

**Bind:** WETH, Phase 1 factory.

**Done when:** factory + router under CREATE3; create-pair path viable.

**X:** Camelot on BattleChain.

---

### Phase 9 — Liquity / BOLD

**Script:** `Script_BC_Phase9_Liquity.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-liquity.json`  
**Research:** §2.7 — graph from `AddressesRegistry` fields.

| # | Deploy |
|---|--------|
| 9.1 | BoldToken |
| 9.2 | CollateralRegistry + AddressesRegistry (CCR/MCR/BCR/SCR/penalties) |
| 9.3 | ActivePool, DefaultPool, GasPool, CollSurplusPool |
| 9.4 | StabilityPool |
| 9.5 | SortedTroves, TroveManager, TroveNFT, MetadataNFT |
| 9.6 | BorrowerOperations |
| 9.7 | PriceFeed wired to **BC Chainlink ETH/USD** (WETH branch) |
| 9.8 | HintHelpers, MultiTroveGetter, RedemptionHelper, InterestRouter as required |
| 9.9 | `AddressesRegistry.setAddresses` full wiring |
| 9.10 | Zappers optional; if used, **bind** BC Uni V3 (do not redeploy V3) |

**Bind:** BC WETH, BC Chainlink, Phase 1 factory.

**Done when:** one WETH collateral branch fully wired; open-trove path viable.

**X:** Liquity on BattleChain.

---

### Phase 10 — Sky / Maker-related

**Script:** `Script_BC_Phase10_Sky.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-sky.json`

| # | Deploy | Evidence |
|---|--------|----------|
| 10.1 | Vat | `SkyDssFactoryService.deployDss` / `TestBase_SkyDss` |
| 10.2 | Dai | same |
| 10.3 | DaiJoin | same |
| 10.4 | Jug | same |
| 10.5 | Pot | same |
| 10.6 | Spotter | same |
| 10.7 | Flapper | same — **required** (not optional) |
| 10.8 | Flopper | same — **required** |
| 10.9 | Vow | same |
| 10.10 | Dog | same |
| 10.11 | End | same |
| 10.12 | Chainlog (MockChainlog on BC or production chainlog if ported) | same |
| 10.13 | Default parameters (`setDefaultParameters`) | same |
| 10.14 | At least one ilk: GemJoin + price feed (DSValue or BC oracle) + `initIlk` | same |
| 10.15 | Script must call same wiring as `_wireSystem` / chainlog registration | same |

**Source:** `SkyDssFactoryService.sol`, `TestBase_SkyDss.sol`, `BcSkyPhase10Deploy.sol`.

**Lineage (locked 2026-07-26):** DSS uses Maker-style plain `new` inside the factory service — **not** CREATE3-wrapped under Phase 1 Create3Factory (**multi-root Safe Harbor**). Do not invent a divergent CREATE3 graph for Sky. Pip seed is Maker-style DSValue (`peek`); raw Chainlink aggregators are not pip ABI.

**Bind:** BC tokens/oracles, Phase 1 factory (optional bind only).

**Done when:** DSS core + one collateral join path scripted; manifest lists core modules including flapper/flopper/pot/chainlog.

**X:** Sky on BattleChain.

---

### Phase 11 — Resupply — **DROPPED**

Not ported into Crane. **Out of scope** for this greenfield program. No script, no X post, no live step.

Re-open only after a Resupply port lands.

---

### Phase 12 — Reliquary

**Script:** `Script_BC_Phase12_Reliquary.s.sol`  
**Manifest:** `docs/deployment/addresses/battlechain-sepolia-reliquary.json`

| # | Deploy | Evidence |
|---|--------|----------|
| 12.1 | Reliquary core (`Reliquary` — reward token, emission, name/symbol) | `TestBase_Reliquary` |
| 12.2 | LinearCurve (at least one curve used by default pool) | same |
| 12.3 | LinearPlateauCurve and/or PolynomialPlateauCurve if exposing full curve set | same (TestBase deploys all three) |
| 12.4 | Reward token + pool/deposit token (BC mocks or prior-phase LP) | same uses mocks |
| 12.5 | `addPool` with allocPoint, pool token, curve, rewarder (may be `address(0)`) | same |
| 12.6 | Optional: rolling rewarder / NFT descriptor if used beyond TestBase minimum | port tree |

**Source:** `TestBase_Reliquary.sol`.

**Bind:** Phase 1 factory; reward + deposit tokens (BC mocks or prior-phase LPs).

**Done when:** Reliquary + one pool scripted; create-relic path viable.

**X:** Reliquary on BattleChain.

---

### Phase 13 — Pendle / Frax / other vendored

**Scripts (required family; one script per slice):**

| Script | Manifest |
|--------|----------|
| `Script_BC_Phase13a_Pendle.s.sol` | `battlechain-sepolia-pendle.json` |
| `Script_BC_Phase13b_Frax.s.sol` | `battlechain-sepolia-frax.json` |

Additional slices only if product adds them; name `Script_BC_Phase13c_<Name>.s.sol`.

#### 13a — Pendle (required)

**Research:** §2.11 — `PendlePoolDeployHelper` + factories.

| # | Deploy |
|---|--------|
| 13a.1 | Pendle Router (AllAction V3) |
| 13a.2 | PendleYieldContractFactory |
| 13a.3 | PendleMarketFactoryV3 |
| 13a.4 | PendlePoolDeployHelper (or inline equivalent) |
| 13a.5 | One SY for a BC-available asset |
| 13a.6 | createYieldContract → createNewMarket (+ optional seed liquidity) |
| 13a.7 | Oracle helpers if required for that market |

**Bind:** BC tokens for seed.

#### 13b — Frax (required)

Hermetic tests today cover **Fraxswap** and **BAMM** setup, not the entire Frax monorepo.

| # | Deploy | Evidence |
|---|--------|----------|
| 13b.1 | FraxswapFactory | `TestBase_FraxBAMM` |
| 13b.2 | Fraxswap pair creation path (pair bytecode via factory) | same |
| 13b.3 | BAMM-related contracts exercised by `TestBase_FraxBAMM` / BAMM specs (enumerate in Phase 13b plan from those tests) | BAMM TestBase + specs |
| 13b.4 | Fraxswap TWAMM / Range pieces only if corresponding TestBases are in the ship path (`TestBase_FraxswapTWAMM`, `TestBase_FraxswapRange`) | those TestBases |
| 13b.5 | Any additional Frax core (frxUSD, etc.) **only if** added to the Phase 13b plan with a TestBase or explicit product requirement | TBD in plan |

Phase 13b plan must list the **exact** contract list; minimum bar = everything needed to reproduce `TestBase_FraxBAMM` deploy graph on BC under CREATE3.

**Done when:** 13a and 13b scripts + manifests exist and deploy their listed surfaces.

**X:** Per slice when that slice ships (after live).

---

## 7. Script platform requirements

All phase scripts must:

1. Live under `scripts/foundry/bc/` with names in §6 (canonical). `Script_Promo_*` is not canonical.
2. Extend `BCScript` + shared `BCPhaseScriptBase`.
3. Use Phase 1 factory for CREATE3 / packages (Phase 1 creates the factory).
4. Revert if broadcaster is Foundry default `0x1804…`.
5. Revert if factory bind equals abandoned gen-1 address.
6. On chain 627, require `code.length > 0` for every bound address before depending on it.
7. Write docs JSON + table + runtime JSON; log docs handoff.
8. Support internal `_runDeploy` for tests without broadcast/attack mode.
9. Phase 2+: **no** new Safe Harbor agreement; **no** attack-mode re-link of Create3Factory.
10. Phase 1 only: create agreement + `requestAttackMode`.

**FullStack:** one Solidity script, one forge broadcast: Phase 1 then Phase 2 (full). Standalone Phase 1 and Phase 2 scripts remain required for resume.

**Broadcast CLI (live, only after §2 gate):**

```bash
export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/bc/<Script>.s.sol:<Contract> \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400
```

## 8. Per-phase ops (after live is allowed)

1. Operator runs **exactly one** command from [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md)  
2. Script writes address manifest (JSON + table)  
3. **Agent** refreshes docs site: manifests, `deployed-addresses.md`, `BC_TESTNET.sol`  
4. **Post** the pre-drafted X text from [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md) (docs links only)

## 9. Decisions (locked)

| ID | Decision |
|----|----------|
| D1 | Script names `Script_BC_PhaseN_*` |
| D2 | TimelockAuthorizer admin = deployer |
| D3 | FullStack script required |
| D4 | Overwrite `battlechain-sepolia.json` as Phase 1 SoT |
| D5 | Implement 2a then 2b inside Phase 2; both complete before any live deploy |
| D6 | One agreement per generation (Phase 1 only) |
| D7 | Timelock minDelay = 1 hour |
| D8 | Reuse existing CREATE3 salt strings |
| D9 | Phase 1 includes sample ERC20Permit token |
| D10 | FullStack = one Solidity script / one broadcast |
| D11 | Phase 2a router surface = current Wave B facet set |
| D12 | Hard revert on abandoned gen-1 factory |
| D13 | **Phases 1–10 and 12–13 required; Phase 11 Resupply dropped** |
| D14 | **No live BC broadcast until Phase 0 + all phase scripts are planned and implemented and locally verified** |
| D15 | **Never deploy BC-provided protocols/deps** — bind Euler, Venus, Morpho, Uni V3, tokens, Chainlink, Safe, etc. |
| D16 | **Phase 4 = bind BC Euler mocks** (not redeploy EVC/vaults) |
| D17 | **Phase 5 = bind BC Venus** as Compound-style surface (Comet port only if product overrides) |
| D18 | **Scripts fix all options** — operator never chooses params at run time |
| D19 | **Pre-deploy gate includes X drafts for all phases** + command list |
| D20 | **Post-phase:** agent updates docs addresses; X post from pre-written draft |
| D21 | **Resupply dropped** until ported |

## 10. Definition of done (program)

The program is ready for **first live greenfield broadcast** when:

- [ ] Phase 0 complete  
- [ ] Scripts exist for Phases 1–10, 12–13 (including 13a/13b and FullStack); **no** Phase 11  
- [ ] Each script’s §6 list is implemented (bind scripts for 4/5; Crane deploys elsewhere)  
- [ ] Local verification done per master plan checklist  
- [ ] Runbooks exist for each phase  
- [ ] Security contact set if public attack-mode announcement is intended  

Then live order: Phase 1 → 2 → 3 → … → 13 (or FullStack for 1+2 then 3…), with manifests and docs after each phase.

## 11. Test cross-check (2026-07-23)

**Honest answer:** the first draft of §6 was **not** written by walking every TestBase. A pass was done afterward against hermetic TestBases, DFPkg integration tests, factory services, and the existing BC promo scripts. Results:

### 11.1 Where tests **do** define a deploy graph (used to refine §6)

| Phase | Primary evidence | Notes |
|-------|------------------|--------|
| 1 | `Script_Promo_BC_Launch`, ERC20Permit integration | Solid |
| 2 | Wave B script; `*_DFPkg_Integration.t.sol` (Weighted/Stable/ConstProd/Gyro/CoW); Router-Vault integration; ReClamm `BaseReClammTest` / `ReClammPoolContractsDeployer`; LBP target/facet tests | Vault hermetic TestBase uses **mocks** (not Timelock/production vault diamond). Production path = DFPkg + Wave B script, not `TestBase_BalancerV3Vault` mock stack. **Added** ERC4626RateProvider DFPkg (2a.12). |
| 6 | `TestBase_Aerodrome` full setUp | Expanded 6.1–6.18 to match TestBase (Pool impl, Forwarder, Airdrop, governors, wiring). Slipstream hermetic base is **mock CLPool**; real factory path from fork parity. |
| 8 | `TestBase_CamelotV2` | Factory + Router only — PRD matches |
| 10 | `SkyDssFactoryService` + `TestBase_SkyDss` | Flapper/Flopper **required**; PRD aligned to full `DssDeployment` |
| 12 | `TestBase_Reliquary` | Curves are first-class deploys; rewarder may be zero |
| 13b | `TestBase_FraxBAMM`, Fraxswap TestBases | Minimal surface = Fraxswap (+ BAMM path), not entire frax tree |

### 11.2 Where tests **do not** give a greenfield deploy recipe

| Phase | What exists | Implication for §6 |
|-------|-------------|-------------------|
| 3 Aave | `ProtocolV3TestBase` = config snapshots against **existing** pools; `deployments/procedures/*` = upstream-style procedures | §6.3a still derived from procedures/instances, **not** a single Crane TestBase that deploys a full market. Phase 3 plan must walk `AaveV3*Procedure.sol` and pin exact addresses/steps. |
| 4 Euler | BC provides mock Euler | **Resolved:** bind-only (research §2.2) |
| 5 Compound | BC provides Venus (not Comet) | **Resolved:** bind Venus (research §2.3) |
| 7 Uniswap extras | Fork TestBases bind mainnet V4 PM | **Resolved:** deploy V4 periphery; bind BC V3 (research §2.5) |
| 9 Liquity | Bold `AddressesRegistry` | **Resolved:** branch deploy graph (research §2.7) |
| 11 Resupply | Not ported | **Dropped (D21)** |
| 13a Pendle | `PendlePoolDeployHelper` + factories | **Resolved:** factory + one market (research §2.11) |
| 3b Aave V4 | Full vendored tree + orchestration + deploy tests | **Code present** — wrap in BC script (LiquidationLogic pre-link + FullDeployInputs) |

### 11.3 Rule for implementers

When implementing a phase script:

1. Start from §6 list in this PRD.  
2. Diff against the **primary evidence** TestBase/script in §11.1 (or procedures for Aave).  
3. If the TestBase deploys something §6 omits, **add it to §6** in the same PR.  
4. Prefer production DFPkg/factory paths over test mocks (especially Balancer: no NullAuthorizer/BasicAuthorizerMock on BC).

### 11.4 Follow-up work

- [ ] Phase 3a: Aave V3 procedures on BC  
- [ ] Phase 3b: Aave V4 orchestration BC script (LiquidationLogic two-step + hardcoded inputs)  
- [ ] Expand `BC_TESTNET.sol` with Euler, Venus, Morpho, Safe constants

## 12. Document roles

| Doc | Role |
|-----|------|
| **This PRD** | What must be deployed; policy; script names; locked decisions |
| [`BC_GREENFIELD_PHASE_DEPLOY_STEPS.md`](./BC_GREENFIELD_PHASE_DEPLOY_STEPS.md) | **Ordered deploy steps for every phase** (implementation plan input) |
| [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md) | Aave V4 deep dive |
| [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md) | BC bind inventory + research notes |
| [`BC_GREENFIELD_MASTER_PLAN.md`](./BC_GREENFIELD_MASTER_PLAN.md) | Checklist to tick plan/implement/verify/live |
| [`BC_GREENFIELD_INVENTORY.md`](./BC_GREENFIELD_INVENTORY.md) | Short phase list + X lines |
| [`BC_GREENFIELD_DEPLOYMENT_SCRIPTS_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_SCRIPTS_PRD.md) | Historical scripts PRD; defer to this doc for scope |
| Create3 greenfield plan | Factory idempotency technical plan |

## 13. Change log

| Date | Change |
|------|--------|
| 2026-07-23 | v1.0 — Full deployment PRD: all phases required; what-to-deploy tables; no live deploy until all scripts implemented |
| 2026-07-23 | v1.1 — Test cross-check §11; expand Aero/Sky/Reliquary/Frax/Balancer rate provider from TestBases; flag phases without deploy TestBases |
| 2026-07-23 | v1.2 — Deploy research: BC mock inventory; Phase 4/5 bind defaults; Aave procedures; Uni V4 periphery; BOLD/Pendle graphs; D15–D17 |
| 2026-07-23 | v1.3 — Operator workflow: fixed scripts, commands file, X drafts in pre-deploy gate, post-phase docs+X (D18–D20) |
| 2026-07-23 | v1.4 — Drop Phase 11 Resupply; Aave V4 code present + orchestration deploy path documented (D21) |
| 2026-07-23 | v1.5 — Full Aave V4 BC steps in BC_AAVE_V4_DEPLOY_STEPS.md (CREATE2 gate, library, orchestration, config) |
| 2026-07-23 | v1.6 — All-phase deploy steps: BC_GREENFIELD_PHASE_DEPLOY_STEPS.md |
| 2026-07-26 | v1.7 — Tier C local depth: Phase 6.22 CL gauge waived (not in port); Phase 7.3 concrete BcV4Router; Phase 10 multi-root Safe Harbor (plain new DSS, not CREATE3-wrap) |
