---
project: BattleChain greenfield — implementation gap report
version: 1.9
status: open
created: 2026-07-24
last_updated: 2026-07-26
purpose: Conformance gaps vs PRD / phase steps / scripts plan so work can be finished after review
authority:
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
  - docs/deployment/BC_GREENFIELD_PHASE_DEPLOY_STEPS.md
  - docs/deployment/BC_AAVE_V4_DEPLOY_STEPS.md
  - docs/deployment/BC_GREENFIELD_MASTER_PLAN.md
  - docs/superpowers/plans/2026-07-23-bc-greenfield-deploy-scripts.md
related:
  - docs/deployment/BC_GREENFIELD_SCRIPT_GUIDE.md
  - docs/deployment/BC_GREENFIELD_COMMANDS.md
  - docs/deployment/BC_GREENFIELD_X_POSTS.md
  - docs/deployment/BC_GREENFIELD_INVENTORY.md
out_of_scope_here:
  - CCA Rehearsal (IndexedEx research; plan-only — see §21)
---

# BC greenfield — gap report (plan vs implementation)

**Use this file** after review to close remaining work.

### No-live policy (locked 2026-07-25 — owner)

**There is no live greenfield BC broadcast until every phase script is written, compiles, and is tested (local/fork).**  
Not “phase-by-phase live.” Not “deploy Phase 1–3 while finishing 9/13 later.”

| Allowed now | Forbidden until §0 + suite ready |
|-------------|----------------------------------|
| Write / deepen phase scripts | `forge script --broadcast` to **live** BC testnet (chain 627 production RPC) |
| Unit tests + `vm.createSelectFork` of BC | Filling `BC_TESTNET` greenfield zeros from live txs |
| Anvil fork of BC for smoke (local) | Public attack-mode marketing that implies live deploy |
| Docs, X drafts, checklist hygiene | Treating any single phase “fork CONFORMS” as permission to go live |

**§0 live gate (restated):** all of the following must be true before **any** live phase:

1. **All** phase scripts exist at PRD depth (or formally waived in this report / PRD).  
2. Full `scripts/foundry/bc/` **compiles**.  
3. **Each** phase has local verify: unit and/or BC `createSelectFork` / Anvil-fork smoke as applicable (§20 Local smoke column).  
4. X drafts reviewed + security contact real (GATE-5/6).  
5. Commands doc matches scripts.

Until then, work is **scripts + tests only**. Phase 3 fork green does **not** unlock live Aave; it only closes Phase 3’s local DoD.

**Greenfield policy (locked 2026-07-24):** This program **replaces** Wave A/B. Overwriting `battlechain-sepolia*.json` / tables with greenfield addresses is **intentional** when live eventually runs. Abandoned factory `0xC8E93C3c…AD3A` is never the live greenfield root. Do not treat “preserve Wave A history” as a gap.

**Phase 3 Path B (2026-07-25 later):** Etch Path B (§6.0) was **rejected**, then **redone** with a real CREATE2 factory via `BattleChainDeployer.deployCreate2` (Safe Singleton–compatible runtime). V3 market + V4 core/configure re-proven on `createSelectFork` of BC testnet. See **§6.4**. **Local/fork only — no live BC broadcast.**

**Legend**

| Tag | Meaning |
|-----|---------|
| **CONFORMS** | Matches plan intent (minor naming/docs debt OK) |
| **PARTIAL** | Script exists; missing PRD items or incomplete graph |
| **GAP** | Required by PRD/steps; missing or wrong |
| **BLOCKED** | External or prior-phase dependency |
| **PROCESS** | Docs/checklist/hygiene; not bytecode |
| **DEBT** | Compiles but mislabeled, thin, or lineage-wrong |

**Compile DoD (2026-07-24):** `forge build --contracts scripts/foundry/bc/` **green** (user-confirmed + independent run exit 0). Treat as **met** unless a later change breaks it.

**Local verify DoD (preferred):** Anvil fork of BattleChain + Anvil wallet / `vm.createSelectFork` — see **§2.1**. Not live BC.

---

## 0. Executive summary

| Area | Status |
|------|--------|
| Script file map (phases 1–10, 12–13a/b + FullStack + base) | **Present** under `scripts/foundry/bc/` |
| CREATE3 `*WithArgs` idempotency | **CONFORMS** (committed; 4/4 tests pass) |
| Shared `BCPhaseScriptBase` + bind guards | **CONFORMS** (handoff + `BC_TESTNET`; G-3 PRD amended) |
| Phase 1 factories script | **CONFORMS (local)** greenfield salt/labels; fork `deployForFullStack` suite |
| Phase 2 Balancer | **CONFORMS (local)** Timelock hard-require; fork Phase1→2 suite |
| Phase 3 Aave | **CONFORMS (local fork)** (2026-07-25 v1.4): Real Path B via BC Deployer CREATE2 (no etch); V3 `initReserves` + V4 core/configure proven on BC `createSelectFork` 6/6. **Not live.** CREATE3 lineage still **DEBT**. See **§6.4** |
| Phase 4–5 bind | **CONFORMS** + **fork smoke green** (Phase 4 Euler, Phase 5 Venus) |
| Phase 6 Aerodrome | **CONFORMS (local)** governors + fee modules + createPool; CL gauge **WAIVED** (not in port); hermetic; **not live** |
| Phase 7 Uniswap | **CONFORMS (local)** concrete `BcV4Router` + periphery; hermetic; **not live** |
| Phase 8 Camelot | **CONFORMS (local)** factory+router + createPair hermetic; **not live** |
| Phase 9 Liquity | **CONFORMS (local)** full WETH branch + `setAddresses` + open-trove hermetic; fork optional when BC RPC up; **not live** |
| Phase 10 Sky | **CONFORMS (local)** full DSS manifest (flapper/flopper/pot/chainlog); multi-root Safe Harbor **WAIVED** vs CREATE3; openCdp hermetic; **not live** |
| Phase 12 Reliquary | **CONFORMS (local)** full curve set + reward fund + createRelic hermetic; **not live** |
| Phase 13a Pendle | **CONFORMS (local)** real ctors + AllAction router + SY/PT/YT/market + oracle; hermetic 3/3; **not live** |
| Phase 13b Frax | **CONFORMS (local)** factory + pair + full BAMM graph (BAMMTest list); hermetic 3/3; **not live** |
| §0 live gate | **GAP** — no live until X review + security contact (GATE-5/6); scripts + local smoke otherwise ready |
| Local verify (fork path) | **CONFORMS (local)** — Phase 1–5 fork; Phase 6–13 hermetic (or fork when RPC); GATE-7 local smoke green |
| Master plan / step checklists updated | **CONFORMS** (synced 2026-07-25 Tier A) |
| Greenfield live on BC | **Blocked by policy** until GATE-5/6 + Tier D (`BC_TESTNET.CREATE3_FACTORY = address(0)`) |

