# PRD: Porting Active DeFi Protocols into Crane

**Date:** 2026-06-26
**Status:** Draft for review
**Owners:** Crane core
**Companion docs:** [`DEFI_RESEARCH.md`](./DEFI_RESEARCH.md) (rationale/TVL), [`DEFI_PORTING_PRIORITIZATION.md`](./DEFI_PORTING_PRIORITIZATION.md) (ranking/sequencing)
**Related vault PRDs:** `indexedex/prds/AaveV3V4CrossVersionCarryLoopVault.md`, `indexedex/prds/Leveraged_Constant_Product_Vaults_*.md`

---

## Part A — Program Overview

### A.1 Goal

Port the fourteen DeFi protocols identified in `DEFI_PORTING_PRIORITIZATION.md` into the Crane framework as **full, faithful ports** of each protocol's own contracts, with their **shared/low-level dependencies remapped to Crane's existing ported equivalents**. The result is a set of first-class, fork-tested Crane integrations that strategy-vault builders consume directly — covering curated-vault allocation, yield-bearing collateral, leverage/credit primitives, correlated-asset AMMs, and oracleless/permissionless lending.

### A.2 Scope

All fourteen protocols, each in actionable detail:

| # | Protocol | Crane category (target dir) | Lang |
|---|----------|------------------------------|------|
| 1 | Ethena (USDe / sUSDe) | `tokens/ethena/` | Solidity |
| 2 | Lido (wstETH) | `staking/lido/` | Solidity |
| 3 | Morpho Blue | `lending/morpho/blue/` | Solidity |
| 4 | Morpho Vaults (MetaMorpho) | `lending/morpho/metamorpho/` | Solidity |
| 5 | Ajna (V2) | `lending/ajna/` | Solidity |
| 6 | Sky sUSDS + Spark | `cdps/sky/savings/`, `lending/spark/` | Solidity |
| 7 | Yearn V3 | `vaults/yearn/` (new category) | Vyper + Solidity |
| 8 | Silo V2 | `lending/silo/` | Solidity |
| 9 | Curve (core stable/crypto + gauges) | `dexes/curve/`, `staking/curve/` | Vyper |
| 10 | Curve LlamaLend V2 | `lending/curve-llamalend/` | Vyper |
| 11 | Convex | `staking/convex/` | Solidity |
| 12 | Fluid (Instadapp) | `lending/fluid/` | Solidity |
| 13 | Alchemix V3 | `cdps/alchemix/` | Solidity |
| 14 | Gearbox V3 | `lending/gearbox/` | Solidity |

**Out of scope (per research):** off-chain components (Ethena hedging desk, DAO curation/governance weighting), Impermax V3 (excluded — known core valuation flaw), EigenLayer (watchlist only). Periphery/CLI/deployer/keeper trees are excluded unless they contain security-critical logic worth holding locally.

### A.3 Relationship to the carry/loop vault work

This PRD makes the **dependencies** available; it does not build the consumer vaults. The carry/loop and leveraged-LP vault PRDs in `indexedex/prds/` are the downstream consumers. Where a port directly feeds those vaults (sUSDe, wstETH, Morpho Blue, Euler — already ported), the verification section includes a minimal "consumed by a CraneTest vault" smoke example, not a full vault build.

### A.4 Core design principle — faithful logic, reused dependencies

> **Port each protocol's own contracts faithfully; rewrite their dependency imports to Crane's already-ported equivalents.**

- **Faithful** = the protocol's domain contracts (its market/AMM/vault/CDP logic) are vendored into `contracts/external/<lib>/` byte-for-logic equivalent to a pinned upstream tag, so behavior matches mainnet and audits remain meaningful.
- **Reused** = the shared libraries underneath them (OZ, Solady, ERC4626 base, oracle adapters, rate-provider pattern, Permit2 aware layer, EVC) are **not** re-vendored from the protocol's copy; their imports are rewritten to the corresponding `@crane/...` path.
- The Crane-native surface on top (Service / AwareRepo / Facet-Target-Repo / DFPkg) is **new** code that wraps the vendored protocol for use inside Diamonds.

