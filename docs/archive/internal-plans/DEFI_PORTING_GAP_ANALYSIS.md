# DeFi Porting Gap Analysis

**Date:** 2026-06-29  
**Purpose:** Cross-reference shared gaps across the 14 target protocols (from `DEFI_PORTING_PRD.md`) to resolve common dependencies **once**. Analysis performed via GitHub web UI, raw file views, tree browsing, and public audit reports — **no full repo clones required**.

This matrix focuses on the gap categories identified in the PRD's Part B (Shared-Dependency Prep) plus practical porting concerns (license, Vyper, custom math, etc.).

**How this was built (repeatable process):**
- Targeted GitHub tree views for structure (`/tree/<tag>/src` or `/contracts`).
- Raw file fetches for key contracts listed in the PRD (imports, pragma, patterns).
- Inspection of `foundry.toml` / `remappings.txt` where present.
- Cross-reference with Code4rena/Sherlock/audit scopes.
- Only core domain contracts inspected (not tests/periphery).

**Next:** Expand rows for remaining protocols + add "Action" column linking to CRANE-### tasks. Update as Phase 0 items (RateProvider, fair-reserves oracle, missing external/ pieces) land.

## Common Gaps to Resolve Once (High Multiplier)

- **Reusable RateProvider facet** (general, not Balancer-tied): Needed by Ethena, Lido, Sky sUSDS, Yearn, potentially Silo/Morpho LP paths. Current Crane has Balancer-specific `ERC4626RateProvider*` + `IRateProvider`.
- **Generalized ERC4626 base + rate support**: Crane has native `tokens/ERC4626/` (good start). Many protocols have custom/modified 4626 (vesting, cooldown, etc.).
- **Oracle adapters**: Crane has Chainlink/Pyth/Redstone interfaces + external vendors. Missing: fair-reserves LP oracle (shared by Morpho/Silo/LlamaLend), specific rate providers.
- **Solady pieces**: Partial in `external/solady/`. Morpho and others use custom `SafeTransferLib`/`MathLib` — map or vendor selectively.
- **OZ coverage**: Strong vendored set, but verify exact symbols/versions per protocol (esp. older 0.6.x in Lido, drafts).
- **Permit2**: Already fully ported + `Permit2Aware*` (Facet/Repo). High reuse.
- **Vyper handling decision** (per PRD A.6): Curve family + Yearn. Recommend: interfaces + Solidity reference of novel math + live fork tests (avoid full `.vy` recompile unless needed).
- **BUSL licensing clearance**: Blocking for Morpho Blue/MetaMorpho, Gearbox core-v3, portions of Curve.
- **Internal/custom libs**: Many protocols (Morpho, Ajna, Curve math, LLAMMA) have self-contained math. Map to Crane utils where possible (`ConstProdUtils`, Better* libs) or add under `external/`.
- **EVC / composability patterns**: Reuse existing Euler EVC port for Gearbox/Silo-style.

## Phase 1 Matrix (Priority)

