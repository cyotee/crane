---
project: BattleChain greenfield — master checklist
version: 1.1
status: active
created: 2026-07-23
last_updated: 2026-07-25
policy: NO live BC broadcast until ALL phase scripts are written AND locally tested
authority: docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
gap_report: docs/deployment/BC_GREENFIELD_GAP_REPORT.md
research: docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md
---

# BC greenfield master checklist

**Authoritative requirements:** [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md)  
**Gap / conformance report:** [`BC_GREENFIELD_GAP_REPORT.md`](./BC_GREENFIELD_GAP_REPORT.md)  
**Deploy research (BC binds + unclear phases):** [`BC_GREENFIELD_DEPLOY_RESEARCH.md`](./BC_GREENFIELD_DEPLOY_RESEARCH.md)  
**Per-phase deploy steps:** [`BC_GREENFIELD_PHASE_DEPLOY_STEPS.md`](./BC_GREENFIELD_PHASE_DEPLOY_STEPS.md)  
**Script implementation plan:** [`../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md`](../superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md)

This file is only a **progress checklist**. What to deploy is defined in the PRD (§6). Do not invent a reduced ship set here.

**Policy (locked 2026-07-25):** No live BattleChain broadcast until **every** phase script is **written and tested** (local/fork). Not phase-by-phase live. See gap report v1.5+ no-live policy.

**Operator model:** Fixed Foundry scripts (no run-time product options). Commands: [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md). Agent usage + deploy inventory: [`BC_GREENFIELD_SCRIPT_GUIDE.md`](./BC_GREENFIELD_SCRIPT_GUIDE.md). X drafts: [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md).

**Bind sources (G-3):** FullStack / `deployForFullStack` handoff → `BC_TESTNET` after live Phase 1. No env product knobs.

Mark `- [ ]` → `- [x]` as work finishes.

---

## 0. Deploy gate (no live BC until all checked)

### 0.1 Implementation

- [x] Phase 0 (idempotency + shared base) done — CREATE3 with-args idempotent; bind base present
- [x] Phase 1 script implemented + local verify — greenfield identity + fork `deployForFullStack` (Tier A)
- [x] Phase 2 script(s) including 2a+2b + FullStack implemented + local verify — Timelock hard-require + fork (Tier A)
- [x] Phase 3 script implemented + local verify — Path B + V3/V4 `createSelectFork` 6/6 (not live)
- [x] Phase 4 bind script implemented + local verify — Anvil BC fork smoke
- [x] Phase 5 Venus bind script implemented + local verify — Anvil BC fork smoke
- [ ] Phase 6 script implemented + local verify — **PARTIAL** (core; governors/fee modules open)
- [ ] Phase 7 script implemented + local verify — **PARTIAL** (V4Router open)
- [x] Phase 8 script implemented + local verify — factory+router minimum (smoke optional)
- [ ] Phase 9 script implemented + local verify — **GAP** (roots only)
- [ ] Phase 10 script implemented + local verify — **PARTIAL**
- [x] Phase 11 Resupply — **N/A (dropped)**
- [ ] Phase 12 script implemented + local verify — **PARTIAL**
- [ ] Phase 13a + 13b scripts implemented + local verify — **GAP**
- [x] Scripts hardcode **all** options (no env product flags)
- [x] [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md) matches final script paths

### 0.2 Communications (required before first broadcast)

- [x] All phase X drafts written in [`BC_GREENFIELD_X_POSTS.md`](./BC_GREENFIELD_X_POSTS.md)
- [ ] X drafts reviewed (no hex addresses; docs links OK)
- [ ] Security contact ready if public attack-mode promo

### 0.3 Go live

- [ ] **Only then:** live sequence below (one command per phase → agent updates docs → post X) — **blocked until 0.1 full + 0.2**

---

## 1. Phase 0 — Prerequisites

### 1.1 Factory idempotency