**Severity for “scripts compile plan” DoD** (superpowers plan): **met**.  
**Severity for full PRD script suite:** **Tier A + Tier B + Tier C closed (local/hermetic)**; only pre-live process (G-5 / GATE-5–6) + Tier D live remain.

---

## 1. Sources of truth (what “conform” means)

| Doc | Role |
|-----|------|
| `BC_GREENFIELD_DEPLOYMENT_PRD.md` | **Authoritative** deploy list per phase |
| `BC_GREENFIELD_PHASE_DEPLOY_STEPS.md` | Step order / operator detail |
| `BC_AAVE_V4_DEPLOY_STEPS.md` | Aave V4 A–F |
| `2026-07-23-bc-greenfield-deploy-scripts.md` | Compile-complete script suite DoD |
| `BC_GREENFIELD_MASTER_PLAN.md` | Progress checklist (currently stale) |
| `BC_GREENFIELD_COMMANDS.md` / `BC_GREENFIELD_X_POSTS.md` | Operator + pre-deploy comms |

**Deliberate dual standard:** the scripts plan’s DoD is “every phase script **compiles**”; the PRD’s “done when” often means **usable protocol surface**. This report tracks **both**. Gaps labeled **PRD-depth** may be acceptable if the project formally narrows scope; until then they remain open.

---

## 2. Global / platform gaps

| ID | Severity | Plan requirement | Implementation | Action to close |
|----|----------|------------------|----------------|-----------------|
| G-1 | **CONFORMS** | Master plan / phase steps tick boxes as work finishes | Master plan v1.1 synced 2026-07-25 | Keep in sync as Tier B/C closes |
| G-2 | **PROCESS** | Work committed / reviewable | Most of `scripts/foundry/bc/`, greenfield docs untracked | Commit or stack for review; keep Wave A/B artifacts distinct |
| G-3 | **CONFORMS** | Bind sources for phase scripts | PRD amended: **FullStack handoff → `BC_TESTNET`**; no env product knobs | Matches `BCPhaseScriptBase` |
| G-4 | **DEBT** | Greenfield roots never bind abandoned gen-1 | Guard present; greenfield constants are `address(0)` | OK until Phase 1 live; then write real addresses into `BC_TESTNET` |
| G-5 | **GAP** | Security contact real before public attack-mode marketing | `REPLACE_BEFORE_BROADCAST@example.com` in base + Phase 1/2 | Replace contact before first public attack-mode post |
| G-6 | **PROCESS** | X drafts reviewed (master §0.2) | Drafts written; checklist unchecked | Human review of `BC_GREENFIELD_X_POSTS.md` |
| G-7 | **DEBT** | Safe (Gnosis) stack bind if needed (phase 0.6 / research) | No Safe singleton constants in `BC_TESTNET` (only Safe Harbor URI) | Add Safe addresses from research if any phase needs them |
| G-8 | **CONFORMS** | No Phase 11 script | Absent | Keep dropped |
| G-9 | **CONFORMS** | Commands doc lists fixed forge commands | `BC_GREENFIELD_COMMANDS.md` matches script names | Re-check if scripts split (e.g. Aave configure) |
| G-10 | **CONFORMS** | CREATE3 with-args idempotent | Service + factory + tests | Done |
| G-11 | **CONFORMS (1–13 hermetic/fork)** | Local verify per phase | Phase 1–5 fork; Phase 6–8/10/12 hermetic (Tier C); Phase 9/13a/13b hermetic (+ fork when RPC) | Keep green; optional BC fork for 6–8/10/12 when RPC up |
| G-12 | **WAIVED (policy)** | “Don’t clobber Wave A/B manifests” | **Intentional greenfield replace** (owner 2026-07-24) | Keep shared paths; add `"generation": "greenfield"` labels (P1-7). Do not restore Wave A preservation as a requirement |

### 2.1 Fork smoke test log (2026-07-24)

**Setup:**

```bash
anvil --fork-url https://testnet.battlechain.com --chain-id 627 --port 8545
# Anvil #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# PK: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 (Anvil only)
```

Fork height ~**17200**, chain id **627**.

| Check | Result |
|-------|--------|
| Fork + chain id | **PASS** |
| BC binds have code (WETH, Uni V3, Chainlink, Euler, Venus, BC Deployer, CreateX) | **PASS** |
| Safe Harbor registry / agreement / attack (ERC-1967 proxies) | **PASS** (proxy bytecode) |
| Wave A Create3Factory still on fork | **PASS** (code present; must not bind as greenfield root) |
| Safe Singleton CREATE2 `0x914d…` | **EMPTY** — Aave V4 Path A still blocked on fork too |
| Anvil wallet `cast send` / tiny `CREATE` | **PASS** |
| `Script_BC_Phase4_Euler` `--broadcast` to Anvil | **PASS** (bind + `_requireCode` + manifests; no CREATE3 txs) |
| `Script_BC_Phase5_Compound` `--broadcast` to Anvil | **PASS** |
| `Script_BC_Phase1_Factories` **simulation** on fork | **PASS** — predicted new factory `0xDAc6…796b` ≠ abandoned; full log of facets/packages/stubs/agreement; BC WETH/Uni V3 binds |
| Phase 1 **multi-tx** `forge script --broadcast` to Anvil | **FAIL** in agent session — 37 txs queued, **0 receipts**, `Error: Device not configured (os error 6)`. Retries: `--slow`, `--skip-simulation`, `--batch-size 1`, auto-mine Anvil. **cast** single txs still work. Treat as tooling/env issue; validate Phase 1 via `createSelectFork` in-process tests or operator laptop Anvil broadcast |