This is the crux of the effort: a faithful port that does **not** duplicate shared infrastructure already in Crane.

### A.5 Definition of done (applies to every protocol section)

A protocol port is complete when all of the following hold:

1. **Vendored upstream** under `contracts/external/<lib>/`, pinned to a stated tag/commit, with shared deps remapped to `@crane/...` (no protocol-local copies of OZ/Solady/oracle/Permit2/EVC).
2. **No new git submodules** — sources are copied in (per standing project rule).
3. **`@crane/` imports only** — no relative or bare `contracts/` imports; no unauthorized `foundry.toml`/`remappings.txt` edits.
4. **Crane wrapper surface** present: interfaces + Service (always); AwareRepo/Facet-Target-Repo where stateful in-Diamond use is intended; DFPkg where it fits the Diamond factory model.
5. **Verification:** fork test(s) against the live deployment(s) listed in the section, plus `Behavior_*` validation of any interface Crane consumers rely on, plus a `TestBase` descendant and an example-usage `CraneTest`.
6. **Docs/NatSpec** per Crane conventions; CODEBASE_MAP regenerated or its protocol section updated.
7. **Task tracked** under the allocated CRANE-### range (see A.8).

### A.6 Cross-cutting concerns (resolve in Phase 0, re-check per port)

- **Licensing (gating).** Several targets are **BUSL-1.1** (Gearbox core-v3; Morpho Blue & MetaMorpho; portions of Curve). Vendoring BUSL source into Crane has redistribution/relicensing implications that **must be cleared before those ports start**. Track a per-protocol license field; do not vendor BUSL code until cleared. MIT/GPL targets (Lido, Ajna, Fluid, Ethena audit set, Yearn) are lower-risk but still recorded.
- **Vyper sources.** Curve core, Curve LlamaLend, and Yearn vaults-v3 are **Vyper**. Decision per port: (a) vendor `.vy` and compile via Foundry's Vyper support, or (b) port interfaces + a Solidity reference of the novel math (LLAMMA, StableSwap invariant) and fork-test against live Vyper deployments. Default: **(b) interfaces + Solidity service/wrappers + fork tests**, vendoring `.vy` only where re-deployment in tests is required.
- **Dependency substitution map** is built once in Phase 0 (Part B) and referenced by every section.
- **Oracle reuse.** All oracle-based lenders (Morpho, Silo, LlamaLend, Spark, Gearbox, Fluid) route to Crane's existing Chainlink/Pyth/RedStone adapters; LP-collateral paths use fair-reserves + TWAP, never spot.

### A.7 Sequencing (execution order, not detail level)

Detail is uniform across all 14 in this document; **build order** follows the prioritization phases:

- **Phase 0** — Shared-dependency prep (Part B) + license clearances + Vyper decision.
- **Phase 1** — Ethena, Lido, Morpho Blue, MetaMorpho, Ajna.
- **Phase 2** — Sky sUSDS + Spark, Yearn V3.
- **Phase 3** — Silo V2, Curve core + LlamaLend + Convex.
- **Phase 4** — Fluid, Alchemix V3, Gearbox V3.

### A.8 Task index allocation

Highest existing task index is CRANE-269. Allocate:

| Range | Workstream |
|-------|-----------|
| CRANE-270–279 | Phase 0 shared-dep prep + license/Vyper decisions |
| CRANE-280–299 | Phase 1 (5 protocols) |
| CRANE-300–319 | Phase 2 |
| CRANE-320–349 | Phase 3 |
| CRANE-350–379 | Phase 4 |

> Addresses and exact upstream tags marked **(verify)** must be confirmed from official docs/explorer at port time before fork tests are written.

---

## Part B — Shared-Dependency Prep (Phase 0)