| Protocol | Upstream (PRD) | Key Contracts | OZ Usage | Solady / Custom Safe/Math | ERC4626 | RateProvider / Exchange Rate | Oracles | Permit2 | Other Libs / Math | Vyper? | License | Solidity | Notable Patterns | Current Crane Coverage / Gaps | Notes / Specific Vendor Targets |
|----------|----------------|---------------|----------|---------------------------|---------|------------------------------|---------|---------|-------------------|--------|---------|----------|------------------|-------------------------------|---------------------------------|
| **Ethena (USDe/sUSDe)** | ethena-labs/bbp-public-assets (contracts/contracts/) | USDe.sol, EthenaMinting.sol, SingleAdminAccessControl.sol, StakedUSDe.sol, StakedUSDeV2.sol, USDeSilo.sol | ERC20Burnable, ERC20Permit, Ownable2Step | Minimal in core; has internal `lib/math`, `utils` | Yes — StakedUSDeV2 (modified ERC4626 with 8h vesting, 14d cooldown, silo) | Needs dedicated `SUSDeRateProvider` (or generalize existing) | None in core (off-chain for mint/redeem pricing) | Not evident in core | EIP712 signatures for orders, roles (MINTER/REDEEMER/GATEKEEPER), custom vesting | No | Low risk (audit repo) | 0.8.x (verify) | Mint/redeem with routes/custodians, delegation, restricted staker roles | Strong native ERC4626 + Permit2. Gap: RateProvider generalization + cooldown/vesting model + `EthenaService` (mint/stake/unstake). No port started. | Vendor core 5-6 files. Cross-ref with Pendle Ethena SYs (incidental today). Directly feeds carry/loop vaults. |
| **Lido (wstETH)** | lidofinance/core | WstETH.sol (+ IStETH) | Old OZ: ERC20Permit (drafts, 0.6.12) | None | No (pure wrapper) | Yes — `getWstETHByStETH`, `stEthPerToken`, `tokensPerStEth` (shares math) | None | No | Simple staking shortcut (receive ETH) | No | GPL-3.0 (verify) | 0.6.12 (core wrapper); newer versions exist | Rebasable vs static balance wrapper | Has IRateProvider precedent (Balancer). Gap: thin reusable `WstETHRateProvider` + wrap/unwrap service. No dedicated port. | Extremely thin. Versioned contracts dir. Generalize RateProvider here first for multiplier. |
| **Morpho Blue** | morpho-org/morpho-blue (src/) | Morpho.sol + interfaces/, libraries/ (small ~650 LoC core) | Minimal (custom IERC20 interface) | **Custom** `SafeTransferLib` (low-level call, no Solady), internal MathLib, SharesMathLib, UtilsLib, MarketParamsLib | No | User-supplied `IOracle` per market | `IOracle` interface (permissionless) | No | Internal math for shares/assets, interest accrual (Taylor compound), health checks | No | BUSL-1.1 (clear first) | 0.8.19 | Immutable singleton, MarketParams/Id, callbacks, flash loans, auth with nonce/sig | No port. Strong oracles in Crane (reuse + add fair-reserves LP adapter). Gap: Morpho-specific Service + IOracle adapters. | Internal libs (not Solady). Very clean for faithful port. Unblocks MetaMorpho + Alchemix. |
| **Morpho Vaults (MetaMorpho)** | morpho-org/metamorpho (src/) | MetaMorpho.sol, MetaMorphoFactory.sol + libraries/ | Ownable2Step + Multicall (likely) | Similar to Blue (inherits patterns) | Yes (ERC4626 vault layer) | Allocation/queue logic + curator | Uses Blue oracles | No | Roles (curator/allocator/guardian), adapters | No | BUSL-1.1 / GPL (clear) | 0.8.x | Curated ERC4626 over Blue markets, factory | Depends on Blue. Gap: DFPkg candidate for curated vault reference + Service for deposit/allocate/withdraw. | Do Blue first. Curator risk — expose params. |
| **Ajna (V2)** | ajna-finance/ajna-core (src/) | ERC20Pool.sol, ERC721Pool.sol, *Factories, PositionManager.sol, PoolInfoUtils.sol + base/libraries/ | IERC20, SafeERC20 (@openzeppelin) | Some base64 (for NFT), contained. Uses solmate/PRB? in older audits | No | **Oracleless** (lenders set bucket prices) | None (by design) | No | Bucket/auction mechanics, PositionManager (ERC721) | No | Low risk (review audits) | 0.8.18 (per PRD) | Peer-to-pool, permissionless pools, bond-backed auctions, LP + NFT collateral | No port. Oracleless = huge advantage for safe LP collateral (avoids Impermax class bugs). Gap: AjnaService for create/pool ops/auctions + AwareRepo. | Strong fit for "open our own markets with arbitrary LP collateral". Thin-pool liquidation speed is a modeling concern. |

## Phase 2+ (Initial / Partial)

