# DeFi Protocol Porting Research — Strategy Vault Enablement

**Date:** 2026-06-24
**Purpose:** Identify active DeFi protocols worth porting into Crane to facilitate strategy-vault
development by framework consumers. Prioritized against what Crane already integrates and against the
in-flight carry/loop vault work (`prds/AaveV3V4CrossVersionCarryLoopVault.md`).

---

## 1. What Crane Already Covers

Mapping current `contracts/protocols/` + skills so we don't re-port:

| Category | Already integrated |
|----------|--------------------|
| DEXes | Uniswap V2/V3/V4, Aerodrome (+Slipstream CL), Balancer V3, Camelot |
| Lending / money markets | Aave V3, Aave V4, Euler EVK/EVC, Compound V3 (Comet) |
| CDP / stablecoin | Sky / MakerDAO (Vat, Dog, Clip, Pot, Jug…) |
| Yield / PT-YT | Pendle |
| Staking / LST-ish | Liquity, Reliquary, Resupply |
| Oracles | Chainlink, Pyth, RedStone |
| Infra | Permit2, LayerZero, Gnosis Safe |

**Implication:** Crane already has strong *money-market* and *DEX* primitives. The biggest leverage for
strategy-vault builders now is (a) a **curated-vault allocation layer**, (b) **yield-bearing collateral
sources** (LSTs, synthetic-dollar stables), and (c) **leverage/credit primitives** that aren't simple
loops. These are the gaps below.

---

## 2. Top Recommendations (Ranked)

### Tier 1 — High impact, directly enables strategy vaults

#### 2.1 Morpho (Blue + Vaults / MetaMorpho) — **strongest single recommendation**
- **What:** Two-layer lending. *Morpho Blue* is a ~650-line immutable isolated-market primitive;
  *Morpho Vaults* (MetaMorpho, ERC-4626) are a curator layer that allocates deposits across Blue markets.
- **Why port:** This *is* the canonical strategy-vault pattern. Builders on Crane get (1) permissionless
  isolated markets to lever against, and (2) a battle-tested ERC-4626 curator-vault reference to model
  their own vaults on. Complements — does not duplicate — Aave/Euler/Compound.
- **Status:** ~$7B+ TVL (mid-2026), second-largest lending protocol after Aave; on Ethereum + Base
  (Base matters — Crane already targets Base via Aerodrome). 200+ markets. Institutional curators
  (Steakhouse, Gauntlet, Re7, MEV Capital).
- **Scope:** Small, auditable core (Blue). Vault layer is the higher-value but larger lift.
- **Risk note:** Curated-vault risk is *curator* risk (see Stream Finance fallout, §4).

#### 2.2 Ethena (USDe / sUSDe)
- **What:** Synthetic dollar from a delta-neutral basis trade (long LST/BTC, short perps). sUSDe is the
  ERC-4626 yield-bearing staked form. ~$5.5–6B supply (Q2 2026), largest synthetic dollar after USDS.
- **Why port:** sUSDe is one of the most-used *yield-bearing collateral* legs in carry/loop strategies and
  is widely listed on Aave/Morpho/Pendle. A first-class sUSDe wrapper + the cooldown/unstake flow lets
  vault builders compose Ethena yield directly. Directly relevant to the carry-loop vault PRD.