One-time inventory of what upstream protocols import vs. what Crane already provides. Porting these once unblocks every section. Each row is the substitution applied during A.4 remapping.

| Upstream dependency | Crane equivalent | Status / action |
|--------------------|------------------|-----------------|
| OZ `ERC20`, `ERC20Burnable`, `ERC20Permit`, `Ownable2Step`, `AccessControl` | `@crane/contracts/token/...`, `@crane/contracts/access/...` | Confirm coverage from Aave work; add any v5 gaps to `contracts/external/openzeppelin/` |
| OZ/Solady `ERC4626` base | Crane ERC4626 (`crane-tokens` skill surface) | Confirm 4626 base + decimals-offset variant exists; add if missing |
| Solady `SafeTransferLib`, `FixedPointMathLib`, `EIP712`, `LibBit` | `@crane/contracts/utils/...` (`SafeCastLib`, `Create2`, etc.) | Map per-symbol; add missing Solady pieces to `contracts/external/solady/` |
| Permit2 | Crane Permit2 aware layer | Already ported — reuse |
| Chainlink / Pyth / RedStone feeds | Crane oracle adapters (`oracles/`) | Already ported — reuse; add fair-reserves LP oracle adapter (shared by Morpho/Silo/LlamaLend) |
| Rate-provider pattern (LST/4626 exchange rate) | Existing Balancer-derived rate-provider pattern | Generalize into a reusable RateProvider facet (used by Ethena/Lido/sUSDS) |
| EVC (Ethereum Vault Connector) | Crane Euler EVC port | Already ported — reuse for Gearbox/Silo-style composability where applicable |
| Aave V3 base (for forks) | Crane Aave V3 port | Reuse for Spark (Aave V3 fork) |
| Sky/Maker DSS core (Vat, Pot, Jug…) | Crane Sky port | Reuse for sUSDS savings rate accrual |
| Curve math (StableSwap/Crypto invariant) | none today | New in Phase 3; shared by LlamaLend |
| Multicall / Multicall3 | Crane equivalent (verify) | Add to `contracts/external/` if missing |

**Phase 0 deliverables:** the gap list above resolved (each "add if missing" closed), the reusable RateProvider facet, the fair-reserves LP oracle adapter, license clearances for BUSL targets, and the Vyper handling decision (A.6).

---

## Part C — Per-Protocol Sections

Each section uses the uniform template: **Upstream source · Live deployments · Crane dependency map · Port layout · Crane wrapper surface · Verification · Risks/notes**.

---

### C.1 Ethena (USDe / sUSDe)

- **Upstream source:** `ethena-labs/bbp-public-assets` (contracts dir: `USDe.sol`, `EthenaMinting.sol`, `StakedUSDe.sol`, `StakedUSDeV2.sol`, `USDeSilo`) cross-checked against audit set `code-423n4/2023-10-ethena`. Pin a tag/commit **(verify)**. License: review (audit repo) **(verify)**.
- **Live deployments (Ethereum):** USDe `0x4c9EDD5852cd905f086C759E8383e09bff1E68B3`; sUSDe (StakedUSDeV2) `0x9D39A5DE30e57443BfF2A8307A4256c8797A3497`; EthenaMinting **(verify)**.
- **Crane dependency map:** OZ `ERC20Burnable`/`ERC20Permit`/`AccessControl` → Crane token/access; ERC4626 base → Crane 4626; rate read → reusable RateProvider facet (B).
- **Port layout:** `contracts/external/ethena/` (vendored USDe, StakedUSDeV2, Silo, minting); `contracts/protocols/tokens/ethena/` (Crane wrappers).
- **Crane wrapper surface:** `IUSDe`, `ISUSDe`, `IEthenaMinting`; `EthenaService` (mint/redeem/stake/cooldown/unstake helpers); `SUSDeRateProvider` facet (exchange rate for vault accounting). DFPkg optional.
- **Verification:** fork test of stake → 8h vesting → cooldown → unstake; `Behavior_ERC4626` on sUSDe; rate-provider Behavior; example CraneTest consuming sUSDe as collateral value.
- **Risks/notes:** off-chain hedging not ported; model 7-day cooldown + possibly-negative funding in any consumer accounting.