| Protocol | Upstream (PRD) | Key Contracts | OZ Usage | Solady / Custom Safe/Math | ERC4626 | RateProvider / Exchange Rate | Oracles | Permit2 | Other Libs / Math | Vyper? | License | Solidity | Notable Patterns | Current Crane Coverage / Gaps | Notes / Specific Vendor Targets |
|----------|----------------|---------------|----------|---------------------------|---------|------------------------------|---------|---------|-------------------|--------|---------|----------|------------------|-------------------------------|---------------------------------|
| **Sky sUSDS + Spark** | sky-ecosystem / marsfoundation (sUSDS ERC4626); marsfoundation/sparklend-v1-core (Aave V3 fork) | sUSDS (4626), SparkLend Pool + PSM | Reuse existing Sky DSS + Aave patterns | Incremental | Yes (sUSDS) | Yes (savings rate via Pot-style; RateProvider needed) | Reuse Crane Aave oracles + Sky | High reuse | DSS core (Vat/Pot/Jug) already ported in Crane | No | AGPL/BUSL (verify) | 0.8.x | Spark as Aave fork delta only | **Excellent reuse**: Deep Sky DSS + Aave v3/v4 already in Crane. Gap: thin SUSDS wrapper + RateProvider + Spark-specific Service capturing deltas only. | Do after Ethena/Lido RateProvider work. Mostly incremental. |
| **Yearn V3** | yearn/yearn-vaults-v3 (Vyper VaultV3 + TokenizedStrategy) | VaultV3.vy, TokenizedStrategy.sol, RoleManager | ERC4626 base | Strategy adapters | Yes (multi-strategy) | Allocator debt management + RateProvider | Various (via strategies) | Varies | Allocator / debt allocation patterns | Yes (core vault) | AGPL | Mixed (Vyper + 0.8.x) | Tokenized multi-strategy allocator reference | Gap: interfaces + Solidity reference of allocator + DFPkg candidate. RateProvider. Vyper handling decision. | Best public reference for the tokenized multi-strategy pattern Crane consumers should emulate. |

## Phase 3 & 4 Expanded

| Protocol | Upstream (PRD) | Key Contracts | OZ Usage | Solady / Custom Safe/Math | ERC4626 | RateProvider / Exchange Rate | Oracles | Permit2 | Other Libs / Math | Vyper? | License | Solidity | Notable Patterns | Current Crane Coverage / Gaps | Notes / Specific Vendor Targets |
|----------|----------------|---------------|----------|---------------------------|---------|------------------------------|---------|---------|-------------------|--------|---------|----------|------------------|-------------------------------|---------------------------------|
| **Silo V2** | silo-finance/silo-contracts-v2 (silo-core/contracts) | Silo.sol, SiloConfig.sol, SiloFactory.sol, SiloLens, hooks, interestRateModel, lib/ (SiloMathLib, Actions, Views, SiloStdLib) | OpenZeppelin5 (SafeERC20, IERC20, Address) + ERC3156 flash | Internal math (SiloMathLib, Rounding, Hook) | Yes (full ERC4626 for collateral) | Per-silo oracles + risk params | External oracle adapters per silo | No | Isolated markets, hooks system, ERC4626 + leverage | No | BUSL-1.1 (verify) | 0.8.28 | Permissionless isolated 2-asset silos, programmable risk | No port. Gap: SiloService for deploy/deposit/borrow/liquidate + fair-reserves LP oracle. | Good third isolated-market option after Morpho/Euler. Focus on LP collateral path. |
| **Curve (core stable/crypto + gauges)** | curvefi/stableswap-ng, tricrypto-ng, curve-dao-contracts | Various factories, pools (StableSwap, Twocrypto), gauges (Vyper + some Solidity) | Varies (often minimal in core) | Custom Curve math (StableSwap, Crypto invariants) | Some pools 4626? | Rate providers for some | Internal + external oracles | No | StableSwap/Crypto invariants, gauge rewards | Yes (core) | Review (BUSL portions) | Mixed | Low-slippage correlated AMM + boosted gauges | Gap: CurveService + Solidity reference of invariants + gauge wrappers. | Shared math with LlamaLend. Start with dominant stable + one crypto. |
| **Curve LlamaLend V2** | curvefi/curve-stablecoin | AMM.vy (LLAMMA), Controller.vy, ControllerFactory.vy, LendFactory.vy, price_oracles/ | IERC20 via interfaces | Custom LLAMMA band math, crv_math, snekmate math | No | External price oracles + bands | IPriceOracle | No | Soft-liquidation bands, rate accrual | Yes (heavy) | Review (BUSL) | Vyper 0.3/0.4 | Permissionless markets, LLAMMA soft liq, range-based liquidation | Gap: LlamaLendService + LLAMMA reference + band logic. Do Curve first. | Soft-liq for graceful unwinds. Oracle + band params critical (past incidents). |
| **Convex** | convex-eth/platform (contracts/contracts) | Booster.sol, BaseRewardPool.sol, CrvDepositor.sol, RewardFactory, StashFactory, many reward/lock contracts | OZ 0.6.12 (SafeMath, SafeERC20, IERC20, Address) | Integrates Curve gauges/rewards | Wrappers for some | N/A | N/A | No | CVX boosting, extraRewards, veCRV integration | No | Review | 0.6.12 | Deposit LP → stake in Curve gauges → boosted CRV + CVX rewards | Gap: ConvexService (deposit/stake/claim/withdraw). After Curve gauges. | Reward routing + auto-compound reference. |
| **Fluid (Instadapp)** | Instadapp/fluid-contracts-public | liquidity/ (core singleton), protocols/vault (VaultFactory, vaultT1), protocols/lending (fTokens 4626), dex, oracle, libraries | Likely OZ + custom | Custom math in libraries, compact storage | Yes (fTokens ERC4626) | Central Liquidity layer + oracles | External oracles | No | Unified liquidity, smart collateral/debt vaults, operate() | No | Review | 0.8.x | Liquidity singleton + DEX + lending + vault modules | Gap: FluidService (operate, open smart vault, fToken flows). | Capital-efficient looping, module layout, contract size watch. |
| **Alchemix V3** | alchemix-finance/v3-poc or v3 | AlchemistV3.sol, Transmuter, MYT adapters | OZ + ERC4626 | Yield paying down debt | MYT wraps Morpho Vaults (ERC4626) | Transmuter peg/oracle | Peg oracles | Varies | Alchemist CDP + queued redemptions + temporal priority | No | Review | 0.8.x | Non-liquidatable leverage via self-repaying alAssets, MYT baskets | Gap: AlchemixService (mint alAsset, Transmuter queue, earmark). Do Morpho first. | MYT = DAO-curated Morpho basket. Peg via Transmuter throughput. |
| **Gearbox V3** | Gearbox-protocol/core-v3 | CreditManagerV3, CreditFacadeV3, CreditAccountV3, PoolV3 + integrations/oracles | OZ | Adapters, whitelists | N/A (credit accounts) | External oracles (via oracles-v3) | N/A | No | Credit Accounts (isolated whitelisted exec), multicall | No | BUSL-1.1 (clear first) | 0.8.x | Composable leverage via whitelisted targets (moving away from loops) | Gap: GearboxService (open credit account, multicall execution). Reference EVC patterns. | Lower priority. Principled leverage vs flashloan loops. |