**Side effect:** Phase 1 **simulation** wrote predicted fork addresses into `docs/deployment/addresses/battlechain-sepolia.json` (and table). Those are **not live BC**. Discard / overwrite on real greenfield deploy. Prefer routing fork runs to `script/output/` only when implementing further.

**Implication for implementation work:** Invest in scripts; verify binds and deploy graphs on BC fork. Prefer **`forge test` + `vm.createSelectFork`** for Phase 1+ so multi-tx broadcast is not required for DoD.

---

## 3. Phase 0 — Prerequisites

| ID | Severity | Item | Status | Notes |
|----|----------|------|--------|-------|
| P0-1 | **CONFORMS** | `_create3WithArgs` early-return | Done | Commit `c5440a7d` |
| P0-2 | **CONFORMS** | Idempotency tests | 4/4 pass | Re-verified 2026-07-24 |
| P0-3 | **CONFORMS** | `ABANDONED_CREATE3_FACTORY` | Done | = Wave A `0xC8E9…` |
| P0-4 | **CONFORMS** | Euler/Venus/Morpho/Kyber/CCIP binds in `BC_TESTNET` | Done | Confirmed on fork |
| P0-5 | **CONFORMS** | `BCPhaseScriptBase` | Present | Handoff + constants; G-3 closed |
| P0-6 | **CONFORMS** | Compile of base / suite | **Green** | User + independent `forge build --contracts scripts/foundry/bc/` exit 0 |

---

## 4. Phase 1 — Factories

**Script:** `Script_BC_Phase1_Factories.s.sol`  
**PRD items 1.1–1.13:** deploy path largely **present**.

| ID | Severity | Item | Status | Notes |
|----|----------|------|--------|-------|
| P1-1 | **CONFORMS** | Create3 + diamond via `InitBcService.initEnvBc` | Present | |
| P1-2 | **CONFORMS** | ERC20 / 5267 / 2612 facets + Permit DFPkg + sample token | Present | |
| P1-3 | **CONFORMS** | Uni V2 factory/router, Uni V4 PoolManager, BetterPermit2 CREATE3 | Present | Salts reuse `bc-promo-*` (allowed) |
| P1-4 | **CONFORMS** | Bind WETH + Uni V3 | Present | |
| P1-5 | **CONFORMS** | Agreement scope Create3Factory + `requestAttackMode` on BC | Present | |
| P1-6 | **CONFORMS** | **New** greenfield agreement salt | `crane-indexedex-bc-greenfield-v1` | Closed Tier A 2026-07-25 |
| P1-7 | **CONFORMS** | Manifest identity | `generation: greenfield`, phase 1, runtime `greenfield-phase1.latest.json` | Closed Tier A 2026-07-25 |
| P1-8 | **WAIVED** | Manifest path overwrite | Same path as Wave A JSON | **Policy:** intentional greenfield replace (G-12 waived) |
| P1-9 | **CONFORMS** | FullStack `deployForFullStack` | Present | Primary handoff for testing Phase 2 without live constants |
| P1-10 | **BLOCKED** | Live exit criteria | Not live | After **live** broadcast only: factory ≠ abandoned; update `BC_TESTNET` zeros |
| P1-11 | **CONFORMS** | Fork / local smoke | `BC_Phase1_Factories_Fork.t.sol` `deployForFullStack` in-process | Closed Tier A 2026-07-25 |

---

## 5. Phase 2 — Balancer V3

**Script:** `Script_BC_Phase2_BalancerV3.s.sol` + `Script_BC_FullStack.s.sol`

| ID | Severity | Item | Status | Notes |
|----|----------|------|--------|-------|
| P2-1 | **CONFORMS** | Vault facets + VaultDFPkg + vault instance | Present | |
| P2-2 | **CONFORMS** | ProtocolFeeController + set | Present | |
| P2-3 | **CONFORMS** | Router facets + RouterDFPkg + router | Present | |
| P2-4 | **CONFORMS** | Weighted / Stable / ConstProd packages | Present | |
| P2-5 | **CONFORMS** | Gyro 2-CLP / E-CLP, LBP, CoW pool+router, ReClamm | Present | 2b included |
| P2-6 | **CONFORMS** | ERC4626RateProviderFacetDFPkg (2a.12) | Present | |
| P2-7 | **CONFORMS** | TimelockAuthorizer only (PRD non-goal: Null as auth) | Bootstrap Null → **set PFC under Null (hard)** → Timelock hard `getAuthorizer() == timelock`; re-run if already set | Closed Tier A 2026-07-25; PFC-before-Timelock fix same day |
| P2-8 | **CONFORMS** | Timelock `minDelay = 1 hours`, admin deployer | Present | |
| P2-9 | **CONFORMS** | No agreement / no attack re-link | Present | |
| P2-10 | **CONFORMS** | FullStack 1→2 handoff addresses | Present | Avoids zero constants |
| P2-11 | **CONFORMS** | Manifest identity | `generation: greenfield`, phase 2, runtime `greenfield-phase2-balancer-v3.latest.json` | Shared docs path OK (G-12) |
| P2-12 | **CONFORMS** | Local verify: vault + Timelock | `BC_Phase2_Balancer_Fork.t.sol` Phase1→2 | Closed Tier A 2026-07-25 |

---

## 6. Phase 3 — Aave (**local fork CONFORMS — not live**)

### 6.0 Historical ERROR: `vm.etch` Path B (rejected 2026-07-25; superseded by §6.4)

**Status (historical):** An earlier Phase 3 attempt implemented Path B with **`vm.etch`** of Safe Singleton runtime at `0x914d…`. That was **rejected** (not a real deploy; cannot survive live broadcast). Keep this section as the rejection record; **do not reintroduce etch Path B**.