---

### C.2 Lido (wstETH)

- **Upstream source:** `lidofinance/core` — `WstETH.sol` (+ `IStETH` for rate). Pin tag **(verify)**. License: GPL-3.0 **(verify)**.
- **Live deployments (Ethereum):** wstETH `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0`; stETH `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84`. (Base wstETH bridged **(verify)**.)
- **Crane dependency map:** OZ `ERC20Permit` → Crane token; exchange-rate read → reusable RateProvider facet (B).
- **Port layout:** `contracts/external/lido/` (WstETH + interfaces); `contracts/protocols/staking/lido/` (wrappers).
- **Crane wrapper surface:** `IWstETH`, `IStETH`; `LidoService` (wrap/unwrap, `stEthPerToken`/`tokensPerStEth`); `WstETHRateProvider` facet. Withdrawal-queue interface optional (read-only).
- **Verification:** fork test wrap/unwrap + rate read; `Behavior_RateProvider`; example CraneTest using wstETH as ETH-yield collateral leg.
- **Risks/notes:** wrapper-only; full Lido DAO out of scope.

---

### C.3 Morpho Blue

- **Upstream source:** `morpho-org/morpho-blue` — `src/Morpho.sol` + `src/libraries/*` (incl. `periphery`) + `src/interfaces/*`. Pin tag **(verify)**. **License: BUSL-1.1 — clear before vendoring (A.6).**
- **Live deployments:** Morpho Blue singleton (Ethereum & Base) `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` **(verify on Base)**.
- **Crane dependency map:** minimal external; `SafeTransferLib`/math → Crane utils; `IOracle`/`IIrm` adapters → Crane oracle adapters; LP collateral → fair-reserves LP oracle (B).
- **Port layout:** `contracts/external/morpho/blue/` (Morpho.sol + libs); `contracts/protocols/lending/morpho/blue/` (wrappers).
- **Crane wrapper surface:** `IMorpho`, `IIrm`, `IOracle`; `MorphoBlueService` (createMarket / supply / supplyCollateral / borrow / repay / withdraw / liquidate, with `MarketParams`/`Id` helpers); example IRM + oracle adapter. AwareRepo for in-Diamond market bookkeeping if a consumer holds positions.
- **Verification:** fork tests against live markets (supply/borrow/liquidate); `Behavior_MorphoMarket`; example CraneTest opening a permissionless market with a Crane oracle adapter.
- **Risks/notes:** immutable core = clean port; curator risk lives in the vault layer (C.4). Stream-Finance-class looping risk is a consumer constraint (conservative LTV, no circular collateral).

---

### C.4 Morpho Vaults (MetaMorpho)

- **Upstream source:** `morpho-org/metamorpho` — `src/MetaMorpho.sol` + factory + roles/adapters. Pin tag **(verify)**. **License: BUSL-1.1 / GPL — clear before vendoring (A.6).**
- **Live deployments:** MetaMorpho factory (Ethereum & Base) **(verify)**.
- **Crane dependency map:** depends on C.3 (Morpho Blue); ERC4626 base → Crane 4626; `Ownable2Step`/`Multicall` → Crane equivalents.
- **Port layout:** `contracts/external/morpho/metamorpho/`; `contracts/protocols/lending/morpho/metamorpho/`.
- **Crane wrapper surface:** `IMetaMorpho`, `IMetaMorphoFactory`; `MetaMorphoService` (deposit/withdraw, allocation queue, roles: curator/allocator/guardian); **DFPkg** candidate — this is the reference curated-vault pattern for Crane consumers.
- **Verification:** fork test deposit → allocate across Blue markets → withdraw; `Behavior_ERC4626` + role-gating Behaviors; example CraneTest deploying a curated vault via DFPkg over C.3.
- **Risks/notes:** curator risk — expose allocation/cap/oracle params transparently. Do C.3 first.