## Summary of Cross-Cutting Gaps (Updated)

- **RateProvider generalization**: Ethena, Lido, Sky, Yearn, some Curve/Silo paths.
- **LP oracle (fair-reserves + TWAP)**: Morpho, Silo, LlamaLend (Ajna advantage).
- **Curve / LLAMMA math**: Curve core + LlamaLend + Convex.
- **Custom SafeTransfer/Math**: Morpho (internal), Silo (own libs), Curve Vyper.
- **BUSL clearance**: Morpho Blue/Meta, Gearbox, Curve portions, Silo (older).
- **Vyper ports**: Curve family, Yearn (interface + math ref recommended).
- **EVC / account abstraction**: Gearbox (reuse Euler), some Fluid/Silo.
- **ERC4626 modifications**: Ethena (vesting/cooldown), Fluid fTokens, Alchemix MYT, Silo.

## Recommended Phase 0 Actions (from this analysis)

1. **Generalize RateProvider** (ERC4626 + LST + custom) — unblocks Ethena #1, Lido #2, Sky, Yearn.
2. Add fair-reserves LP oracle adapter (shared by Morpho, Silo, LlamaLend).
3. Expand `external/` for any missing OZ v5 / Solady symbols surfaced above.
4. Decide Vyper strategy + start Curve math reference (for LlamaLend + Convex).
5. Clear BUSL for Morpho/Gearbox/Curve portions before Phase 1/3.
6. Map custom SafeTransfer/Math patterns (Morpho example) to Crane equivalents where possible.

## How to Maintain / Expand

- Add rows for remaining protocols by repeating the targeted-fetch process (5-10 min per protocol).
- After each port, update the "Current Crane Coverage" column.
- Link tasks: e.g. "CRANE-270: Generalize RateProvider facet".

This matrix + the PRD's Definition of Done gives a clear, dependency-grouped plan.

**Status**: Initial build (Phase 1 complete with fresh fetches; others summarized). Ready for review + expansion.