| File / area | What was wrong |
|-------------|----------------|
| V3/V4 `Create2Utils.ensureCreate2Factory` | `vm.etch` at canonical Safe Singleton when empty |
| Fork suite | Passed only because cheatcodes installed the factory |

### 6.4 REDO complete (2026-07-25) — real Path B + V3/V4 fork proof

**Status:** **Local / fork DoD met.** Production Path B no longer uses `vm.etch`. Proven via `createSelectFork` of BC testnet (chain 627) driving shipped helpers. **Live BC broadcast still not done** (greenfield §0 gate).

#### Path B implementation

| Piece | Behavior |
|-------|----------|
| Path A | If `0x914d…` has code → use canonical Safe Singleton |
| Path B | Else deploy official Safe Singleton **runtime** (69-byte initcode bootstrap `60458060093d393df3` + runtime) via **`IBattleChainDeployer(BC_TESTNET.DEPLOYER).deployCreate2`** with fixed CreateX-compatible salt |
| Fallback | Hermetic Anvil without BC Deployer: plain `CREATE` + transient store of factory address (same tx) |
| `getFactory()` / `create2Deploy` | Use active factory address (Path A or Path B); compute CREATE2 against that factory |
| Forbidden | `vm.etch` of CREATE2 factory in production Path B / Phase 3 greenfield scripts |

#### Files

| Path | Role |
|------|------|
| `contracts/protocols/lending/aave/v4/.../Create2Utils.sol` | Real Path A/B (no etch) |
| `contracts/protocols/lending/aave/v3.6/.../Create2Utils.sol` | Same Path B scheme for V3 library batches |
| `scripts/foundry/bc/BcAavePhase3Deploy.sol` | V3 market + V4 core/configure; `ensureCreate2FactoryPathB` |
| `scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol` (+ 3b LibraryPreCompile / Configure) | Operator entry |
| `test/foundry/spec/scripts/bc/BC_Phase3_Aave_Fork.t.sol` | BC fork suite (asserts Path A empty; factory = BC Deployer prediction) |
| `test/.../Create2Utils.t.sol` | Unit: `testCreate2Deploy_pathB_realFactoryWhenPathAMissing` (replaced etch-named test) |

#### Fork verification (2026-07-25)

```bash
forge test --match-path test/foundry/spec/scripts/bc/BC_Phase3_Aave_Fork.t.sol -vv
# 6/6 pass (twice): binds, Path B no-etch, V3 market, V4 core+configure, full V3+V4, V4 supply smoke
forge test --match-path test/foundry/spec/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.t.sol
# 11/11 pass
```

| Check | Result |
|-------|--------|
| Path A `0x914d…` empty on BC after Path B | **PASS** (no etch) |
| Path B factory code via BC Deployer CREATE2 | **PASS** |
| V3 pool/provider/oracle + WETH/USDC/DAI aTokens | **PASS** |
| V4 AccessManager/Hub/Spoke/LiquidationLogic + reserves | **PASS** |
| Optional V4 `spoke.supply` WETH | **PASS** (fork suite) |
| Live `forge script --broadcast` to BC | **Not run** (policy / §0) |

### 6.1 Scripts / libs (trusted for local fork path)

- `BcAavePhase3Deploy.sol` — V3/V4/configure helpers  
- `Script_BC_Phase3_Aave.s.sol`, `Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol`, `Script_BC_Phase3b_AaveV4_Configure.s.sol`  
- `SpokeBytecodeLinker` — LiquidationLogic CREATE2 + artifact link  
- `BC_Phase3_Aave_Fork.t.sol` — fork suite (real Path B)

### 6.2 Aave V3 (PRD 3a)

| ID | Severity | Notes |
|----|----------|--------|
| P3a-1–8 | **CONFORMS (fork)** | Batch + `initReserves` for BC WETH/USDC/DAI; re-proven after real Path B |
| P3a-9 | **WAIVED** | Optional periphery |
| P3a-10 | **DEBT** | CREATE3 lineage still open (Aave uses CREATE2 factory / `new`, not Phase 1 CREATE3 root) |

### 6.3 Aave V4 (steps A–F)

| ID | Severity | Step | Status |
|----|----------|------|--------|
| P3b-A | **CONFORMS (fork)** | CREATE2 Path B | Real BC Deployer CREATE2 factory; unit + fork prove no etch at `0x914d…` |
| P3b-B | **CONFORMS (fork)** | LiquidationLogic + link | Proven in `deployV4Core` / fork suite |
| P3b-C | **CONFORMS (fork)** | Orchestration + `FullDeployInputs` | Hardcoded BC inputs in `BcAavePhase3Deploy` |
| P3b-D | **CONFORMS (fork)** | Configure + supply smoke | WETH/USDC/DAI reserves; supply smoke OK on fork |
| P3b-E | **PARTIAL** | Manifest fields | Script writes JSON/table; not filled from **live** BC |
| P3b-F | **PROCESS** | Docs + X after live | Still after live only |

**PRD “done when” (usable market on BC):** **met for local/fork deploy path.** **Not live** until Tier D / §0. CREATE3 lineage remains **DEBT** (P3a-10).
---

## 7. Phase 4 — Euler (bind)

| ID | Severity | Status | Notes |
|----|----------|--------|-------|
| P4-1 | **CONFORMS** | Bind EVC / eUSDC / eWETH; code checks; no CREATE3 | Matches PRD |
| P4-2 | **PROCESS** | Live docs/`BC_TESTNET` already have addresses | Script still needed for manifest generation on live |
| P4-3 | **CONFORMS** | Fork smoke (2026-07-24) | `forge script` Phase 4 on Anvil BC fork **PASS** — logs EVC/eUSDC/eWETH; `_requireCode` on chain 627 |

---

## 8. Phase 5 — Venus / Compound-style (bind)