---

### C.5 Ajna (V2)

- **Upstream source:** `ajna-finance/ajna-core` — `ERC20Pool`/`ERC721Pool`, `ERC20PoolFactory`/`ERC721PoolFactory`, `PositionManager`, `PoolInfoUtils`, base/libs. solc 0.8.18. Pin a release tag from `ajna-finance/ajna-core/releases` **(verify)**. License: review **(verify)**; audits in `ajna-finance/audits`.
- **Live deployments:** broadly deployed (Ethereum, Base, Arbitrum, OP, Polygon, …). Pull factory/utils addresses from official deployments **(verify)**.
- **Crane dependency map:** minimal; base64/NFT contained; PRB/solmate math → Crane utils where equivalent, else vendor under `external/ajna/`. **No oracle** — nothing to remap there.
- **Port layout:** `contracts/external/ajna/` (pools, factories, position/bucket/auction libs); `contracts/protocols/lending/ajna/` (wrappers).
- **Crane wrapper surface:** `IAjnaPool`, `IAjnaPoolFactory`, `IPositionManager`; `AjnaService` (create pool, add/remove quote at bucket price, draw/repay debt, kick/take auctions). AwareRepo for a consumer that lends into buckets.
- **Verification:** fork test create pool → lender deposits buckets → borrower posts collateral → borrow → auction; `Behavior_AjnaPool`; example CraneTest taking an LP token as collateral in a self-created oracleless market (the headline LP-collateral capability).
- **Risks/notes:** oracleless ⇒ no LP-oracle-manipulation class; risk shifts to lender mispricing + thin-pool liquidation speed — model active liquidity in any vault that lends here.

---

### C.6 Sky sUSDS + Spark

- **Upstream source:** sUSDS (Savings USDS, ERC4626 over USDS) from the Sky/Spark savings contracts **(verify repo: sky-ecosystem / marsfoundation)**; Spark = `marsfoundation/sparklend-v1-core` (Aave V3 fork) + Spark PSM **(verify)**. License: AGPL/BUSL **(verify per repo)**.
- **Live deployments (Ethereum):** sUSDS `0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD` **(verify)**; USDS **(verify)**; SparkLend Pool **(verify)**.
- **Crane dependency map:** sUSDS savings accrual → reuse Crane Sky DSS core (Pot-style rate); Spark → reuse Crane **Aave V3 port** (fork delta only); ERC4626 base → Crane 4626; rate read → RateProvider facet (B).
- **Port layout:** `contracts/external/sky/savings/` (sUSDS); `contracts/external/spark/` (fork deltas vs Aave); `contracts/protocols/cdps/sky/savings/`, `contracts/protocols/lending/spark/`.
- **Crane wrapper surface:** `ISUSDS` + `SUSDSService` + `SUSDSRateProvider`; Spark: reuse Aave interfaces, add `SparkService` + a diff doc of Spark-specific changes.
- **Verification:** fork test sUSDS deposit/accrue/withdraw; Spark supply/borrow fork test reusing the Aave test harness; Behaviors via existing Aave behavior libs.
- **Risks/notes:** mostly incremental — prefer reuse over re-port. Capture only the Spark↔Aave delta.

---

### C.7 Yearn V3

