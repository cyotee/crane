---
project: BattleChain greenfield — X announcement drafts
version: 1.0
status: pre-deploy-drafts
created: 2026-07-23
last_updated: 2026-07-23
rule: No contract hex addresses in posts. Docs links only.
---

# BC greenfield — X post drafts (all phases)

**Gate rule:** These drafts must exist and be reviewed **before any live greenfield broadcast**.  
After each phase succeeds on BC, post the matching draft (optionally tighten wording to match what shipped). Update the **docs URLs** if the public repo path differs.

**Always:**

- Addresses live on docs / JSON / `BC_TESTNET` — **not** in the post body.  
- Mention @battlechain; tag protocol accounts where natural.  
- Tone: ready to use / ready to attack under Safe Harbor — not a token launch.

**Canonical docs links (adjust org/repo if needed):**

```
Deployed addresses: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
Address JSON dir:   https://github.com/cyotee/crane/tree/main/docs/deployment/addresses
Explorer:           https://explorer.testnet.battlechain.com
```

---

## Phase 1 — Crane factories + core stubs

```
Crane factories are live on @battlechain testnet (greenfield root).

Create3Factory + diamond package factory, ERC20Permit package, Uni V2 + V4 PoolManager, Permit2 — under one Safe Harbor lineage.

We bind what BattleChain already provides (WETH, Uni V3). We deploy what Crane owns.

Addresses on our docs. Come build — or break it.

@battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 2 — Balancer V3

```
Balancer V3 is live on @battlechain testnet — and ready to use.

Vault, TimelockAuthorizer, routers, and pool types (weighted, stable, const-prod, gyro, LBP, CoW, ReClamm) via Crane diamonds.

Addresses on our docs. Come build (or break it).

@Balancer @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 3 — Aave

```
Aave is live on @battlechain testnet for Crane greenfield testing.

Pool stack wired to BC test tokens and Chainlink mocks — supply/borrow surface ready for agents and whitehats under Safe Harbor.

Addresses on our docs.

@aave @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 4 — Euler (BC-provided mocks)

```
Euler is available on our @battlechain stack — using BattleChain’s mock EVC + vaults (bound, not redeployed).

Crane docs now point integrators at the BC Euler surface for adversarial testing.

Addresses on our docs.

@eulerfinance @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 5 — Compound-style (Venus mock)

```
Compound-style lending is on our @battlechain path via BattleChain’s Venus mock (Comptroller + vTokens) — bound, not redeployed.

Crane greenfield docs list the addresses for builders and attackers.

@VenusProtocol @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 6 — Aerodrome + Slipstream

```
Aerodrome + Slipstream are live on @battlechain testnet (Crane greenfield).

Pools, voter/ve stack, gauges, and concentrated liquidity factory path — for Base-style ve(3,3) + CL testing under Safe Harbor.

Addresses on our docs. Come break it.

@AerodromeFi @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 7 — Uniswap complete

```
Uniswap surfaces on @battlechain for Crane: BC Uni V3 (bound), Crane Uni V2 + V4 PoolManager, plus V4 periphery (positions, router, lenses).

Full Uni path for agents and whitehats. Addresses on docs only.

@Uniswap @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 8 — Camelot

```
Camelot V2 is live on @battlechain testnet via Crane (factory + router).

Another DEX surface for composition testing under Safe Harbor.

Addresses on our docs.

@CamelotDEX @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 9 — Liquity / BOLD

```
Liquity V2 / BOLD is live on @battlechain testnet (Crane greenfield).

Core branch wired for BC WETH + Chainlink mocks — open-trove path for adversarial testing.

Addresses on our docs.

@LiquityProtocol @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 10 — Sky

```
Sky / DSS core is live on @battlechain testnet via Crane.

Vat + joins + rate stack for CDP-style testing under Safe Harbor. Addresses on docs.

@SkyEcosystem @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 11 — Resupply

**Dropped** from this greenfield (not ported). No post.

---

## Phase 12 — Reliquary

```
Reliquary is live on @battlechain testnet via Crane.

Maturity-weighted staking / relic surface for gauge-style experiments under Safe Harbor.

Addresses on our docs.

@battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 13a — Pendle

```
Pendle is live on @battlechain testnet (Crane greenfield).

Yield contract + market factory path with a seed market for PT/YT-style testing under Safe Harbor.

Addresses on our docs.

@pendle_fi @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Phase 13b — Frax

```
Frax surfaces (Fraxswap / BAMM path) are live on @battlechain testnet via Crane greenfield.

Addresses on our docs. Come build or break it.

@fraxfinance @battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Optional: single cutover post (if posting once after full stack)

```
Crane’s full greenfield DeFi stack is on @battlechain testnet.

Factories, Balancer V3, Aave (V3+V4), bound Euler/Venus, Aerodrome, Uniswap, Camelot, Liquity, Sky, Reliquary, Pendle, Frax — under one CREATE3 root and Safe Harbor.

We use BC-provided mocks where they exist. We deploy Crane-owned ports where they don’t.

Addresses only on docs. Whitehats and agents: this is the red-team surface.

@battlechain @cyfrin

Docs: https://github.com/cyotee/crane/blob/main/docs/deployment/deployed-addresses.md
```

---

## Checklist (pre-deploy gate)

- [ ] Phase 1 draft reviewed  
- [ ] Phase 2 draft reviewed  
- [ ] Phase 3 draft reviewed  
- [ ] Phase 4 draft reviewed  
- [ ] Phase 5 draft reviewed  
- [ ] Phase 6 draft reviewed  
- [ ] Phase 7 draft reviewed  
- [ ] Phase 8 draft reviewed  
- [ ] Phase 9 draft reviewed  
- [ ] Phase 10 draft reviewed  
- [ ] Phase 11 — N/A (dropped)  
- [ ] Phase 12 draft reviewed  
- [ ] Phase 13a draft reviewed  
- [ ] Phase 13b draft reviewed  
- [ ] Docs base URLs correct for public repo  
- [ ] Security contact ready before public attack-mode marketing  

---

## Change log

| Date | Change |
|------|--------|
| 2026-07-23 | Initial drafts for all phases; required pre-deploy gate |