- **Scope:** The on-chain surface (StakedUSDe ERC-4626 + minting/cooldown) is modest; the off-chain
  hedging engine is *not* portable (and shouldn't be — integrate the token, not the desk).

#### 2.3 Fluid (Instadapp) — lending + DEX + smart collateral/debt
- **What:** Unified liquidity layer combining a money market, a DEX, and "smart collateral/smart debt"
  vaults. ~$800M+ TVL and growing; a leading venue for capital-efficient looping.
- **Why port:** Purpose-built for leveraged vaults with native looping/de-looping and shared liquidity —
  fills the "efficient leverage" gap that raw Aave/Compound loops handle clumsily.
- **Scope:** Medium. Vault + liquidity-layer interfaces.

#### 2.4 Curve + Convex — stable/correlated AMM + boosted gauge wrapper
- **What:** Curve = dominant low-slippage AMM for like-kind assets (stable/LST pools, sub-0.01% slippage).
  Convex = boost/auto-compounding layer over Curve gauges.
- **Why port:** Strategy vaults constantly need (a) cheap correlated-asset swaps for loop entry/exit and
  unwind, and (b) Curve LP + gauge yield as a strategy leg. Crane has Balancer V3 and Aerodrome but no
  Curve — a real gap for stablecoin/LST strategies. Convex gives the standard "deposit LP → boosted,
  auto-compounded rewards" vault pattern to model.
- **Scope:** Curve stable/crypto pool + gauge interfaces (medium); Convex booster/reward pool (medium).

### Tier 2 — Strong yield/collateral sources

#### 2.5 Lido (stETH / wstETH)
- **What:** Largest LST. wstETH is the non-rebasing ERC-20 used everywhere as collateral.
- **Why port:** The default ETH-yield collateral leg for leveraged staking ("ETH carry") vaults. A clean
  wstETH wrap/unwrap + rate provider is high-utility and low-complexity. Pairs naturally with the
  carry-loop vault PRD if it expands beyond stable carry to ETH staking carry.
- **Scope:** Small (wrap/unwrap, exchange-rate read). Withdrawal queue optional.

#### 2.6 Sky / Spark — sUSDS + Spark Lend / SparkLink
- **What:** Crane already has the *Maker/Sky CDP core*. Missing: the **sUSDS** ERC-4626 savings wrapper
  (~$2.4B, ~6.5% yield) and **Spark** (the Sky-aligned Aave-V3-fork money market + DAI/USDS yield routing).
- **Why port:** sUSDS is a top stablecoin yield primitive and a clean ERC-4626 to expose. Spark gives a
  second deep money market sharing liquidity with Sky. Incremental on top of existing Sky work.
- **Scope:** sUSDS small; Spark medium (but largely an Aave-V3 fork — reusable patterns from existing Aave port).

#### 2.7 Yearn V3
- **What:** Modular ERC-4626 multi-strategy vaults; "strategies" are themselves 4626 sub-vaults aggregated
  by a parent allocator. ~$300–500M TVL.
- **Why port:** Best open-source *reference architecture* for the tokenized-vault factory pattern Crane
  wants consumers to build. Even if not fully ported, the V3 allocator/strategy split is the model to
  mirror in Crane's vault DFPkgs.
- **Scope:** Medium. Consider porting interfaces + the strategy/allocator pattern rather than the whole stack.

### Tier 3 — Specialized / opportunistic

#### 2.8 Gearbox V3 — composable leverage / Credit Accounts
- **What:** Credit Accounts = isolated contracts holding user+borrowed funds with whitelisted tokens/
  protocols. Note: Gearbox is **explicitly moving away from looping** toward native execution composability
  (2026), so port the V3 Credit Account model, not the legacy loop flows.
- **Why port:** A more principled leverage primitive than DEX-flashloan loops — interesting reference for
  Crane's vault leverage layer. Lower priority than Morpho/Fluid.

#### 2.9 Silo V2 — permissionless isolated-market lending — **LP-collateral / own-market candidate**
- **What:** Per-asset isolated lending markets (risk-contained). Active V2. Markets ("silos") are deployable
  permissionlessly, each a two-asset isolated pair with its own oracle and risk params.
- **Why port:** A clean **permissionless market-creation** venue that fits the "open our own lending markets"
  goal. Can take LP tokens as collateral given a manipulation-resistant LP oracle (see §5). Overlaps
  conceptually with Morpho Blue + Euler — port if you want a third isolated-market option or its specific
  two-asset silo model.
- **Scope:** Medium. Oracle adapter for LP collateral is the real work (shared with Morpho/Euler/LlamaLend).

#### 2.10 EigenLayer (restaking) — watch / optional
- **What:** Restaking layer (~$17B TVL) turning staked ETH/LSTs into AVS security collateral.
- **Why (not yet):** Powerful but the yield is operator/AVS-dependent and slashing-exposed; integration
  surface is large and still maturing. Track as a future LRT-collateral source rather than a near-term port.

#### 2.11 Alchemix (V3) — self-repaying loans / synthetic debt
- **What:** "Self-repaying loan" CDP. Users deposit ETH/USDC, the deposit is wrapped into a DAO-curated
  **Mix-Yield Token (MYT)** — a basket of yield strategies built on **Morpho Vaults V2** (customized
  ERC-4626) — and borrow synthetic debt (**alUSD / alETH**) up to ~90% LTV at 0% interest. Yield on the
  collateral automatically pays the debt down; there are **no price-triggered liquidations** as long as the
  vault stays solvent.
- **V3 architecture (four layers):** (1) vaults convert base deposits → MYT; (2) the **Alchemist** contract
  issues alAssets against MYT collateral; (3) a revamped **Transmuter** handles 1:1 fixed-duration
  redemptions (e.g. 30/60/90-day queues) and peg support; (4) a support layer adds "earmarking,"
  time-weighted queues, and "temporal priority." Notably, collateral keeps earning yield on the *full*
  original amount until a redemption actually settles ("temporal advantage").
- **Why port:** Highly relevant to Crane's strategy-vault thesis on two fronts. First, alUSD/alETH are a
  **non-liquidatable leverage primitive** — a fundamentally different (and safer-by-design) way to get
  leverage than the carry/loop approach in the PRD, with no liquidation cascade risk. Second, Alchemix V3 is
  *itself* a curated multi-strategy vault system (MYT on Morpho Vaults V2), so it both **composes with a
  Morpho port** (§2.1) and serves as a concrete reference for a DAO-curated, rebalanced strategy basket.
  The Transmuter's queued-redemption + temporal-priority mechanics are a useful pattern for any vault that
  needs orderly, peg-preserving exits.
- **Status:** V3 is the current line (major 2026 upgrade; ALCX rallied ~200% on the launch). Multiple
  top-firm audits + active Immunefi bug bounty. Built on Morpho Vaults V2.
- **Scope:** Medium. The Alchemist CDP + Transmuter are the core surface to port; the MYT layer is largely a
  Morpho Vaults V2 wrapper (so do §2.1 first). The off-chain DAO curation of strategy weights is governance,
  not a portable contract.
- **Risk note:** Solvency depends on the underlying MYT strategies performing — bad-debt risk shifts from
  liquidation to **strategy/curator risk** (same family as the Morpho/curator and Stream Finance concerns in §4).
  Synthetic-asset peg depends on Transmuter throughput.

#### 2.12 Impermax (V3) — permissionless leveraged LP / yield farming — **⚠ exploited, see verdict**
- **What:** Permissionless leveraged yield farming. Lenders supply single tokens; borrowers post **LP
  tokens as collateral** to borrow and lever up their LP/farming position (up to ~20x). Isolated,
  permissionless lending pools per LP pair. Governance token IBEX (formerly IMX).
- **Why it was on the radar for vault builders:** LP-collateralized leverage is a useful strategy-vault
  primitive (lever a Uniswap/Aerodrome LP position). But see the verdict — the V3 design has a demonstrated
  collateral-valuation flaw that is core to its leverage model, not a peripheral bug.

##### Is it still active?
**Yes, but barely.** As of mid-2026 Impermax is still deployed (Ethereum, Polygon, Arbitrum, Avalanche,
Base, Sonic) and the front-end/contracts operate, but it is **economically marginal**: ~$728K TVL and a
~$150K token market cap (down enormously from its peak). Treat it as a *surviving* but not *thriving*
protocol — low liquidity is itself a risk multiplier for the exact attack class that hit it.

##### The hack (root cause — what we'd have to fix to fork/relaunch)
- **When / size:** ~April 27–28, 2025. ~$300K stolen directly; ~$400K total estimated loss. Hit the
  **Impermax V3** Base deployment (exploit tx `0x14ea5b...3ed77`).
- **Class:** Flash-loan-funded **collateral over-valuation** of Uniswap-V3-style LP positions, combined with
  a **reinvest-at-manipulated-tick** self-liquidation. Three compounding flaws:
  1. **Inconsistent fee valuation (the core bug).** The collateral valuation counted **uncollected**
     Uniswap V3 fees at *full face value*, while **auto-compounded** fees were subject to a `safetyMargin`
     ratio adjustment. So pending/uncollected fees were valued more favorably than the same fees once
     compounded — a discrepancy the borrower controls.
  2. **Manipulable fee generation.** In a **low-liquidity** pool the attacker pushed the tick to an extreme,
     ran ~50 wash swaps to accumulate large one-sided **uncollected fees**, and borrowed against that
     inflated collateral value.
  3. **`reinvest` mints liquidity at the wrong tick.** The auto-compound/`reinvest` path reinvested the
     accrued fees using the **manipulated (spot) tick** rather than a validated/TWAP tick. When price
     normalized, the position suffered large impermanent loss and went underwater; the attacker then used
     **`restructureBadDebt`** to socialize the resulting bad debt onto lenders instead of being liquidated.
- **Attack flow:** flash loan (Balancer/Morpho) → create LP collateral in a thin Uni V3 pool → manipulate
  tick + wash-swap to inflate uncollected fees → borrow against inflated collateral → `reinvest` compounds
  at the bad tick → push price back, position goes underwater → `restructureBadDebt` dilutes lenders →
  repay flash loan, keep the spread.

##### Verdict for our fork/fix goal
**Do not treat current Impermax as a "safe to integrate" dependency**, and **a fork is feasible but
non-trivial** — the flaw is in the heart of the leverage/valuation logic, not a one-line slip. To relaunch
safely a fork would need to fix all three layers:
- **Valuation:** value collateral (incl. fees) from a **manipulation-resistant oracle / TWAP**, never raw
  spot pool state; value **uncollected fees consistently** with compounded fees (apply the same
  `safetyMargin` discount, or **exclude uncollected fees from borrowable collateral entirely**).
- **`reinvest`:** mint compounded liquidity at a **TWAP-validated tick** with a deviation guard; reject
  reinvest when spot deviates from TWAP beyond a threshold (defeats the thin-pool tick manipulation).
- **`restructureBadDebt`:** add TWAP/health-check guards and prevent a position from being created,
  inflated, and bad-debt-restructured **atomically by the same actor** (block same-block create→exploit).
- **Operational:** enforce minimum-liquidity / whitelisted-pool requirements so thin pools can't be used as
  the manipulation venue; full re-audit before mainnet.

**Recommendation:** If LP-collateralized leverage is wanted, prefer building it on Crane's existing,
better-audited money markets (Aave/Euler/Morpho) with oracle-priced collateral, rather than forking
Impermax V3. Only pursue an Impermax fork if its specific permissionless-per-pair leverage model is a hard
requirement — and if so, the three fixes above are the minimum bar. Lower priority than every Tier 1–2 item.

#### 2.13 Ajna — oracleless, permissionless, governance-free lending — **best fit for LP-collateral own-markets**
- **What:** Peer-to-pool lending with **no oracles and no governance**. Anyone permissionlessly creates a
  pool for any pair; **lenders set the price** ("bring your own oracle") by depositing quote token into
  price buckets. Accepts almost any tokenized collateral — fungible (incl. **LP tokens**) and NFT. Loans are
  perpetual with a utilization-based variable rate; liquidations are bond-backed auctions. The contracts are
  immutable.
- **Why port:** Uniquely aligned with the stated goal — *open our own lending markets that accept LP tokens*.
  Because there is **no price feed**, the entire Impermax/Cheese-Bank/Warp class of LP-oracle-manipulation
  bugs **cannot exist** — the protocol can't be tricked by a price it never reads. Removes the single
  hardest, most dangerous piece of LP-collateral lending (a safe LP oracle).
- **Status:** Ajna V2 live and broadly deployed (Ethereum, Base, Arbitrum, OP, Polygon, Avalanche, BSC,
  Blast, Linea, Mode, Filecoin, and more). Immutable, no-governance design.
- **Scope:** Medium. Pool factory + bucket/auction mechanics. The tradeoff vs oracle markets: lenders must
  actively choose prices, and per-pool liquidity is lender-driven — model this in any vault that lends into Ajna.
- **Risk note:** Risk moves from oracle-manipulation to **lender mispricing / liquidity** — a lender who sets
  a bad bucket price can be arbitraged. No protocol-level bad-debt socialization, but thin pools liquidate slowly.

#### 2.14 Curve LlamaLend (V2) — permissionless markets + soft liquidation — **LP-collateral / own-market candidate**
- **What:** Curve's isolated lending. **Permissionless market creation** (factory: pick the pair, oracle,
  LLAMMA + IRM params). Borrow/lend crvUSD originally; **LlamaLend V2 (launched 2026-06-10)** generalizes to
  arbitrary isolated markets with range-based liquidation by default.