- **Upstream source:** `yearn/yearn-vaults-v3` (Vyper `VaultV3.vy`, `TECH_SPEC.md`) + `yearn/tokenized-strategy` (Solidity `TokenizedStrategy.sol`, immutable proxy). Pin tags **(verify)**. License: AGPL **(verify)**.
- **Live deployments:** Vault factory + TokenizedStrategy implementation **(verify)**.
- **Crane dependency map:** ERC4626 base → Crane 4626; `tokenized-strategy` proxy pattern → keep faithful; Vyper handling per A.6 (default: interface + Solidity reference of allocator/debt-management, fork-test the live Vyper vault).
- **Port layout:** `contracts/external/yearn/v3/`; **new category** `contracts/protocols/vaults/yearn/`.
- **Crane wrapper surface:** `IVaultV3`, `ITokenizedStrategy`, `IRoleManager`; `YearnV3Service` (deposit/withdraw, add/remove strategy, debt allocation); this is the **multi-strategy allocator reference** Crane consumers mirror — DFPkg candidate for the strategy/allocator split.
- **Verification:** fork test deposit → allocate to a strategy → report → withdraw; `Behavior_ERC4626` + allocator Behaviors; example CraneTest of an allocator + one tokenized strategy.
- **Risks/notes:** Vyper vault core; port interfaces + Solidity reference rather than re-implementing Vyper. Curator/strategy risk — expose params.

---

### C.8 Silo V2

- **Upstream source:** `silo-finance/silo-contracts-v2` (monorepo; `silo-core/contracts/`: `Silo.sol`, `SiloConfig.sol`, `SiloFactory`, hooks, interfaces). Pin a release tag (e.g. `0.20.0`) **(verify)**. License: review **(verify)**; Immunefi-covered.
- **Live deployments:** Silo V2 factory + deployed silos **(verify)**.
- **Crane dependency map:** ERC4626 (Silo is 4626-compatible) → Crane 4626; OZ → Crane; oracle adapters → Crane oracles; LP collateral → fair-reserves LP oracle (B); hooks system kept faithful.
- **Port layout:** `contracts/external/silo/v2/`; `contracts/protocols/lending/silo/`.
- **Crane wrapper surface:** `ISilo`, `ISiloConfig`, `ISiloFactory`, hooks interfaces; `SiloService` (deploy silo, deposit/borrow/repay/withdraw, transition collateral, liquidate). AwareRepo for in-Diamond positions.
- **Verification:** fork test deploy two-asset silo → borrow/liquidate; `Behavior_Silo`; example CraneTest of an LP-collateral silo with a Crane fair-reserves oracle.
- **Risks/notes:** oracle quality is the real work (shared with Morpho/LlamaLend). Third isolated-market option after Morpho/Euler.

---

### C.9 Curve (core stable/crypto + gauges)

- **Upstream source:** StableSwap-NG / Tricrypto-NG factories + pools from `curvefi` (`stableswap-ng`, `tricrypto-ng`/`twocrypto-ng`) and gauge contracts (`curve-dao-contracts`). **All Vyper.** Pin tags **(verify)**. License: review (some BUSL) **(verify)**.
- **Live deployments:** dominant stable pool (e.g. 3pool/USDC-USDT) + one crypto pool + their gauges **(verify)**.
- **Crane dependency map:** new Curve math (StableSwap/Crypto invariant) — Solidity reference under `external/curve/math/` (shared with C.10); gauge reward token reads → Crane token utils; Vyper handling per A.6.
- **Port layout:** `contracts/external/curve/` (interfaces + Solidity math reference); `contracts/protocols/dexes/curve/` (swap/liquidity wrappers); `contracts/protocols/staking/curve/` (gauge wrappers).
- **Crane wrapper surface:** `ICurvePool`, `ICurveFactory`, `ILiquidityGauge`; `CurveService` (quote, exchange, add/remove liquidity, gauge deposit/claim). Quote utils mirroring `ConstProdUtils` style.
- **Verification:** fork tests against live stable + crypto pools (swap, add/remove, gauge stake/claim); `Behavior_CurvePool`; example CraneTest using Curve for loop entry/exit.
- **Risks/notes:** multiple pool versions = surface; start with dominant stable + one crypto. Vyper math fidelity is the critical correctness item — fork-test against live.

---

### C.10 Curve LlamaLend V2