- [x] Plan: early-return on `*WithArgs` when code exists
- [x] Implement service (+ factory if needed)
- [x] Tests: double package / facet-with-args / create3 regression
- [x] Local verify green

### 1.2 Shared script base

- [x] `BCPhaseScriptBase` (sender guard, handoff + constants bind, abandoned factory revert, manifest I/O, handoff log)
- [x] Abandoned factory constant `0xC8E93C3c…AD3A`
- [x] Local verify / compile
- [x] G-3 bind decision: handoff + `BC_TESTNET` only (PRD amended 2026-07-25)

---

## 2. Phase checklists

For each phase: **Plan** (deploy graph matches PRD §6) → **Implement** script → **Local verify** → **Live** (only after §0).

### Phase 1 — Factories

PRD deploy list: 1.1–1.13  
Script: `Script_BC_Phase1_Factories.s.sol`  
Manifest: `battlechain-sepolia.json`  
Runtime: `script/output/battlechain-sepolia/greenfield-phase1.latest.json`

- [x] Plan written (order, salts, binds)
- [x] Script implemented
- [x] Sample token included
- [x] Agreement + attack mode (on live; fork deploys agreement path)
- [x] Manifest write (`generation: greenfield`, salt `crane-indexedex-bc-greenfield-v1`)
- [x] Runbook (commands doc)
- [x] Local verify — BC `createSelectFork` deployForFullStack (Tier A)
- [ ] Live (after §0)
- [ ] `BC_TESTNET` + docs + X

### Phase 2 — Balancer V3

PRD: 2a.1–2a.11 + 2b.1–2b.6  
Scripts: `Script_BC_Phase2_BalancerV3.s.sol`, `Script_BC_FullStack.s.sol`  
Manifest: `battlechain-sepolia-balancer-v3.json`

- [x] Plan: TimelockAuthorizer (1h, deployer admin), full facet/package list
- [x] Implement 2a
- [x] Implement 2b (Gyro, LBP, CoW, ReClamm)
- [x] FullStack 1→2
- [x] No agreement / no attack re-link
- [x] Hard-require vault authorizer == Timelock (Tier A P2-7)
- [x] Runbook
- [x] Local verify — BC fork Phase1 handoff → Phase2 Timelock (Tier A)
- [ ] Live (after §0)
- [ ] Docs + X

### Phase 3 — Aave

PRD + **[`BC_AAVE_V4_DEPLOY_STEPS.md`](./BC_AAVE_V4_DEPLOY_STEPS.md)**  
Scripts: Phase3 Aave + Phase3b LibraryPreCompile (+ optional configure split)

- [x] Script + real Path B CREATE2 (no etch)
- [x] Local verify — BC fork 6/6
- [ ] Live (after §0)
- [ ] Docs + X

### Phases 4–5 — Bind

- [x] Phase 4 Euler bind + fork smoke
- [x] Phase 5 Venus bind + fork smoke
- [ ] Live (after §0)

### Phases 6–13

See gap report for PRD-depth open items (Tier B/C). Scripts may compile as stubs; not §0-ready until Local smoke green or waived.

- [ ] Phase 6 Aerodrome — PRD depth open
- [ ] Phase 7 Uniswap extras — V4Router open
- [x] Phase 8 Camelot — minimum factory+router
- [ ] Phase 9 Liquity — GAP
- [ ] Phase 10 Sky — PARTIAL
- [ ] Phase 12 Reliquary — PARTIAL
- [ ] Phase 13a Pendle — GAP
- [ ] Phase 13b Frax — GAP

---

## 3. Tier A hygiene (2026-07-25)

- [x] P1-6 / P1-7 greenfield salt + labels
- [x] P2-7 Timelock hard assert
- [x] G-11 Phase 1/2 fork tests
- [x] G-3 bind priority PRD amend
- [x] G-1 master plan sync
- [ ] G-5 / GATE-5–6 security contact + X review (pre-live only)

---

*Update this file when closing gap report IDs. Live columns stay empty until full suite is written and tested.*