| ID | Severity | Status | Notes |
|----|----------|--------|-------|
| P5-1 | **CONFORMS** | Bind Comptroller + vTokens; no Comet | Matches PRD default |
| P5-2 | **PARTIAL** | `_requireCode` only on Comptroller + vUSDC + vWETH | Consider requiring all listed vTokens on chain 627 |
| P5-3 | **CONFORMS** | Fork smoke (2026-07-24) | Phase 5 on Anvil BC fork **PASS** |

---

## 9. Phase 6 — Aerodrome + Slipstream (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase6_Aerodrome.s.sol` + `BcAerodromePhase6Deploy.sol`  
**Tests:** `BC_Phase6_Aerodrome_Hermetic.t.sol` (always-on).

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P6-1 | **CONFORMS (local)** | 6.1–6.15 core ve(3,3) stack | Helper plain CREATE + role wiring | |
| P6-2 | **CONFORMS (local)** | 6.16 ProtocolGovernor | Deployed + `Voter.setGovernor` | Closed Tier C 2026-07-26 |
| P6-3 | **CONFORMS (local)** | 6.17 EpochGovernor | Deployed + `Voter.setEpochGovernor` | Closed Tier C 2026-07-26 |
| P6-4 | **CONFORMS** | 6.18 role wiring | Present | |
| P6-5 | **CONFORMS** | 6.19–6.20 CLPool + CLFactory | Present | legacy CL factory `address(0)` intentional |
| P6-6 | **CONFORMS (local)** | 6.21 Custom fee modules | CustomSwapFeeModule + CustomUnstakedFeeModule set on CLFactory | Closed Tier C 2026-07-26 |
| P6-7 | **WAIVED** | 6.22 CL gauge path | **No CLGauge in Crane slipstream port** (only CLPool/CLFactory/fees) | Product non-goal until CL gauge port lands; PRD note |
| P6-8 | **CONFORMS (local)** | create-pool smoke | Hermetic volatile `PoolFactory.createPool` | Closed Tier C 2026-07-26 |

**Verdict:** **Local DoD met** (with P6-7 waived). **Not live.**

---

## 10. Phase 7 — Uniswap extras (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase7_Uniswap.s.sol` + `BcUniswapPhase7Deploy.sol` (`BcV4Router` concrete)  
**Tests:** `BC_Phase7_Uniswap_Hermetic.t.sol`.

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P7-1 | **CONFORMS** | Bind Uni V3 | Present (operator path) | |
| P7-2 | **CONFORMS (local)** | PositionDescriptor + PositionManager | Helper + hermetic | |
| P7-3 | **CONFORMS (local)** | 7.3 V4Router | Concrete `BcV4Router` (extends abstract `V4Router` + ReentrancyLock + ERC20 `_pay`) | Closed Tier C 2026-07-26 |
| P7-4 | **CONFORMS (local)** | StateView + V4Quoter | Present | |
| P7-5 | **CONFORMS (local)** | Manifest PM + periphery | Hermetic deploys own PM; live binds Phase1 constants when filled | |

**Verdict:** **Local DoD met**. **Not live.**

---

## 11. Phase 8 — Camelot (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase8_Camelot.s.sol` + `BcCamelotPhase8Deploy.sol`  
**Tests:** `BC_Phase8_Camelot_Hermetic.t.sol`.

| ID | Severity | Status | Notes |
|----|----------|--------|-------|
| P8-1 | **CONFORMS (local)** | Factory + Router | Helper plain CREATE; script operator path |
| P8-2 | **CONFORMS (local)** | createPair viable | Hermetic createPair smoke PASS |

**Verdict:** **Local DoD met**. **Not live.**

---

## 12. Phase 9 — Liquity / BOLD (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase9_Liquity.s.sol` + `BcLiquityPhase9Deploy.sol`  
**Tests:** `BC_Phase9_Liquity_Hermetic.t.sol` (always-on); `BC_Phase9_Liquity_Fork.t.sol` (BC `createSelectFork` when RPC up).

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P9-1 | **CONFORMS (local)** | 9.1 BoldToken | CREATE2 via helper | |
| P9-2 | **CONFORMS (local)** | 9.2 CollateralRegistry + AddressesRegistry | Full; CCR/MCR/BCR/SCR from bold `Constants` WETH params | |
| P9-3 | **CONFORMS (local)** | 9.3–9.9 pools, SP, troves, BO, price feed, helpers | Active/Default/Gas/CollSurplus, SP, ST, TM, NFT, Metadata, BO, WETHPriceFeed, HintHelpers, MultiTroveGetter, RedemptionHelper, DebtInFrontHelper, InterestRouter | |
| P9-4 | **CONFORMS (local)** | 9.10 `setAddresses` full wiring | Pre-calc CREATE2 + `AddressVars` then deploy | |
| P9-5 | **CONFORMS (local)** | 9.8 PriceFeed → BC ETH/USD | `WETHPriceFeed(CHAINLINK_ETH_USD, 24h, BO)`; hermetic uses mock oracle with 8 decimals | |
| P9-6 | **CONFORMS (local)** | Open-trove exit | Hermetic `openTrove` PASS (`MIN_DEBT=2000e18`, `ETH_GAS_COMPENSATION=0.0375e18`) | Fork open when RPC available |

**Verdict:** **Local/fork DoD met** for one WETH branch. **Not live.** Zappers remain out of scope.

---

## 13. Phase 10 — Sky / DSS (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase10_Sky.s.sol` + `BcSkyPhase10Deploy.sol`  
**Tests:** `BC_Phase10_Sky_Hermetic.t.sol` (deploy + openCdp draw DAI).

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P10-1 | **CONFORMS (local)** | 10.1–10.15 via `SkyDssFactoryService` | Full `deployDss` + params + `initIlk` | Closed Tier C 2026-07-26 |
| P10-2 | **WAIVED** | Deploy under Phase 1 Create3Factory | **Multi-root Safe Harbor** — Maker-style plain `new` graph is intentional; documented in helper/script NatSpec + manifest `"lineage": "multi-root-safe-harbor-plain-new"` | Do not CREATE3-wrap DSS (divergent graph risk) |
| P10-3 | **CONFORMS (local)** | Flapper/Flopper/Pot/Chainlog in manifest | Full table + JSON addresses | Closed Tier C 2026-07-26 |
| P10-4 | **CONFORMS (local)** | openCdp-style exit | Hermetic join+frob+exit DAI PASS | Closed Tier C 2026-07-26 |