- **Upstream source:** `curvefi/curve-stablecoin` — `AMM.vy` (LLAMMA), `Controller`, lending market factory (V2 generalized markets, branch/tag dated 2026-06-10). **Vyper.** Pin tag **(verify)**. License: review (BUSL portions) **(verify)**.
- **Live deployments:** LlamaLend V2 factory + a representative market **(verify)**.
- **Crane dependency map:** builds on C.9 Curve math; oracle adapters → Crane oracles; LLAMMA soft-liq logic kept faithful; Vyper handling per A.6.
- **Port layout:** `contracts/external/curve/llamalend/`; `contracts/protocols/lending/curve-llamalend/`.
- **Crane wrapper surface:** `ILlamaLendController`, `ILLAMMA`, `ILlamaLendFactory`; `LlamaLendService` (create market, create/adjust loan, soft-liq band reads, repay). AwareRepo for positions.
- **Verification:** fork test create loan → price move → soft-liquidation across bands → recovery; `Behavior_LlamaLend`; example CraneTest demonstrating graceful unwind.
- **Risks/notes:** soft-liq reduces but does not remove bad-debt risk; band + oracle params are safety-critical (sDOLA 2026-03-02 incident). Do C.9 first.

---

### C.11 Convex

- **Upstream source:** `convex-eth/platform` — `Booster.sol`, `BaseRewardPool.sol`, `CvxMining`, reward pools. Pin tag **(verify)**. License: review **(verify)**.
- **Live deployments:** Booster + base reward pools (per Curve gauge) **(verify)**.
- **Crane dependency map:** depends on C.9 Curve gauges; OZ → Crane; reward routing kept faithful.
- **Port layout:** `contracts/external/convex/`; `contracts/protocols/staking/convex/`.
- **Crane wrapper surface:** `IBooster`, `IBaseRewardPool`; `ConvexService` (deposit LP → stake, getReward, withdraw). The "deposit LP → boosted, auto-compounded rewards" vault reference.
- **Verification:** fork test deposit Curve LP → stake → accrue → claim → withdraw; `Behavior_ConvexRewardPool`; example CraneTest of a gauge-wrapper vault.
- **Risks/notes:** after Curve gauges; mostly reward routing.

---

### C.12 Fluid (Instadapp)

- **Upstream source:** `Instadapp/fluid-contracts-public` — `contracts/liquidity/` (userModule `operate()`), `contracts/protocols/vault/` (VaultFactory, vaultT1 core), `contracts/protocols/lending/` (fTokens, 4626), DEX modules, periphery resolvers. Pin commit (e.g. `f8a9385…`) **(verify)**. License: review **(verify)**.
- **Live deployments:** Liquidity layer singleton + VaultFactory + fTokens **(verify)** from `deployments/deployments.md`.
- **Crane dependency map:** central Liquidity layer kept faithful; ERC4626 fTokens → Crane 4626; OZ → Crane; oracle adapters → Crane oracles.
- **Port layout:** `contracts/external/fluid/`; `contracts/protocols/lending/fluid/`.
- **Crane wrapper surface:** `IFluidLiquidity`, `IFluidVault`, `IFluidVaultFactory`, `IFToken`; `FluidService` (operate/deposit/withdraw/borrow/payback, smart collateral/debt vault open/adjust).
- **Verification:** fork test against live Liquidity layer (lend via fToken; open a smart-collateral vault position); `Behavior_FluidVault`; example CraneTest of capital-efficient looping.
- **Risks/notes:** newer architecture, heavy gas-optimized module layout and contract-size limits — watch deployment size when wrapping.

---

### C.13 Alchemix V3

