# DeFi Protocol Porting Prioritization

**Date:** 2026-06-25  
**Context:** Follow-up to `DEFI_RESEARCH.md`. Goal: port as many high-value DeFi protocols into Crane as efficiently as possible.  
**Prioritization criteria (in order):**  
1. **Small core code surface** (few contracts, low LoC, minimal periphery needed for useful integration).  
2. **Shared / common dependencies** — porting once (especially OZ pieces, math, oracles, rate providers, Permit2 patterns) prepares *multiple* future ports.  
3. **Leverage of existing Crane ports** (Sky core, Aave ports, Uniswap libs, Balancer patterns, Permit2 aware layer, etc.).  
4. **Strategy-vault enablement + collateral / leverage utility** (per original research).  
5. **Low additional complexity/risk** (immutable preferred; avoid known core bugs unless the fix is the deliverable).  
6. **Prep multiplier / dependency graph position** — items that unblock clusters go higher.

We favor *Crane-style* ports (interfaces + key impls + `*AwareRepo` + `*Service` (or full Facet-Target-Repo where high-value like Balancer) + TestBase + DFPkg where it fits the Diamond factory model) over blind full copies.

---

## Summary Ranked List

| Rank | Protocol | Est. Core Surface | Key Shared Deps / Prep Value | Why This Position (Small + Prep + Impact) | Recommended Scope | Notes / Risks |
|------|----------|-------------------|------------------------------|-------------------------------------------|-------------------|---------------|
| 1 | Ethena (USDe + sUSDe / StakedUSDeV2) | **Tiny** (5-8 contracts: USDe, EthenaMinting, StakedUSDeV2, Silo, access control, rate providers) | OZ (ERC20Burnable/Permit/Ownable2Step), simple ERC4626 yield | Smallest real surface. Pure high-use yield-bearing collateral leg. Directly feeds carry/loop vaults. Heavy standard OZ = prep for everything else. | Wrapper + mint/redeem flow + StakedUSDe ERC4626 + cooldown model + rate provider. Service helpers. | Off-chain hedging not portable (and shouldn't be). Peg/funding risk (document). |
| 2 | Lido (wstETH) | **Tiny** (wstETH wrapper + rate/read functions) | OZ, rate provider patterns (already have some in Balancer) | Thinnest possible high-utility collateral. Default ETH-yield leg for staking carry strategies. Wrapper-only port. | WstETH wrap/unwrap + exchange rate + optional withdrawal queue interface. RateProvider facet example. | Full Lido DAO is larger; we only need the token + rate surface for vaults. |
| 3 | Morpho Blue | **Very small** (~650 LoC core, 1 main contract + small libs/interfaces) | Minimal (mostly custom + light OZ/Solady). Oracles separate. | The canonical small immutable isolated-market primitive. Permissionless markets. *The* reference for strategy vaults per research. Unblocks Alchemix. | Core Morpho (market creation, supply/borrow/liquidate), IOracle adapters (reuse existing), basic oracle examples. Service + aware if needed. | Immutable = easy to port. Curator risk lives in vaults layer. |
| 4 | Morpho Vaults (MetaMorpho / Vault V2) | **Small** (Factory + MetaMorpho ERC4626 + allocator/roles/adapters) | Same as Blue + ERC4626 + Ownable/Multicall patterns | The "curated vault" pattern itself. Battle-tested reference for Crane consumers building their own vaults. Small on top of Blue. | Factory + vault + allocation logic + roles (curator/guardian) + adapters. DFPkg example? | Curator risk (expose parameters transparently). Do Blue first. |
| 5 | Ajna (V2) | **Small** (PoolFactory x2, Pool x2, PositionManager, PoolInfoUtils + base/libs) | Minimal external; immutable design. Some base64 for NFT but contained. | Oracleless + permissionless + no governance. Structurally immune to LP-oracle manipulation bugs (Impermax class). Perfect for "accept arbitrary LP collateral + open own markets". | Core pool + factory + position/bucket mechanics + liquidation auctions. No oracle surface. | Lenders price buckets (model active liquidity in vaults). Thin-pool liquidation speed is a risk parameter. |
| 6 | Sky sUSDS + Spark | **Small incremental** (sUSDS ERC4626) + **Medium reuse** (Spark = Aave V3 fork) | Existing Sky DSS core (already ported), Aave patterns (deep v3/v4 ports) | Leverages massive existing work. sUSDS = top stable yield primitive (~2.4B). Spark = aligned second money market. | sUSDS wrapper (like wstETH). SparkLend interfaces + key differences from Aave. Reuse Aave test harness where possible. | Mostly incremental. Reuse > full re-port. |
| 7 | Yearn V3 (Allocator / multi-strategy pattern) | **Small-medium** (Vault allocator + strategy base; many strategies are external 4626) | ERC4626, debt management patterns | Best public reference architecture for the tokenized multi-strategy vault pattern Crane wants consumers to emulate. Even partial port teaches the allocator/strategy split. | Core VaultV3 allocator + strategy interface + RoleManager/factory patterns. Example adapters. Not every strategy. | Vyper in places historically; focus on interface + reference impl. |
| 8 | Silo V2 | **Medium** (isolated silo markets, factory, oracle + risk per silo) | Oracles (can reuse Crane adapters), LP oracle work (shared with others) | Permissionless isolated markets (like Morpho). Clean two-asset silo model. Good third option for "own markets". LP collateral possible with fair-reserves oracle. | Factory + silo pair + risk params + oracle adapter surface. Focus on LP-collateral oracle path. | Oracle quality critical (shared concern with Morpho/Euler). |
| 9 | Curve (core stable/crypto + gauges) | **Medium** (pool math + factory variants + gauge system) | Preps LlamaLend + Convex + many stable/LST strategies. Math patterns similar to Balancer/ConstProd. | Fills the "cheap correlated-asset swaps + boosted gauge yield" gap. No Curve in Crane today despite Balancer. High utility for loop entry/exit. | Core StableSwap + Crypto pools (NG if relevant) + gauge interfaces + deposit/withdraw. Utils for quotes. | Multiple pool versions increase surface; start with dominant stable + one crypto. |
| 10 | Curve LlamaLend V2 | **Medium+** (on top of Curve + LLAMMA soft-liq AMM + lending market factory) | Curve (above) + oracle work | Soft liquidation (LLAMMA) = graceful unwind under stress (highly desirable for vaults vs hard liquidation). Permissionless markets. | LLAMMA + market factory + soft-liq logic + oracle. | Oracle + band parameterization is safety-critical (past incident). Do Curve first. |
| 11 | Convex | **Medium** (booster + reward pools on Curve gauges) | Curve gauges | Standard "deposit LP → auto-compounded boosted rewards" pattern. Reference for gauge wrapper vaults. | Booster + base reward pool + staking/claim flows. | After Curve gauges. Mostly reward routing. |
| 12 | Fluid (Instadapp) | **Medium** (central Liquidity layer singleton + lending fTokens (4626) + DEX + smart collateral/debt vaults) | Unified liquidity; some overlap with existing DEX/lending patterns | Purpose-built for capital-efficient looping / native smart collateral & debt. Fills "efficient leverage" gap that raw Aave loops handle clumsily. | Liquidity core + fToken lending + key DEX/vault primitives. | Newer architecture; watch contract sizes and proxy patterns. |
| 13 | Alchemix V3 | **Medium** (Alchemist, Transmuter, MYT adapters, ~5k LoC / ~39 files in audit scope) | **Morpho** (MYT on Morpho Vaults) + ERC4626 | Non-liquidatable leverage via self-repaying synthetic debt (fundamentally different from carry/loop). Also a DAO-curated multi-strategy basket (MYT) reference. | Alchemist CDP + Transmuter queued redemption + temporal priority. MYT as Morpho adapter. | Do Morpho first. Strategy/curator risk shifts to underlying MYT (same family as Morpho vaults). Peg depends on Transmuter. |
| 14 | Gearbox V3 | **Medium** (Credit Accounts = isolated whitelisted execution contexts) | EVC-like patterns (Crane has Euler EVC) | More principled composable leverage than flashloan loops. Moving away from legacy looping. | Credit Account model + whitelisting + execution. | Lower priority than above. Reference for vault leverage layer. |
| — | EigenLayer | **Large** (restaking, operators, AVS, slashing, strategy registry, etc.) | Many oracle + staking integrations | Powerful but yield is operator/AVS dependent + slashing exposed. Large surface. | Watch only for now. Track as future LRT collateral source. | Not near-term. |
| — | Impermax V3 | Medium but **avoid as-is** | LP collateral patterns | Demonstrated core collateral valuation flaw (uncollected fees + thin-pool tick manipulation + bad-debt socialization). | Do not port current design. | If LP-collateral leverage required, build on Crane's audited markets (Euler/Ajna/Morpho) + proper TWAP oracle instead. |

---

## Phased Execution Order (Efficiency Focus)

**Phase 0 — Foundations (if any OZ/Solady gaps remain from Aave work)**
- Expand `contracts/external/` for any missing v5 pieces, AccessManager, specific Permit/ERC4626 variants, Solady EIP712/LibBit, etc. This single investment unblocks **almost every item above**.

**Phase 1 — Smallest + Highest Prep Multiplier (do these first)**
1. Ethena sUSDe
2. Lido wstETH
3. Morpho Blue
4. Morpho Vaults (MetaMorpho)
5. Ajna

**Rationale:** These have the smallest surfaces. Ethena + Lido + Morpho vaults give immediate high-use collateral + the vault reference. Ajna gives unique oracleless capability. All benefit from (and exercise) standard OZ/ERC4626/rate provider work.

**Phase 2 — Leverage Existing Ports**
6. Sky sUSDS + Spark (Sky core + Aave reuse)
7. Yearn V3 allocator pattern (teaches the multi-strategy model)

**Phase 3 — Correlated Assets + Gauge Yield**
8. Silo V2 (permissionless option)
9-11. Curve core + LlamaLend + Convex (biggest "missing primitive" for stables/LSTs)

**Phase 4 — Specialized Leverage / Dependent**
12. Fluid
13. Alchemix V3 (post-Morpho)
14. Gearbox

---

## Dependency Graph (High Level)

```
OZ expansions / ERC4626 / RateProvider patterns
├── Ethena sUSDe
├── Lido wstETH
├── Morpho Vaults
├── Yearn V3
├── Sky sUSDS
│
Morpho Blue ──► Alchemix V3 (via MYT)
│
Ajna (oracleless) ──► Safe LP collateral vaults (with Euler/Morpho)
│
Curve pools + gauges ──► LlamaLend ──► Convex
│
Aave ports ──► Spark
│
Existing Uniswap oracles / EVC ──► Gearbox, Silo oracles, etc.
```

Porting any "leaf" that also brings a shared leaf (OZ, Curve math, Morpho) multiplies future speed.

---

## Port Scope Recommendations (Crane Style)

- **Wrappers / yield tokens** (Ethena sUSDe, Lido wstETH, sUSDS): Thin `*AwareRepo` or simple library + rate provider facet + test base. Minimal code.
- **Primitives** (Morpho Blue, Ajna, Silo): Core contracts + interfaces + Service layer for common operations (supply/borrow/liquidate/create market) + oracle adapter examples.
- **Vault/allocator patterns** (MetaMorpho, Yearn V3): Full enough to serve as *reference* + DFPkg if it fits Diamond model.
- **Larger systems** (Fluid, Curve family, Alchemix): Prioritize the novel pieces (Liquidity layer, LLAMMA soft liq, Transmuter queues) + integration surface. Use stubs/comparators heavily in tests.
- Always add: TestBase (or fork TestBase), Behavior validation where interfaces matter, and example usage in CraneTest descendants.

Avoid porting full test/periphery/CLI/deployer trees unless they contain security-critical logic we want locally.

---

## Risks & Due Diligence Reminders (from DEFI_RESEARCH)

- Curator risk (Morpho/Yearn/Alchemix MYT): expose allocation params.
- Synthetic peg & funding (Ethena): model cooldowns and negative yield scenarios.
- Oracle dependence everywhere: reuse Chainlink/Pyth/Redstone + market-native where available. For LP collateral, prefer fair-reserves + TWAP (never spot) or oracleless (Ajna).
- Looping yield systemic risk (Stream Finance precedent): conservative LTVs, no circular collateral.
- Past incidents (LlamaLend sDOLA, Impermax): parameterize carefully; prefer audited parameter sets in examples.

---

## Sources & Verification Notes

Drawn from:
- `DEFI_RESEARCH.md` (original ranking + TVL/rationale)
- Public GitHub trees and audit scopes (Morpho Blue ~tiny, MetaMorpho small, Ethena handful of contracts, Ajna focused pool set, Alchemix V3 ~5k LoC audit scope, Lido wrapper thin, Fluid multi-protocol on liquidity layer, etc.)
- Crane existing ports (Sky, Aave, Euler, Balancer patterns, Uniswap libs, Permit2) for leverage assessment.
- Protocol docs and post-mortems referenced in the research doc.

This list is ordered for **maximum ports per engineering hour** while hitting the highest-leverage items for strategy-vault builders.

---

## Suggested Next Actions

1. Pick Phase 1 #1 (Ethena) or #3 (Morpho Blue) as a pilot — both tiny and high signal.
2. While porting, capture any missing canonical pieces into `contracts/external/` (one-time prep win).
3. After 2-3 small ports, re-evaluate the Curve cluster vs. incremental Sky/Spark.
4. For LP-collateral workstream: prototype on existing Euler first (zero new port), then Ajna.

Update this file as ports complete (add status columns, actual file counts from the port, lessons learned).