**Verdict:** **Local DoD met** (CREATE3 lineage formally waived as multi-root). **Not live.** Pip seed is DSValue (Maker `peek`); Chainlink aggregator is not a pip ABI.

---

## 14. Phase 12 — Reliquary (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase12_Reliquary.s.sol` + `BcReliquaryPhase12Deploy.sol`  
**Tests:** `BC_Phase12_Reliquary_Hermetic.t.sol`.

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P12-1 | **CONFORMS (local)** | Reliquary + LinearCurve + addPool | Present | |
| P12-2 | **CONFORMS (local)** | Full curve set | Linear + LinearPlateau + PolynomialPlateau | Closed Tier C 2026-07-26 |
| P12-3 | **CONFORMS (local)** | Fund rewards | Helper funds Reliquary (`rewardFunded`) | Closed Tier C 2026-07-26 |
| P12-4 | **CONFORMS (local)** | create-relic smoke | Hermetic `createRelicAndDeposit` PASS | Closed Tier C 2026-07-26 |

**Verdict:** **Local DoD met**. **Not live.** Bootstrap Relic from `addPool` mints to deployer EOA (not helper).

---

## 15. Phase 13a — Pendle (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase13a_Pendle.s.sol` + `BcPendlePhase13aDeploy.sol`  
**Tests:** `BC_Phase13a_Pendle_Hermetic.t.sol` (always-on); `BC_Phase13a_Pendle_Fork.t.sol` (BC `createSelectFork` when RPC up).

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P13a-1 | **CONFORMS (local)** | 13a.1 Router (AllAction V3) | `PendleRouterV4` + ActionStorage/Misc/AddRemove/SwapPT/SwapYT/Callback facets wired | |
| P13a-2 | **CONFORMS (local)** | 13a.2–13a.3 factories | Real split-code ctors for YT + MarketV3; YC `initialize`; MF treasury/gauge stub | |
| P13a-3 | **CONFORMS (local)** | 13a.4 PoolDeployHelper | Wired to real router + factories | |
| P13a-4 | **CONFORMS (local)** | 13a.5 One SY for BC asset | `PendleERC20SY` on WETH (fork) / hermetic ERC20 | |
| P13a-5 | **CONFORMS (local)** | 13a.6 createYieldContract + createNewMarket | PT/YT + market; manifests list sy/pt/yt/market | |
| P13a-6 | **CONFORMS (local)** | 13a.7 Oracle helpers | `PendlePYLpOracle` behind ERC1967Proxy (initialize) | |

**Verdict:** **Local/fork DoD met** for one ERC20-SY seed market. Hermetic 3/3 + BC fork seed on WETH re-verified 2026-07-26. **Not live.** Optional seed liquidity remains non-goal.

---

## 16. Phase 13b — Frax (**local CONFORMS — not live**)

**Script / helper:** `Script_BC_Phase13b_Frax.s.sol` + `BcFraxPhase13bDeploy.sol`  
**Tests:** `BC_Phase13b_Frax_Hermetic.t.sol`; `BC_Phase13b_Frax_Fork.t.sol` (BC WETH/USDC pair when RPC up).

**Exact BAMM graph (from `BAMMTest._deployBamm` / TestBase_FraxBAMM path):**
1. FraxswapFactory  
2. FraxswapPair (`factory.createPair`)  
3. FraxswapDummyRouter  
4. BAMMHelper  
5. FraxswapOracle  
6. BAMM  

| ID | Severity | PRD item | Implementation | Action |
|----|----------|----------|----------------|--------|
| P13b-1 | **CONFORMS (local)** | 13b.1 FraxswapFactory | Present | |
| P13b-2 | **CONFORMS (local)** | 13b.2 Pair creation path | createPair hermetic DummyTokens; fork WETH/USDC | |
| P13b-3 | **CONFORMS (local)** | 13b.3 BAMM graph | Full list above; hermetic `bamm.mint` smoke | |
| P13b-4 | **CONFORMS** | Exact contract list | Listed in script NatSpec + manifest `contractList` | |

**Verdict:** **Local DoD met** for TestBase_FraxBAMM / BAMMTest graph. Hermetic 3/3 re-verified 2026-07-26 (includes real `bamm.mint`); fork skips cleanly when BC RPC down. **Not live.** TWAMM/Range out of scope.

---

## 17. §0 deploy gate (master plan)

| ID | Severity | Gate item | Status |
|----|----------|-----------|--------|
| GATE-1 | **CONFORMS (local)** | All phase scripts implemented at PRD depth | Tier C closed: implement or formal waive (P6-7 CL gauge; P10-2 multi-root CREATE3) — **not live** |
| GATE-2 | **CONFORMS** | Scripts compile | Green (`forge build --contracts scripts/foundry/bc/`; hermetic suites compile path) |
| GATE-3 | **CONFORMS** | Commands match paths | Yes |
| GATE-4 | **CONFORMS** | X drafts written | Yes |
| GATE-5 | **GAP** | X drafts reviewed | Checklist open — **blocks live** |
| GATE-6 | **GAP** | Security contact ready | Placeholder — **blocks live** |
| GATE-7 | **CONFORMS (local)** | **Local/fork verify per phase** | Phase 1–5 fork; Phase 6–13 hermetic (or fork when RPC) — **local green**; still **blocks live** until GATE-5/6 + Tier D |
| GATE-8 | **CONFORMS** | **No live until full suite** | Owner (2026-07-25): **no** live BC until **all scripts written and tested**; not phase-by-phase live. Constants remain zero until Tier D |

Re-run compile after any gap-close edits. Prefer `createSelectFork` tests over multi-tx Anvil `--broadcast` for DoD.

---