- **Why port:** The **LLAMMA soft-liquidation** model is the standout feature for protecting vaults from
  severe price moves — instead of one catastrophic liquidation, collateral is *gradually* converted across
  price bands as price falls (and converted back if it recovers). That continuous de-risking is much closer
  to the "graceful unwind under stress" behavior you were reaching for than a hard-liquidation design. Can
  take LP collateral given an oracle.
- **Status:** Active; V2 generalized markets live since 2026-06-10. **Note:** a 2026-03-02 flash-loan exploit
  hard-liquidated 27 borrowers on the sDOLA/crvUSD market (~$10.9M) — oracle/market-config risk persists, so
  any ported market needs careful oracle + LLAMMA parameterization (see §5).
- **Scope:** Medium–large. LLAMMA AMM-liquidation logic is the non-trivial part; reuses Crane's Curve work if §2.4 is done.
- **Risk note:** Soft liquidation reduces *but does not remove* bad-debt risk; oracle quality + band params
  are the safety-critical knobs (see the sDOLA incident).

---

## 3. Suggested Porting Order

1. **Morpho Blue + a minimal MetaMorpho/ERC-4626 vault reference** — the keystone for strategy vaults.
2. **Ethena sUSDe wrapper** + **Lido wstETH wrapper** — the two highest-use yield-bearing collateral legs;
   both small and directly feed the carry/loop vault PRD.
