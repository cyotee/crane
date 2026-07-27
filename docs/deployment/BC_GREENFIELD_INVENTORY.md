# BC greenfield inventory (phased)

New Create3Factory root (idempotent bytecode). No diamondCut. Old Crane addresses abandoned.  
Each phase: deploy → manifest → `BC_TESTNET`/docs → **X announcement**.

**Always bind (never deploy):** BC SafeHarbor/Attack infra, WETH, Uni V3, BC test tokens, BC Chainlink mocks, **BC Euler mocks, BC Venus, BC Morpho**, Safe, etc. — full list in [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md).

**PRD (what to deploy):** [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md) — all phases 1–13; fixed scripts; no live BC until scripts + **X drafts** ready  
**Deploy research:** [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md)  
**Implementation plan (scripts compile):** [`../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md`](../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md)  
**All phase deploy steps:** [`BC_GREENFIELD_PHASE_DEPLOY_STEPS.md`](./BC_GREENFIELD_PHASE_DEPLOY_STEPS.md)  
**Aave V4 deep dive:** [`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md)  
**Operator commands:** [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md)  
**X post drafts (pre-deploy gate):** [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md)  
**Checklist:** [`BC_GREENFIELD_MASTER_PLAN.md`](./BC_GREENFIELD_MASTER_PLAN.md)

---

## Phase 1 — Crane factory system

- Create3Factory + DiamondPackageCallBackFactory  
- ERC20 / ERC5267 / ERC2612 facets + ERC20PermitDFPkg (+ optional sample token)  
- Uni V2 Factory + Router02  
- Uni V4 PoolManager  
- BetterPermit2  
- Safe Harbor agreement (new salt, scope = Create3Factory, ChildContractScope.All)  
- requestAttackMode  

**X:** Crane factories + core stubs live on BattleChain.

---

## Phase 2 — Balancer V3

- Vault facets + VaultDFPkg + **TimelockAuthorizer** + ProtocolFeeController + Vault  
- Router facets + RouterDFPkg + Router  
- Weighted / Stable / ConstProd packages  
- Gyro 2-CLP + E-CLP packages  
- LBP package  
- CoW pool + CoW router packages  
- ReClamm  

**X:** Balancer V3 (vault, routers, TimelockAuthorizer, all pool types) ready on BattleChain.

---

## Phase 3 — Aave

- Aave V3 (as ported: Pool / providers / config surfaces needed for dependents)  
- Aave V4 Hub/Spoke when ready  

**X:** Aave on BattleChain.

---

## Phase 4 — Euler

- **Bind** BC mock Euler V2 (EVC + eUSDC + eWETH) — do not redeploy  
- Optional Crane EVK extras only if product requires beyond mocks  

**X:** Euler on BattleChain.

---

## Phase 5 — Compound-style (Venus mock)

- **Bind** BC Venus Comptroller + vTokens — do not redeploy  
- True Comet only if product overrides research default  

**X:** Compound-style lending on BattleChain.

---

## Phase 6 — Aerodrome + Slipstream

- Aero pools / router / voter / gauges (as ported)  
- Slipstream CL  

**X:** Aerodrome + Slipstream on BattleChain.

---

## Phase 7 — Uniswap (Crane surfaces beyond Phase 1 stubs)

- V2/V3/V4 services or remaining ports not covered by Phase 1 stubs  

**X:** Uniswap ports complete on BattleChain.

---

## Phase 8 — Camelot

- Camelot V2 (as ported)  

**X:** Camelot on BattleChain.

---

## Phase 9 — Liquity / BOLD (as ported)

**X:** Liquity on BattleChain.

---

## Phase 10 — Sky / Maker-related (as ported)

**X:** Sky on BattleChain.

---

## Phase 11 — Resupply

**Dropped** from this greenfield program (not ported into Crane yet). Revisit when ported.

---

## Phase 12 — Reliquary

**X:** Reliquary on BattleChain.

---

## Phase 13 — Pendle / Frax / other vendored (as ready)

Split or merge when maturity allows.

**X:** Per protocol when that slice ships.

---

## Out of scope (until called)

- IndexedEx product (DETF, CCA, RICH)  
- NullAuthorizer (promo shortcut; Phase 2 uses TimelockAuthorizer)  
- Mainnet / Base promote  
- diamondCut of old factory  
- **Resupply** (not ported; dropped from this greenfield)

---

## Per-phase ops

1. Deploy under Phase 1 factory  
2. Write/update address manifest  
3. Refresh `BC_TESTNET` + Deployed Addresses  
4. X post (addresses on docs only)  