## 18. Historical Wave A / Wave B (context, not greenfield)

| Item | Status | Interaction with greenfield |
|------|--------|-----------------------------|
| Wave A factories | Live on BC at abandoned address | Must not bind as greenfield root; still visible on BC fork |
| Wave B Balancer | Manifest claims deployed on Wave A factory | Superseded by greenfield Phase 2 when that goes live |
| Promo scripts | `Script_Promo_BC_*` still present | PRD: not canonical; recovery only |
| CREATE3 with-args idempotency | Shipped for Wave B resume | Helps greenfield re-runs |
| Manifest overwrite | **Policy: OK** | Greenfield intentionally replaces Wave A/B address books |

**Do not treat Wave B as Phase 2 greenfield complete.**

---

## 19. Recommended close order (**scripts + local tests only** — Tier D blocked)

**Rule:** finish writing **and** testing every phase before **any** live BC broadcast.  
**Verify each WP** with unit tests and/or BC fork (`createSelectFork` preferred; Anvil fork scripts OK for binds). Mark §20 Local smoke when a phase’s script path is proven.

### Tier A — Platform hygiene + early fork coverage (**DONE 2026-07-25** except pre-live G-5)

1. ~~**P1-6 / P1-7:** greenfield agreement salt + labels~~ **done**  
2. ~~**P2-7:** hard-require Timelock~~ **done**  
3. ~~**G-11:** Phase 1/2 fork tests~~ **done** (`BC_Phase1_Factories_Fork`, `BC_Phase2_Balancer_Fork`)  
4. ~~**G-3:** bind priority~~ **done** — PRD amend: handoff + `BC_TESTNET`  
5. ~~**G-1:** master plan sync~~ **done** (v1.1)  
6. **G-5 / GATE-5–6:** security contact + X review only when suite is otherwise ready for Tier D (not mid-suite).

### Tier B — PRD-critical protocol depth (**DONE 2026-07-25/26** — script + hermetic/fork each)

7. ~~**Phase 3:** Path B + V3/V4~~ **done (local/fork)** — optional CREATE3 lineage (P3a-10). **No live** until Tier D.  
8. ~~**Phase 9:** full BOLD WETH branch + hermetic open-trove~~ **done (local)** — fork suite skips if BC RPC down. **No live.**  
9. ~~**Phase 13a:** real ctors + router + one SY/market + smoke~~ **done (local)** — hermetic 3/3; BC fork WETH seed. **No live.**  
10. ~~**Phase 13b:** enumerate BAMM list + pair + smoke~~ **done (local)** — hermetic 3/3 (`bamm.mint`); fork when RPC. **No live.**

### Tier C — Completeness / lineage (**DONE 2026-07-26** — script + hermetic each)

11. ~~**Phase 6:** governors / fee modules + createPool; CL gauge waived~~ **done (local)**  
12. ~~**Phase 7:** concrete `BcV4Router` + periphery hermetic~~ **done (local)**  
13. ~~**Phase 10:** full manifest + openCdp; CREATE3 multi-root waived~~ **done (local)**  
14. ~~**Phase 12:** full curves + reward fund + createRelic~~ **done (local)**  
15. ~~**§20 Local smoke** Phases 6–8/10/12~~ **done (local)** — GATE-7 local green.

### Tier D — Live (only after **entire** suite: scripts + tests + §0)

**Do not start Tier D until GATE-1, GATE-2, GATE-7 are green** (and GATE-5/6). Then:

16. Phase 1 live → fill `BC_TESTNET` greenfield zeros.  
17. Per-phase command → docs agent → X post (still sequential live; never skip unfinished script work).

---

## 20. Acceptance matrix (fill when closing)

| Phase | Compile | PRD deploy list | Local smoke | Live | Docs | X |
|------|:-------:|:---------------:|:-----------:|:----:|:----:|:-:|
| 0 | [x] | [x] | [x] idempotent + bind unit | n/a | [ ] | n/a |
| 1 | [x] | [x] greenfield labels | [x] **createSelectFork deployForFullStack** | [ ] | [ ] | [ ] |
| 2 | [x] | [x] Timelock hard | [x] **fork Phase1→2 Timelock** | [ ] | [ ] | [ ] |
| 3 | [x] | [x] fork Path B+V3+V4; lineage **DEBT** | [x] **BC createSelectFork 6/6** (real Path B) | [ ] | [ ] | [ ] |
| 4 | [x] | [x] | [x] **BC Anvil fork script** | [ ] | [ ] | [ ] |
| 5 | [x] | [x] | [x] **BC Anvil fork script** | [ ] | [ ] | [ ] |
| 6 | [x] | [x] governors+fees; CL gauge **waived** | [x] **hermetic stack+createPool** | [ ] | [ ] | [ ] |
| 7 | [x] | [x] BcV4Router concrete | [x] **hermetic periphery+router** | [ ] | [ ] | [ ] |
| 8 | [x] | [x] min factory+router | [x] **hermetic createPair** | [ ] | [ ] | [ ] |
| 9 | [x] | [x] full WETH branch | [x] **hermetic deploy+openTrove**; fork when RPC | [ ] | [ ] | [ ] |
| 10 | [x] | [x] full DSS; CREATE3 multi-root **waived** | [x] **hermetic openCdp** | [ ] | [ ] | [ ] |
| 12 | [x] | [x] curves+fund | [x] **hermetic createRelic** | [ ] | [ ] | [ ] |
| 13a | [x] | [x] router+SY+market | [x] **hermetic seed 3/3**; fork when RPC | [ ] | [ ] | [ ] |
| 13b | [x] | [x] factory+pair+BAMM list | [x] **hermetic BAMM mint 3/3**; fork when RPC | [ ] | [ ] | [ ] |
| §0 gate | — | — | — | [ ] | — | [ ] |

Compile: full `scripts/foundry/bc/` green 2026-07-24; Phase 13 suite 2026-07-26; **Tier C hermetic 2026-07-26**.  
**Local smoke** = unit / `createSelectFork` / Anvil-fork only — **required** before Tier D for each phase (or explicit waive).  
**Live** column stays empty until GATE-5/6 + Tier D.
---