3. **Curve stable/crypto pool + gauge** (then **Convex** booster) — fills the correlated-AMM + boosted-yield gap.
4. **Fluid** — efficient native leverage venue.
5. **sUSDS + Spark** — extends existing Sky work.
6. **Yearn V3** pattern/interfaces — adopt as the vault-architecture reference.
7. **Alchemix V3** — non-liquidatable synthetic-debt leverage; composes with the Morpho port (do §2.1 first)
   and offers an alternative, liquidation-free leverage path for the carry-vault use case.
8. **LP-collateral / permissionless-market workstream** (see §5) — enables "accept LP tokens + open our own
   markets." Recommended sequence:
   a. **Euler EVK** — *already in the repo*; build a permissionless LP-collateral vault here first to validate
      the approach with zero new ports.
   b. **Ajna** — oracleless, permissionless; the safest way to take arbitrary LP collateral (no LP oracle to exploit).
   c. **Morpho Blue** — folds into item 1 above; permissionless isolated markets with an LP oracle.
   d. **Curve LlamaLend (V2)** — adds soft-liquidation (LLAMMA) for graceful unwinds under stress.
   e. **Silo V2** — third isolated-market option if a specific two-asset silo model is needed.
9. Opportunistic: **Gearbox V3**; **EigenLayer** on the watchlist.

