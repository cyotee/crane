---
project: BattleChain greenfield — deploy research
version: 1.0
status: active
created: 2026-07-23
last_updated: 2026-07-23
authority: docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
sources:
  - https://docs.battlechain.com/battlechain/reference/mock-contracts
  - contracts/protocols/** TestBases, procedures, factories
  - scripts/foundry/Script_Promo_BC_*.s.sol
---

# BC greenfield deploy research

Research notes for phases that lacked a clear deploy recipe, and a definitive **BattleChain-provided (bind only)** inventory.

**Policy:** Do **not** deploy anything BattleChain already provides. Bind addresses; only CREATE3-deploy Crane-owned surfaces that are missing.

---

## 1. BattleChain-provided — always bind, never deploy

Source: [Mock & Dependency Contracts](https://docs.battlechain.com/battlechain/reference/mock-contracts) (testnet chain `627`).

### 1.1 Tokens

| Asset | Address |
|-------|---------|
| WETH | `0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42` |
| USDC | `0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE` |
| USDT | `0x0d414B0CCef51a25cd32c93b869A9fF2e883a27E` |
| DAI | `0x393cBd865554a543D992218d190EA9dcE47d9bC2` |
| WBTC | `0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0` |
| LINK | `0xDBCaD9c8f2757f1b7Fe7fC394bEB035018aEA9DC` |
| MTK | `0xA55C81615ea60e870d7a4Dff8C662B4C39c56C80` |

### 1.2 Chainlink mock feeds (8 decimals)

| Feed | Address |
|------|---------|
| ETH/USD | `0xAA72F0168eE17aA93098eC6ECf2EEe72B46aca19` |
| BTC/USD | `0xd87f56De7Fe8d2913B3B8e45C5fd983185286b66` |
| LINK/USD | `0xEa8789e4f6a1d101AfF3093543FC8133c27987FD` |
| USDC/USD | `0x469be0Db9E0E884a2D9E64a186008C684423B79C` |

### 1.3 Uniswap V3 (mock)

| Contract | Address |
|----------|---------|
| UniswapV3Factory | `0xd5DCFCab1B60C70F45D61597b351674b4b3C8CDc` |
| SwapRouter | `0x4FC93149e329C15BfF627E967aaA487079D89d2F` |
| NonfungiblePositionManager | `0x43d314e63223041C61460c9A2F5e597Ff7D1cd30` |

**Phase 1 / 7:** do **not** redeploy Uni V3. Phase 1 still deploys Crane Uni V2 + Uni V4 PoolManager (not provided by BC).

### 1.4 Euler V2 (mock) — **Phase 4 bind**

| Contract | Address |
|----------|---------|
| EVC | `0xB5D56dECA76e65cC9332Af01971bC8ad018a1Fc1` |
| eUSDC Vault | `0x9a6fb480a74e6BAEE31EAbe297384ceA1EBb4d81` |
| eWETH Vault | `0x38aF9d1C638C43d4340a700A854721dD5cdCf974` |

**Implication:** Do **not** redeploy EVC or those vaults on BC for greenfield. Phase 4 script **binds** BC Euler. Only deploy Crane-specific Euler surfaces if product later requires EVK factory/perspectives **beyond** the mock (optional extras — not required for “Euler available on BC”).

### 1.5 Venus (Compound-style mock) — not Comet

| Contract | Address |
|----------|---------|
| Comptroller | `0xAE582334FCf2f932ea1B4D0B484aC34A8184B2e8` |
| vUSDC, vWETH, vWBTC, vDAI, vBNB, vUSDT | see BC docs |

**Implication:** BC provides Venus (Compound V2-style), **not** Compound Comet (V3).  
- If inventory “Compound” means “lending markets to integrate against,” **bind Venus**.  
- If inventory requires **Comet specifically**, that remains a Crane port + deploy (Phase 5). Prefer **bind Venus** unless product explicitly needs Comet bytecode.

### 1.6 Morpho Blue (mock)

| Contract | Address |
|----------|---------|
| MockMorpho | `0x102CdAF4B7097752f2Bb336c6cDf39f0aBBbb58c` |

Preconfigured markets USDC/WETH, USDC/WBTC, WETH/WBTC. **Bind if needed; do not redeploy Morpho.**

### 1.7 Other BC dependencies

| Surface | Address / note |
|---------|----------------|
| MockKyberSwapRouter | `0x5A8Eec040E6CDD11cf78A154a5485677aEeb4d0b` |
| MockCCIPRouter | `0xFA553888e385ECd9ab294e295C206b912a0F402E` |
| Safe stack | full Safe / SafeProxyFactory / MultiSend / … (testnet addresses in BC docs) |
| SafeHarbor / AttackRegistry / BattleChainDeployer / CreateX | already in `BC_TESTNET.sol` |

### 1.8 Not provided by BC (Crane must deploy if in scope)

- Crane Create3Factory / DiamondPackageCallBackFactory  
- ERC20Permit DFPkg surfaces / sample token  
- Uni V2 factory/router, Uni V4 PoolManager + periphery  
- BetterPermit2  
- Balancer V3 (full Crane diamond stack)  
- Aerodrome + Slipstream  
- Camelot V2  
- Aave V3/V4 (full market)  
- Liquity BOLD  
- Sky/DSS  
- Reliquary  
- Pendle / Frax (as scoped)  
- Resupply (if kept)  
- Comet (only if not replaced by Venus bind)

---

## 2. Phase research — how to deploy (Crane-owned only)

### 2.1 Phase 3 — Aave V3

**Source of truth in Crane:**  
`contracts/protocols/lending/aave/v3.6/deployments/procedures/*`  
and `IMarketReportTypes.MarketReport` / `InitialReport` / `SetupReport` / `PeripheryReport`.

**Recommended script path:** wrap procedure calls under CREATE3 (or sequential create3 of each `new X`) in `Script_BC_Phase3_Aave.s.sol`, roles = deployer.

**Deploy order (minimal BC market):**

| Step | Procedure / action | Deploys |
|------|--------------------|---------|
| 1 | `AaveV3SetupProcedure._initialDeployment` | PoolAddressesProvider, DefaultReserveInterestRateStrategyV2, PoolAddressesProviderRegistry (or reuse registry) |
| 2 | `AaveV3PoolProcedure._deployAaveV3Pool` | Pool implementation (`PoolInstance`), PoolConfigurator implementation |
| 3 | Treasury procedure | Treasury / collector implementation + proxy |
| 4 | Oracle procedure | AaveOracle — **sources = BC Chainlink mocks** for WETH/USDC/DAI/WBTC as listed |
| 5 | Tokens procedure | aToken + variableDebtToken implementations |
| 6 | Rewards / incentives (if enabling rewards) | EmissionManager, RewardsController impl + proxy |
| 7 | `_setupAaveV3Market` | ACLManager, set implementations on provider, pool/configurator proxies |
| 8 | Pool configurator | `initReserves` for BC tokens (WETH, USDC, DAI at minimum) |
| 9 | Optional periphery | ProtocolDataProvider, UI data providers, WrappedTokenGateway |

**Bind:** WETH, USDC, DAI, WBTC, LINK; BC Chainlink feeds; Phase 1 factory.

**Do not deploy:** BC tokens or oracles.

**Aave V4:** separate module from `aave/v4/deployments/` (hub/spoke orchestration). Implement after V3 script compiles; same bind rules.

**Local verify:** supply/borrow one asset via Pool using minted BC USDC/WETH.

---

### 2.2 Phase 4 — Euler

**BattleChain already deploys mock Euler V2 (EVC + eUSDC + eWETH).**

| Action | Detail |
|--------|--------|
| **Default Phase 4** | **Bind only** — write EVC + vault addresses into manifest; no CREATE3 of EVC/vaults |
| **Optional extras** | Only if product needs Crane EVK factory / perspectives / IRM factories for *new* vaults beyond mocks — deploy under Phase 1 factory, still bind BC EVC if vaults must register with it (confirm mock EVC allows external vault registration; if not, extras may be standalone Crane EVK) |

**Script:** `Script_BC_Phase4_Euler.s.sol` primarily **records binds** + optional extras.

**Do not redeploy:** BC EVC, eUSDC, eWETH.

**Crane code** (`euler/v1/evc`, `vault`, `periphery/*Factory`) remains for hermetic tests and non-BC chains; BC greenfield uses BC mocks for the core path.

---

### 2.3 Phase 5 — Compound / Comet vs Venus

| Option | Recommendation |
|--------|----------------|
| **A (preferred)** | Treat Phase 5 as **bind BC Venus** (Comptroller + vTokens). Rename/clarify inventory X to “Compound-style lending (Venus mock) on BC.” No Comet port required for greenfield. |
| **B** | True **Comet** port + deploy — only if product requires Comet bytecode parity. Port not in Crane today. |

**Research choice for PRD:** **Option A** unless explicitly overridden — aligns with “do not deploy what BC provides.”

---

### 2.4 Phase 6 — Aerodrome + Slipstream

Already refined from `TestBase_Aerodrome` (see PRD). BC does **not** provide Aerodrome — full deploy.

**Bind:** WETH (and BC tokens for pools).

---

### 2.5 Phase 7 — Uniswap extras

| Surface | Action |
|---------|--------|
| Uni V3 factory / router / NPM | **Bind BC** — never deploy |
| Uni V2 factory / router | Already Phase 1 Crane deploy |
| Uni V4 PoolManager | Already Phase 1 Crane deploy |
| **Deploy in Phase 7** | PositionManager (ctor: PoolManager, Permit2, unsubscribeGasLimit, PositionDescriptor, WETH) |
| | PositionDescriptor |
| | V4Router (or equivalent) |
| | StateView, V4Quoter (lens) |

**Bind:** Phase 1 PoolManager + Permit2 + WETH; BC Uni V3 for manifest completeness.

---

### 2.6 Phase 8 — Camelot

Unchanged: Factory + Router from `TestBase_CamelotV2`. BC does not provide Camelot.

---

### 2.7 Phase 9 — Liquity / BOLD

**Source:** `contracts/protocols/cdps/liquity/v2/bold/*`, especially `AddressesRegistry` (lists every core dependency).

**Per-collateral branch deploy graph (one branch e.g. WETH):**

1. BoldToken  
2. CollateralRegistry  
3. AddressesRegistry (params: CCR, MCR, BCR, SCR, liquidation penalties)  
4. ActivePool, DefaultPool, GasPool, CollSurplusPool  
5. StabilityPool  
6. SortedTroves, TroveManager, TroveNFT, MetadataNFT  
7. BorrowerOperations  
8. PriceFeed adapted for BC — use **BC Chainlink ETH/USD** (or WETH feed path); do **not** deploy mainnet-only LST feeds unless those assets exist on BC  
9. HintHelpers, MultiTroveGetter, RedemptionHelper as needed  
10. `AddressesRegistry.setAddresses(...)` wiring  
11. InterestRouter if required by branch  

**Bind:** WETH = BC WETH; oracles = BC Chainlink; Uni V3 for zappers = BC Uni V3 if zapper path enabled.

**Zappers:** optional for greenfield; if enabled, bind BC Uni V3 / do not redeploy V3.

**Gov (V2-gov):** separate optional slice; not required for core open-trove path.

---

### 2.8 Phase 10 — Sky

Unchanged: `SkyDssFactoryService.deployDss` + `initIlk` with BC gem or mock collateral + pip (BC Chainlink or DSValue for test).

---

### 2.9 Phase 11 — Resupply — **DROPPED**

Not in Crane. **Removed from greenfield scope** (product decision 2026-07-23). Revisit after a port.

### 2.9b Phase 3b — Aave V4 (code present)

| Question | Answer |
|----------|--------|
| Missing protocol code? | **No** |
| Missing deploy infrastructure? | **No** — orchestration in-tree |
| Full BC procedure | **[`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md)** |
| BC blocker found | Safe Singleton CREATE2 `0x914d7Fec…` has **no code** on BC testnet (2026-07-23). Must deploy that factory or Path B adapter before orchestration |
| Provenance | `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md` |

---

### 2.10 Phase 12 — Reliquary

Unchanged from TestBase_Reliquary. Bind BC tokens as reward/pool tokens.

---

### 2.11 Phase 13a — Pendle

**Deploy factories first, then one market:**

| # | Deploy |
|---|--------|
| 1 | Pendle Router (AllAction V3 port) |
| 2 | PendleYieldContractFactory |
| 3 | PendleMarketFactoryV3 |
| 4 | One SY for a BC-available asset (e.g. simple ERC4626 SY if port has implementation, or pendle SY for a mock yield token) |
| 5 | `PendlePoolDeployHelper` (or inline): createYieldContract → createNewMarket → optional seed liquidity |
| 6 | Oracle helpers if required for that market |

**Helper:** `PendlePoolDeployHelper.sol` — constructor(router, yieldContractFactory, marketFactory).

**Bind:** BC tokens for seed; no Pendle on BC today.

---

### 2.12 Phase 13b — Frax

Minimum from tests: FraxswapFactory (+ pair via factory), BAMM path as in TestBase_FraxBAMM. Bind BC tokens.

---

### 2.13 Phase 1–2

Already covered by Launch / Wave B scripts + PRD. BC binds: WETH, Uni V3, tokens, Chainlink, SafeHarbor stack.

---

## 3. Revised phase action matrix

| Phase | Deploy Crane? | Bind BC? | Primary research outcome |
|-------|---------------|----------|---------------------------|
| 1 Factories | **Yes** | Tokens, Uni V3, WETH, SafeHarbor | Existing Launch script |
| 2 Balancer | **Yes** | WETH, Permit2 (Phase 1), tokens | Wave B + DFPkg tests |
| 3 Aave | **Yes** | Tokens, Chainlink | AaveV3*Procedure order |
| 4 Euler | **Bind mock** (default) | EVC, eUSDC, eWETH | BC mock Euler |
| 5 Compound | **Bind Venus** (default) | Comptroller + vTokens | BC Venus ≠ Comet |
| 6 Aerodrome | **Yes** | WETH, tokens | TestBase_Aerodrome |
| 7 Uniswap extras | **Yes** V4 periphery only | Uni V3; Phase 1 V2/V4 PM | PositionManager ctor |
| 8 Camelot | **Yes** | WETH | TestBase_CamelotV2 |
| 9 Liquity | **Yes** | WETH, Chainlink, optional Uni V3 | AddressesRegistry graph |
| 10 Sky | **Yes** | Tokens/oracles | SkyDssFactoryService |
| 11 Resupply | **Dropped** | — | Not ported |
| 3b Aave V4 | **Yes** (code in-tree) | Tokens, Chainlink | Orchestration + LiquidationLogic two-step |
| 12 Reliquary | **Yes** | Tokens | TestBase_Reliquary |
| 13a Pendle | **Yes** | Tokens | Yield + Market factories + helper |
| 13b Frax | **Yes** | Tokens | Fraxswap/BAMM tests |
| Morpho | **Bind only** if needed | MockMorpho | Not a numbered phase; available |

---

## 4. Script implementation notes

1. Put all BC bind addresses in `BC_TESTNET.sol` (expand constants for Euler, Venus, Morpho, Kyber, Safe, CCIP).  
2. Phase scripts that only bind should still write manifests (SoT for docs).  
3. Never CREATE3 bytecode that replaces BC mocks for the same protocol role.  
4. Gas: `-g 400+`, `--skip-simulation` on BC.  
5. Oracles for Crane-deployed protocols: wire **BC Chainlink mocks** via `updateAnswer` for tests.

---

## 5. Open product confirmations (only if overriding research defaults)

These are **defaults already chosen by research** (bind BC). Override only if product requires Crane bytecode parity:

| Default | Override would mean |
|---------|---------------------|
| Phase 4 bind BC Euler | Deploy full Crane EVC/EVK instead |
| Phase 5 bind BC Venus | Port + deploy Comet |
| Phase 7 no Uni V3 deploy | (none — BC provides V3) |

---

## 6. Change log

| Date | Change |
|------|--------|
| 2026-07-23 | Initial research: full BC mock inventory; Aave procedures; Euler/Venus bind; Uni V4 periphery; BOLD AddressesRegistry; Pendle factories |
| 2026-07-23 | Drop Resupply; confirm Aave V4 vendored deploy stack complete |
| 2026-07-23 | BC_AAVE_V4_DEPLOY_STEPS.md; Safe Singleton factory missing on BC testnet |