## 21. CCA Rehearsal (IndexedEx — out of greenfield scope)

Plans under `research/scenarios/cca/` are **PLANNED** only:

- No Phase 0 `ADDRESSES.md`, scripts, runner, FINDINGS, or artifacts.  
- Not part of BC greenfield §0.  
- Track separately under IndexedEx research; do not block greenfield script work.

---

## 22. Progress snapshot

| Done | Not done / open |
|------|-----------------|
| Compile DoD met | G-5 security contact / X review (pre-live GATE-5/6) |
| CREATE3 idempotency (4/4) | Phase 3 CREATE3 lineage **DEBT** (P3a-10, optional) |
| BC fork Phase 1/2/3/4/5; Phase 6–13 hermetic | Safe Singleton Path A on BC (optional; Path B works) |
| **Tier A hygiene** (v1.6) | Tier D live — **blocked** until GATE-5/6 |
| **Phase 9 WETH branch** (v1.7) | |
| **Tier B Phase 13a/13b** (v1.8) | |
| **Tier C Phases 6/7/8/10/12** (v1.9) | |
| G-12 waived (clobber OK) | |
| P6-7 CL gauge waived; P10-2 multi-root CREATE3 waived | |
| **No-live until full suite** (v1.5+) | |

**Next work:** pre-live G-5 / GATE-5–6 only when ready for Tier D; optional fork smoke for 6–8/10/12.  
**Not next:** live BC broadcast (still policy-blocked).

---

## 23. Change log

| Date | Change |
|------|--------|
| 2026-07-24 | v1.0 — Initial gap report from plan docs vs `scripts/foundry/bc/` + `BC_TESTNET` + manifests |
| 2026-07-24 | v1.1 — Compile confirmed; CREATE3 tests re-run; **§2.1 BC Anvil fork smoke** (binds 4/5 pass, Phase 1 sim pass, multi-tx broadcast fail in agent env); G-12 **waived** (greenfield replaces Wave A/B); acceptance matrix + Tier order updated; no live |
| 2026-07-25 | v1.2 — Phase 3 marked closed on fork under etch Path B (superseded by v1.3) |
| 2026-07-25 | v1.3 — **Phase 3 REJECTED:** document `vm.etch` Path B as **unacceptable**; must be redone by another agent; §6.0 explains why; CONFORMS claims reverted to PARTIAL/GAP |
| 2026-07-25 | v1.4 — **Phase 3 Path B REDO:** real CREATE2 via BC Deployer (no etch); V3+V4 `createSelectFork` 6/6; unit Create2Utils 11/11; §6.4; acceptance matrix Phase 3 local smoke green; still not live |
| 2026-07-25 | v1.5 — **No-live policy locked:** no BC broadcast until **all** phase scripts are **written and tested** (local/fork); not phase-by-phase live. GATE-7/8 + §19 Tier D restated; testing co-equal with script depth |
| 2026-07-25 | v1.6 — **Tier A closed:** Phase 1 greenfield salt/labels; Phase 2 Timelock hard-require; Phase 1/2 fork tests; G-3 PRD amend; master plan v1.1 |
| 2026-07-25 | v1.7 — **Phase 9 Liquity:** full WETH branch via `BcLiquityPhase9Deploy`; hermetic open-trove; not live |
| 2026-07-25 | v1.8 — **Tier B closed:** Phase 13a Pendle seed + Phase 13b Frax BAMM graph; hermetic each; not live |
| 2026-07-26 | v1.8 hygiene — re-verified 13a/13b; Tier B marked DONE in §19 |
| 2026-07-26 | v1.9 — **Tier C closed (local):** Phase 6 governors+fee modules (CL gauge **WAIVED**); Phase 7 concrete `BcV4Router`; Phase 8 createPair smoke; Phase 10 full DSS manifest + openCdp (CREATE3 multi-root **WAIVED**); Phase 12 full curves+fund+createRelic; §20 Local smoke 6–8/10/12 green; GATE-1/7 local CONFORMS; still **not live** (GATE-5/6) |

---

*Review this report, decide which PRD-depth items to implement vs formally waive, then work remaining **Tier D** only after GATE-5/6. Live column stays empty until Tier D. When closing an ID, update §20.*
| 2026-07-25 | v1.5 — **No-live policy locked:** no BC broadcast until **all** phase scripts are **written and tested** (local/fork); not phase-by-phase live. GATE-7/8 + §19 Tier D restated; testing co-equal with script depth; Phase 3 “next” is not live |
| 2026-07-25 | v1.6 — **Tier A closed:** Phase 1 greenfield salt/labels; Phase 2 Timelock hard-require; Phase 1/2 fork tests; G-3 PRD amend (handoff + constants); master plan v1.1; §20 Local smoke 1–2 green |
| 2026-07-25 | v1.7 — **Phase 9 Liquity:** full WETH branch via `BcLiquityPhase9Deploy` (CREATE2 setAddresses graph); hermetic open-trove 3/3; fork suite skip-on-RPC-down; §12/§19/§20/§22 updated; not live |
| 2026-07-25 | v1.8 — **Tier B closed:** Phase 13a Pendle seed (`BcPendlePhase13aDeploy` real split-code factories + AllAction router + ERC20 SY + PT/YT/market + PYLpOracle proxy); Phase 13b Frax BAMM graph (`BcFraxPhase13bDeploy` exact BAMMTest list); hermetic 3/3 each; §15/§16/§19/§20/§22; not live |
| 2026-07-26 | v1.8 hygiene — re-verified 13a hermetic+fork and 13b hermetic; G-11 extended to 9/13a/b; Tier B marked **DONE** in §19; exec summary points next at Tier C only; `last_updated` |

---

*Review this report, decide which PRD-depth items to implement vs formally waive, then work remaining **Tier C** (each with local smoke). Live (Tier D) only after the full suite is written, tested, and §0 is green. When closing an ID, update §20 and leave a one-line note under the phase section.*