---

## 4. Risk / Due-Diligence Notes for Vault Builders

- **Looping yield bubble (Stream Finance collapse).** The collapse of Stream Finance's xUSD exposed
  systemic risk in recursive "looping yield" — multiple major protocols (Morpho, Euler, Silo, Gearbox) had
  accepted xUSD as collateral. Any Crane carry/loop vault must enforce conservative LTV/oracle/collateral
  whitelisting and avoid circular collateral. This is a *design constraint*, not just a footnote.
- **Curator risk** (Morpho/Yearn vaults): depositor returns depend on a curator's allocation decisions —
  expose curator/oracle/market parameters transparently in any wrapper.
- **Synthetic-dollar peg & funding risk** (Ethena): sUSDe yield is funding-rate dependent and can go
  negative; cooldown windows affect liquidity. Model unstake delays in vault accounting.
- **Oracle dependence:** every leveraged strategy is only as safe as its price feeds — reuse Crane's
  existing Chainlink/Pyth/RedStone integrations; prefer market-native oracles where the venue provides them.

---

## 5. LP-Collateral & Permissionless-Market Options (own-markets workstream)

**Goal:** a lending layer that (a) accepts **LP tokens as collateral** and (b) lets us **open new lending
markets permissionlessly** as needed. The decisive design axis is **how the LP token is priced**, because the
LP-valuation oracle is the single most dangerous component (it is the root of the Impermax §2.12, Cheese Bank,
and Warp exploits). Two families:

### Oracle-based (you must supply a manipulation-resistant LP oracle)
| Option | Permissionless markets | LP collateral | Notable | Repo status |
|--------|------------------------|---------------|---------|-------------|
| **Euler EVK** (§ existing) | ✅ deploy any vault, set LTVs | ✅ via oracle adapter | Modular Euler Router oracle | **Already in repo — build today** |
| **Morpho Blue** (§2.1) | ✅ market = (loan, collateral, oracle, IRM, LLTV) | ✅ via oracle | Largest ecosystem + curator vaults | On roadmap |
| **Curve LlamaLend V2** (§2.14) | ✅ factory | ✅ via oracle | **LLAMMA soft liquidation** (graceful unwind) | New |
| **Silo V2** (§2.9) | ✅ deploy silos | ✅ via oracle | Two-asset isolated silos | New |

For all of these the **LP oracle is the real engineering work**: value the LP from its invariant + **TWAP
prices of the underlying tokens** (fair-reserves pricing), never from spot reserves. Uniswap **V2** LP tokens
are tractable (fungible; the fair-reserves formula `2·√(r0·r1)·√(p0·p1)/totalSupply` is well established);
Uniswap **V3 / concentrated** positions are NFTs and much harder — prefer V2-style LP collateral first.

### Oracleless (no LP oracle to exploit)
| Option | Permissionless markets | LP collateral | Notable | Repo status |
|--------|------------------------|---------------|---------|-------------|
| **Ajna** (§2.13) | ✅ anyone, no governance | ✅ any ERC-20/NFT | **No oracle** — lenders price; immutable | New |

### Recommendation
1. **Validate on Euler EVK now** — it's already ported, so a permissionless LP-collateral vault + a
   fair-reserves V2-LP oracle adapter proves the concept with no new dependency.
2. **Add Ajna** for the oracleless path — structurally immune to the LP-oracle manipulation that killed
   Impermax; the cleanest way to accept *arbitrary* LP collateral in *self-created* markets.
3. **Morpho Blue** (already item 1 of §3) for the deepest oracle-based ecosystem; **LlamaLend V2** when you
   want soft-liquidation behavior; **Silo V2** as a third isolated-market option.
4. **Do not** fork Impermax/Tarot for this — Euler + Ajna + Morpho deliver "LP collateral + own markets"
   without inheriting its valuation bug.

---

## 6. Sources