- **Upstream source:** `alchemix-finance/v3-poc` (branch `immunefi_audit`, `src/AlchemistV3.sol`) and/or `alchemix-finance/v3`; audit scope `Cyfrin/2024-12-alchemix`. Core: Alchemist (CDP) + Transmuter + MYT adapters. Pin tag/commit **(verify)**. License: review **(verify)**.
- **Live deployments:** V3 Alchemist + Transmuter **(verify)** from `alchemix-finance/contract-addresses`.
- **Crane dependency map:** MYT layer = wrapper over **Morpho Vaults V2** → depends on C.4; ERC4626 → Crane 4626; OZ → Crane; oracle (peg) reads via Transmuter kept faithful.
- **Port layout:** `contracts/external/alchemix/v3/`; `contracts/protocols/cdps/alchemix/`.
- **Crane wrapper surface:** `IAlchemistV3`, `ITransmuter`, `IMYT`; `AlchemixService` (deposit → mint alAsset, repay, Transmuter queued redemption, earmark/temporal-priority reads).
- **Verification:** fork test deposit → borrow alUSD/alETH → yield pays down debt → Transmuter redemption queue; `Behavior_AlchemistV3` + Transmuter Behaviors; example CraneTest of non-liquidatable leverage.
- **Risks/notes:** solvency = underlying MYT (curator) risk; peg = Transmuter throughput. Do C.4 first.

---

### C.14 Gearbox V3

- **Upstream source:** `Gearbox-protocol/core-v3` — `CreditManagerV3`, `CreditFacadeV3`, `CreditAccountV3`, `PoolV3`; interfaces/adapters from `integrations-v3`, oracles from `oracles-v3`. Pin tag **(verify)**. **License: BUSL-1.1 — clear before vendoring (A.6).**
- **Live deployments:** Credit Manager(s) + Pool(s) + Facade(s) **(verify)**.
- **Crane dependency map:** Credit Account model is EVC-adjacent → reference Crane **Euler EVC** patterns for composable execution; OZ → Crane; price oracles → Crane oracle adapters.
- **Port layout:** `contracts/external/gearbox/v3/`; `contracts/protocols/lending/gearbox/`.
- **Crane wrapper surface:** `ICreditManagerV3`, `ICreditFacadeV3`, `ICreditAccountV3`, `IPoolV3`; `GearboxService` (open credit account, multicall execution with whitelisted targets, manage collateral/debt).
- **Verification:** fork test open credit account → leveraged position via whitelisted adapter → close; `Behavior_GearboxCreditAccount`; example CraneTest of principled (non-flashloan-loop) leverage.
- **Risks/notes:** port V3 Credit Account model, not legacy loop flows. Lower priority; reference for the vault leverage layer.

---

## Part D — Milestones & Acceptance

| Milestone | Contents | Acceptance |
|-----------|----------|-----------|
| M0 | Phase 0 (Part B) | Shared-dep gaps closed; RateProvider facet + fair-reserves LP oracle landed; BUSL clearances recorded; Vyper decision documented |
| M1 | C.1–C.5 | All five meet A.5 definition of done; fork tests green |
| M2 | C.6–C.7 | sUSDS + Spark reuse Aave/Sky harness; Yearn allocator reference |
| M3 | C.8–C.11 | Silo + Curve cluster; Curve math fork-verified |
| M4 | C.12–C.14 | Fluid + Alchemix + Gearbox |

**Global acceptance:** every section's checklist (A.5) satisfied; CODEBASE_MAP updated; no new submodules; no unauthorized remappings; all `@crane/` imports.

---

## Part E — Open Items to Confirm at Port Time

1. All **(verify)** addresses and upstream tags/commits — confirm from official docs/explorer before writing fork tests.
2. **License clearance** for BUSL-1.1 targets (Morpho Blue, MetaMorpho, Gearbox core-v3, Curve portions) — **blocking** for those vendors.
3. **Vyper strategy** final call (vendor `.vy` vs. interface + Solidity reference + fork test) for Curve, LlamaLend, Yearn.
4. New `contracts/protocols/vaults/` category (Yearn) — confirm naming vs. folding under `lending/`.
5. Base vs Ethereum fork targets per protocol (some are Base-first given Aerodrome alignment).