- [Morpho Protocol Explained 2026 — Eco](https://eco.com/support/en/articles/13064566-morpho-protocol-explained-2026)
- [Morpho TVL, Fees & Revenue — DefiLlama](https://defillama.com/protocol/morpho)
- [Morpho Blue TVL — DefiLlama](https://defillama.com/protocol/morpho-blue)
- [Morpho's DeFi Lending Innovations: Blue & MetaMorpho — Bitget](https://www.bitget.com/academy/morpho-defi-lending)
- [Best DeFi Lending Protocols 2026 — Eco](https://eco.com/support/en/articles/14800882-best-defi-lending-protocols-2026-tvl-rates-risk)
- [The Complete Guide to DeFi Vaults in 2026 — DeFiPrime](https://defiprime.com/defi-vaults-guide)
- [Best Yield Aggregator in 2026 — Crawlux](https://www.crawlux.com/blog/best-yield-aggregator/)
- [ERC-4626 Tokenized Vault Standard Explained — Eco](https://eco.com/support/en/articles/14796361-erc-4626-tokenized-vault-standard-explained)
- [The End of Looping on Gearbox — Gearbox blog](https://blog.gearbox.finance/the-end-of-looping-on-gearbox/)
- [How it works — Gearbox docs](https://docs.gearbox.finance/overview/how-it-works)
- [Gearbox TVL — DefiLlama](https://defillama.com/protocol/gearbox)
- [Silo V2 TVL — DefiLlama](https://defillama.com/protocol/silo-v2)
- [How Stream Finance's Collapse Exposed DeFi's Looping Yield Bubble — The Defiant](https://thedefiant.io/news/defi/how-stream-finance-s-collapse-exposed-defi-s-looping-yield-bubble)
- [Ethena USDe and sUSDe 2026: Delta-Neutral Yield — Eco](https://eco.com/support/en/articles/15254002-ethena-usde-and-susde-2026-delta-neutral-yield)
- [Ethena USDe TVL — DefiLlama](https://defillama.com/protocol/ethena-usde)
- [The 2026 DeFi Yield Map — Crypto Daily](https://cryptodaily.co.uk/2026/05/the-2026-defi-yield-map-where-returns-now-come-from)
- [What Are the Top DeFi Protocols? 2026 Guide — Token Metrics](https://blog.tokenmetrics.com/p/what-are-the-top-defi-protocols-complete-2026-guide-to-decentralized-finance)
- [Alchemix — Self-Repaying DeFi Loans (official)](https://alchemix.fi/)
- [Introducing Alchemix v3 — Alchemix Finance (Medium)](https://alchemixfi.medium.com/introducing-alchemix-v3-d55f86d35b49)
- [Alchemix v3 — Alea Research](https://alearesearch.io/reports/perspectives/alchemix-v3)
- [Alchemix v3 Introduces Self-Repaying Loans With Fixed-Maturity DeFi Model — TokenPost](https://tokenpost.com/news/technology/20693)
- [Transmuter — Alchemix User Docs](https://docs.alchemix.fi/alchemix-ecosystem/transmuter)
- [alchemist-contract — Alchemix Docs](https://keenanlukeom.github.io/alchemix-v3-docs/dev/alchemist/alchemist-contract/)
- [Impermax Finance — official site](https://www.impermax.finance/)
- [Impermax Finance TVL — DefiLlama](https://defillama.com/protocol/impermax-finance)
- [Impermax V3 TVL — DefiLlama](https://defillama.com/protocol/impermax-v3)
- [Impermax V3 Exploit: Post Mortem — Impermax (Medium)](https://impermax.medium.com/impermax-v3-exploit-post-mortem-6b0818897b25)
- [Inside the Impermax V3 Hack — Verichains](https://blog.verichains.io/p/inside-the-impermax-v3-hack)
- [How Impermax V3 Lost $300k in a Flashloan Attack — QuillAudits](https://www.quillaudits.com/blog/hack-analysis/how-impermax-v3-lost-300k-in-flashloan-attack)
- [Apr 2025 — Impermax V3 Flash Loan Fee Valuation Flaw Exploited — Quadriga Initiative](https://quadrigainitiative.com/casestudy/impermaxfinancev3flashloanfeevaluationflawexploited.php)
- [Ajna Labs — official site](https://www.ajna.finance/)
- [Ajna V2 TVL — DefiLlama](https://defillama.com/protocol/ajna-v2)
- [Ajna Finance: DeFi Without Oracles — StableLab](https://stablelab.xyz/blog/ajna-finance-defi-without-oracles)
- [Modern DeFi Lending Protocols: Ajna — MixBytes](https://mixbytes.io/blog/modern-defi-lending-protocols-how-its-made-ajna)
- [Curve LlamaLend TVL — DefiLlama](https://defillama.com/protocol/curve-llamalend)
- [Introducing Llamalend v2 — Curve](https://news.curve.finance/introducing-llamalend-v2/)
- [Curve Lending: Overview — Curve Docs](https://docs.curve.finance/lending/overview/)
- [Modern DeFi Lending Protocols: Curve LlamaLend — MixBytes](https://mixbytes.io/blog/modern-defi-lending-protocols-how-its-made-curve-llamalend)
- [LlamaLend sDOLA-long2 Post-mortem — Curve Governance](https://gov.curve.finance/t/llamalend-sdola-long2-post-mortem/11020)
