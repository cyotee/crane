---
project: BattleChain greenfield phased deployment scripts
version: 0.1
status: superseded
created: 2026-07-23
last_updated: 2026-07-23
owner: TBD
decisions_resolved: 2026-07-23
superseded_by: docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
related:
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
  - docs/deployment/BC_GREENFIELD_INVENTORY.md
  - docs/deployment/BC_GREENFIELD_MASTER_PLAN.md
  - docs/superpowers/plans/2026-07-23-create3-package-idempotency-and-bc-redeploy.md
  - docs/superpowers/plans/2026-07-23-bc-balancer-v3-wave-b.md
  - docs/deployment/battlechain.md
  - docs/deployment/WAVE_B_BALANCER_V3_RUNBOOK.md
---

# PRD: BattleChain greenfield deployment scripts

> **Superseded for scope and policy.** Use [`BC_GREENFIELD_DEPLOYMENT_PRD.md`](./BC_GREENFIELD_DEPLOYMENT_PRD.md) as the authoritative deployment PRD (what deploys, all phases required, no live broadcast until all scripts are implemented). This document retains earlier script-platform notes; if anything conflicts, the deployment PRD wins.

## 1. Vision

Ship a **repeatable, phase-scoped Foundry script suite** that deploys Crane’s greenfield stack on BattleChain testnet (chain ID `627`) under a **new Create3Factory root**, produces machine-readable address manifests, wires `BC_TESTNET` / Deployed Addresses docs, and supports a clean **deploy → manifest → docs → X announcement** loop per phase.

Scripts implement the inventory in [`BC_GREENFIELD_INVENTORY.md`](./BC_GREENFIELD_INVENTORY.md) as specified in the [deployment PRD](./BC_GREENFIELD_DEPLOYMENT_PRD.md). Checklist: [`BC_GREENFIELD_MASTER_PLAN.md`](./BC_GREENFIELD_MASTER_PLAN.md).

## 2. Background & inventory review

### 2.1 Decision context (from greenfield plan)

| Constraint | Implication for scripts |
|------------|-------------------------|
| **No `diamondCut`** on BattleChain | Never upgrade the live factory in place. New Create3Factory root only. |
| **New Create3Factory root** | Phase 1 deploys factories; later phases **bind** that root. |
| **Old Wave A/B addresses abandoned** | Scripts must not hardcode gen-1 addresses as the only source of truth. |
| **Idempotent CREATE3** (incl. `*WithArgs`) | Scripts may re-broadcast after partial failure without custom short-circuits long-term. |
| **BC-provided contracts** | Always **bind**, never redeploy: SafeHarbor/Attack infra, WETH, Uni V3, test tokens, Chainlink mocks. |

### 2.2 Inventory summary (what scripts must eventually cover)

| Phase | Deliverable surface | Script readiness today |
|-------|---------------------|------------------------|
| **1** | Create3Factory, DiamondPackageCallBackFactory, ERC20/5267/2612 facets, ERC20PermitDFPkg (+ optional sample), Uni V2 Factory + Router02, Uni V4 PoolManager, BetterPermit2, Safe Harbor (new salt, factory scope, `ChildContractScope.All`), `requestAttackMode` | **Exists:** `Script_Promo_BC_Launch.s.sol` (Wave A) — reuse / retarget for greenfield |
| **2** | Balancer V3 vault + TimelockAuthorizer + PFC + Vault; Router DFPkg + Router; Weighted / Stable / ConstProd; Gyro 2-CLP + E-CLP; LBP; CoW pool + CoW router; ReClamm | **Partial:** `Script_Promo_BC_BalancerV3.s.sol` (NullAuthorizer promo; Weighted/Stable/ConstProd only; hardcodes `BC_TESTNET`) |
| **3** | Aave V3 (as ported); Aave V4 Hub/Spoke when ready | **Missing** |
| **4** | Euler EVC / EVK (as ported) | **Missing** |
| **5** | Compound Comet markets / configurator / rewards | **Missing** |
| **6** | Aerodrome + Slipstream CL | **Missing** |
| **7** | Uniswap Crane surfaces beyond Phase 1 stubs | **Missing** |
| **8** | Camelot V2 (as ported) | **Missing** |
| **9** | Liquity / BOLD (as ported) | **Missing** |
| **10** | Sky / Maker-related (as ported) | **Missing** |
| **11** | Resupply | **Missing** |
| **12** | Reliquary | **Missing** |
| **13** | Pendle / Frax / other vendored (split when ready) | **Missing** |

### 2.3 Gaps called out by reviewing inventory + existing scripts

1. **Stale bind source** — Wave B reads `BC_TESTNET.CREATE3_FACTORY` etc. After greenfield Phase 1, those constants are abandoned until rewritten. Scripts must bind from **latest Phase 1 manifest JSON / env**, not only committed constants.
2. **Authorizer mismatch** — Inventory Phase 2 requires **TimelockAuthorizer**. Current Wave B uses **NullAuthorizer** (explicitly out of scope as a promo shortcut).
3. **Incomplete Balancer surface** — Inventory includes Gyro, LBP, CoW, ReClamm; Wave B script only deploys Weighted / Stable / ConstProd packages.
4. **Attack mode linking** — One agreement already linking Create3Factory causes `AttackRegistry__ContractAlreadyLinked` on a second agreement for the same root. Greenfield: Phase 1 owns `requestAttackMode` for the new root; later phases **must skip** re-linking the same factory (children covered by `ChildContractScope.All`).
5. **Package CREATE3 non-idempotency** — Factory `*WithArgs` path historically reverts on re-run. **Prerequisite:** fix + tests before relying on resume-safe greenfield broadcasts (see create3 plan).
6. **Gas on BC** — Large facet CREATE3 needs elevated gas multiplier (`-g 400+`); scripts/runbooks must document this, not assume Foundry defaults.
7. **Later phases gate on port readiness** — Inventory marks many protocols “as ported” / “when ready”. Scripts for those phases are **not** required until the port has a known deploy path (DFPkg, factory, or stub set) and hermetic tests.

### 2.4 Out of scope for this program (inventory)

- IndexedEx product (DETF, CCA, RICH)
- NullAuthorizer as the Phase 2 production path
- Mainnet / Base promote
- `diamondCut` of the old factory
- Migrating state from abandoned gen-1 addresses

## 3. Problem statement

Operators and agents need to **greenfield-redeploy Crane on BattleChain in phases** without:

- accidentally targeting abandoned factory addresses,
- non-resumable mid-phase failures,
- undocumented address handoffs,
- inconsistent Safe Harbor / attack-mode handling,
- or scripts that diverge per protocol with no shared contract.

Today only Phase 1-ish and a partial Phase 2 script exist; they predate the greenfield decision and partially violate the inventory (stale binds, NullAuthorizer, incomplete pool types). There is no shared script framework for Phases 3–13.

## 4. Goals

### 4.1 Primary goals

| ID | Goal |
|----|------|
| **G1** | **Phase 1 greenfield script** deploys a new factory root + full inventory Phase 1 surface, agreement, and attack mode. |
| **G2** | **Phase 2 script** deploys full Balancer V3 inventory surface under the **new** root, with **TimelockAuthorizer**, binding prior phase via manifest (not abandoned constants alone). |
| **G3** | **Shared script platform** (base contract / helpers) so Phases 3–13 follow one pattern: bind prior, deploy surface, write manifest, optional attack-mode skip, docs handoff. |
| **G4** | **Manifest as source of truth** — every phase writes JSON + table under `docs/deployment/addresses/` (+ runtime copy under `script/output/`). |
| **G5** | **Docs/constants handoff** — after each phase: refresh phase JSON, update `BC_TESTNET` (or phase-scoped constants), Deployed Addresses; ready for X post (addresses on docs only). |
| **G6** | **Resume-safe & gas-safe** — re-broadcast same salts is no-op after factory fix; runbooks encode `-g 400+`, `--sender`, `--skip-simulation`. |
| **G7** | **Gate later phases on readiness** — script stubs or explicit “not ready” docs until port deploy path exists; no fake green deploys. |

### 4.2 Success metrics

| Metric | Target |
|--------|--------|
| New Create3Factory address | ≠ abandoned `0xC8E93C3c…AD3A` after Phase 1 |
| Phase 1 re-broadcast | Completes without revert; same addresses |
| Phase 2 factory bind | Resolves from Phase 1 JSON/env; fails if empty or abandoned address (configurable guard) |
| Phase 2 authorizer | TimelockAuthorizer (not NullAuthorizer) |
| Manifest completeness | Every deployed Crane-owned address present in JSON with role keys |
| Attack mode | Phase 1 requests for new root; Phase 2+ skip if factory already linked |
| Operator runbook | Copy-paste commands for Phase 1 and 2; pattern doc for later phases |
| X readiness | Docs URLs only; no raw hex dump required in social copy |

## 5. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| Completing unfinished protocol ports | Scripts deploy **as ported**; porting is separate work. |
| In-place upgrade of gen-1 factory | Operator: no diamondCut. |
| State migration from abandoned addresses | Greenfield only. |
| Redeploying BC-provided infra | Always bind WETH, Uni V3, mocks, SafeHarbor stack. |
| IndexedEx product deploy | Explicit inventory out-of-scope. |
| Base/mainnet promote scripts (this PRD) | Same salts later; separate promote PRD/runbook. |
| Automated X posting from scripts | Human posts; scripts only prepare docs handoff logs. |
| Full E2E protocol smoke for every phase in one PR | Per-phase verify checklist; expand as ports mature. |

## 6. Users & use cases

| Actor | Use case |
|-------|----------|
| **Human operator** | Fund deployer, unlock keystore, run forge script commands from runbook, verify on explorer, commit manifests, post X. |
| **Implementing agent** | Extend shared base, implement phase script from inventory checklist, write tests for bind/manifest logic where pure. |
| **Docs / release agent** | After “phase N complete” log, read JSON, update `BC_TESTNET` + Deployed Addresses, prepare X text. |
| **Attackers / whitehats** | Discover attackable surface via agreement + docs addresses (not this PRD’s code, but scripts must keep lineage correct). |

## 7. Requirements

### 7.1 Shared platform (all phase scripts)

Scripts **must**:

1. Extend `BCScript` (battlechain-lib) and use BattleChain helpers (`createAndAdoptAgreement`, `requestAttackMode`, BC chain checks) where applicable.
2. Use `InitBcService.initEnvBc` **only in Phase 1** for factory bootstrap; later phases **never** create a second factory root unless intentionally starting a new generation.
3. Require `--sender` matching the unlocked account; **revert** if broadcaster is Foundry default `0x1804…`.
4. Support **broadcast** and an internal `_runDeploy(...)` path usable from tests (no broadcast / no attack mode).
5. Resolve **prior-phase addresses** in this priority order:
   1. Env vars (e.g. `CREATE3_FACTORY`, `DIAMOND_FACTORY`, `PERMIT2`) when set  
   2. Manifest JSON path env (`WAVE_A_MANIFEST` / `PHASE_1_MANIFEST`) when set  
   3. `docs/deployment/addresses/battlechain-sepolia.json` (or generation-tagged path)  
   4. `BC_TESTNET` constants **only if** they match the current generation (optional guard: reject known-abandoned factory)
6. On BattleChain chain ID, `require` code at every bound address before deploying dependents.
7. Write manifests on success:
   - Docs JSON: `docs/deployment/addresses/<generation>-phase-N-<name>.json` (or evolved naming consistent with existing `battlechain-sepolia.json` / `…-balancer-v3.json`)
   - Docs table: sibling `.table.md` for mdBook include
   - Runtime: `script/output/battlechain-sepolia/<phase>.latest.json`
8. Log a **docs handoff** block: paths + one-line instruction for the follow-up agent.
9. **Reuse existing CREATE3 salt strings** from Launch/Wave B (D8); new factory address namespaces CREATE3. Do not require a generation salt rewrite.
10. Treat security contact placeholder as a **pre-public** gate: refuse public attack-mode announcement while contact is `REPLACE_BEFORE_BROADCAST@…` (script may still deploy; runbook requires replace before promo).

Scripts **must not**:

1. Call `diamondCut` on BattleChain factories.
2. Redeploy BC-provided WETH / Uni V3 / mocks / BC core infra.
3. `requestAttackMode` on a **new** agreement that re-scopes an already-linked Create3Factory (Phase 2+ must detect linkage and skip).
4. Hardcode only the abandoned gen-1 factory as the sole bind path after greenfield Phase 1 lands.

### 7.2 Idempotency & resume

| Layer | Requirement |
|-------|-------------|
| Factory | `create3` / `create3WithArgs` / package & facet deploy paths return existing code if predicted address has code (prerequisite factory fix). |
| Scripts | Prefer factory-level idempotency; temporary script short-circuits allowed until factory fix proven on BC. |
| Agreements | Salt uniqueness per generation; `SKIP_AGREEMENT=1` (or env) for resume when agreement already adopted. |
| Partial failures | Re-run same command; completed salts no-op; failed salts retry with higher `-g` if OOG. |

### 7.3 Phase 1 — Crane factory system

**Script:** evolve `Script_Promo_BC_Launch.s.sol` (or rename to generation-clear name, e.g. `Script_BC_Phase1_Factories.s.sol`, with alias docs).

| Deploy | Notes |
|--------|--------|
| Create3Factory + DiamondPackageCallBackFactory | Via `InitBcService.initEnvBc` |
| ERC20 / ERC5267 / ERC2612 facets | `deployFacet` |
| ERC20PermitDFPkg (+ optional sample token) | Package + diamond factory deploy |
| Uni V2 Factory + Router02 | CREATE3; router binds WETH |
| Uni V4 PoolManager | CREATE3 |
| BetterPermit2 | CREATE3 |
| Safe Harbor agreement | New salt; scope = **new** Create3Factory; `ChildContractScope.All` |
| `requestAttackMode` | On **this** agreement only |

**Bind only:** WETH, Uni V3 factory/router/NPM, BC SafeHarbor/Attack stack.

**Acceptance:**

- [ ] New factory address ≠ abandoned gen-1
- [ ] All Phase 1 Crane-owned addresses have code
- [ ] Agreement adopted; attack mode requested for new root
- [ ] Manifest overwrites docs JSON as SoT for this generation
- [ ] Re-broadcast succeeds (after factory idempotency fix)

### 7.4 Phase 2 — Balancer V3

**Script:** evolve `Script_Promo_BC_BalancerV3.s.sol` (or `Script_BC_Phase2_BalancerV3.s.sol`).

| Deploy | Notes |
|--------|--------|
| Vault facets + VaultDFPkg | CREATE3 / package paths under Phase 1 factory |
| **TimelockAuthorizer** | Replace NullAuthorizer; **minDelay = 1 hour**; admin = deployer (D2, D7) |
| ProtocolFeeController + Vault instance | Wire fee controller post-deploy |
| Router facets + RouterDFPkg + Router | `getVault()` = vault |
| Weighted / Stable / ConstProd packages | Required |
| Gyro 2-CLP + E-CLP packages | Required when code paths compile & tested |
| LBP package | Required when ready |
| CoW pool + CoW router packages | Required when ready |
| ReClamm | Required when ready |

**Bind:** Phase 1 factory, diamond factory, WETH, Permit2 (and any Phase 1 tokens needed).

**Attack mode:** detect factory linkage → **skip** `requestAttackMode` if already linked; log covering agreement address.

**Acceptance:**

- [ ] All required packages/instances under **new** factory
- [ ] TimelockAuthorizer in place (roles/delays configurable; document defaults for testnet)
- [ ] Vault loupe healthy; router points at vault
- [ ] Balancer manifest complete
- [ ] Double package deploy no-op on factory
- [ ] Docs + optional `BC_TESTNET` Balancer constants updated

**Sub-phasing (decided — D5):** Ship **2a first**, then **2b+**:

- **2a** Vault + Router + TimelockAuthorizer + Weighted/Stable/ConstProd  
- **2b+** Gyro / LBP / CoW / ReClamm as separate scripts **or** additive sections gated by env flags  

Inventory X copy must match what actually shipped.

### 7.5 Phases 3–13 — protocol scripts

Each phase **when ready** gets:

| Artifact | Description |
|----------|-------------|
| `Script_BC_PhaseN_<Protocol>.s.sol` | Bind Phase 1 (+ any hard deps from earlier phases), deploy protocol surface “as ported” |
| Manifest JSON/table | Protocol-specific address book |
| Runbook section | Commands, preconditions, verify checklist |
| X line | Per inventory wording |

**Readiness gate (before writing/broadcasting a phase script):**

1. Vendored/port code builds under Crane.  
2. Hermetic TestBase/Behavior (or documented minimum) exists for the deploy path.  
3. Known constructor/salt/init graph (what CREATE3 vs diamond package vs singleton).  
4. Explicit BC-provided deps list (oracles, tokens).  
5. Inventory phase still accurate (split/merge allowed for Phase 13-style buckets).

**Phase-specific notes (script PRD level, not full port specs):**

| Phase | Script focus |
|-------|----------------|
| 3 Aave | V3 pool/providers/config needed for dependents; V4 Hub/Spoke only if port ready |
| 4 Euler | EVC + EVK core deploy graph |
| 5 Comet | Markets + configurator + rewards |
| 6 Aero + Slipstream | Pools/router/voter/gauges + CL stack |
| 7 Uniswap | Crane services/ports beyond Phase 1 stubs (V3 already BC-provided — do not redeploy BC Uni V3) |
| 8 Camelot | V2 as ported |
| 9 Liquity/BOLD | As ported |
| 10 Sky | As ported |
| 11 Resupply | Registry/core surfaces as ported |
| 12 Reliquary | As ported |
| 13 Pendle/Frax/other | One script per mature slice; do not block on entire bucket |

### 7.6 Ops loop (every phase)

As inventory states:

1. Deploy under Phase 1 factory (or Phase 1 itself creates it).  
2. Write/update address manifest.  
3. Refresh `BC_TESTNET` + Deployed Addresses.  
4. X post (addresses on docs only).

Scripts implement steps 1–2 and **emit** handoff for 3–4; human/agent complete 3–4.

### 7.7 Broadcast CLI contract

Standard flags (all phases):

```bash
export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/<Script>.s.sol:<Contract> \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400
```

Raise `-g` to 500/600 if CREATE3 OOG on large facets. Document estimation procedure in runbooks (reuse Wave B gas troubleshooting).

## 8. Architecture

### 8.1 Recommended layout

```text
scripts/foundry/
  bc/
    BCPhaseScriptBase.s.sol          # shared: sender guard, manifest I/O, prior-phase bind
    Script_BC_Phase1_Factories.s.sol
    Script_BC_Phase2_BalancerV3.s.sol
    Script_BC_FullStack.s.sol        # Phase 1 then Phase 2 (convenience; D3)
    Script_BC_Phase3_Aave.s.sol      # when ready
    ...
  # Script_Promo_* retired as canonical names (D1); optional short-lived aliases only

docs/deployment/
  BC_GREENFIELD_INVENTORY.md
  BC_GREENFIELD_DEPLOYMENT_SCRIPTS_PRD.md   # this file
  addresses/
    battlechain-sepolia.json                 # Phase 1 SoT (generation overwrite)
    battlechain-sepolia-balancer-v3.json     # Phase 2
    battlechain-sepolia-<phase>.json         # later
  PHASE_1_FACTORIES_RUNBOOK.md
  PHASE_2_BALANCER_V3_RUNBOOK.md             # supersede / fold WAVE_B_* where appropriate
```

Exact directory nesting (`bc/` vs flat) is an implementation choice; **shared base** is not optional.

### 8.2 Dependency graph

```text
BC-provided (bind)
    │
    ▼
Phase 1: Create3Factory root + diamond factory + stubs + Permit2 + agreement + attack mode
    │
    ├──────────────► Phase 2: Balancer V3 (TimelockAuthorizer, vault, routers, pools)
    │
    ├──────────────► Phase 3+: lending/DEX/other (each binds Phase 1; may also bind Phase 2+ deps)
    │
    └──────────────► Phase 7 Uniswap extras (never redeploy BC Uni V3)
```

### 8.3 Manifest schema (minimum)

JSON objects should include at least:

| Field | Purpose |
|-------|---------|
| `chainId` | `627` |
| `generation` / `deployTag` | Greenfield generation id |
| `script` | Source path |
| `deployer` | Broadcaster EOA |
| `block` / `timestamp` | Optional provenance |
| `addresses` | Map of role → address (and optional `bcProvided: true`) |
| `agreement` | Safe Harbor agreement if created |
| `attackMode` | requested / skipped + covering agreement if skipped |
| `explorerBase` | `https://explorer.testnet.battlechain.com` |

Prefer additive keys over renaming existing Wave A/B keys when possible to ease docs agents.

### 8.4 Constants strategy

| Artifact | Role |
|----------|------|
| Manifest JSON | **Source of truth** immediately after broadcast |
| `BC_TESTNET.sol` | Committed constants for tests/scripts after human/agent handoff |
| Abandoned gen-1 | Document once as deprecated; do not keep as live CREATE3_FACTORY |

Optional: `BC_TESTNET_GEN1` archive library or comment block — do not leave two “live” factory constants without labels.

## 9. Security & Safe Harbor

1. **Single attackable root per generation:** Create3Factory with `ChildContractScope.All` covers diamonds, packages, facets, and CREATE3 children.  
2. **Phase 1** creates and attack-registers the agreement.  
3. **Phase 2+ never create agreements** (D6). Only manifests under the Phase 1 root; children covered by `ChildContractScope.All`.  
4. Recovery address defaults to deployer unless ops specify otherwise.  
5. Real security contact before public attack-mode marketing.  
6. Never announce abandoned gen-1 addresses as current attack surface after cutover.

## 10. Testing strategy

| Layer | What |
|-------|------|
| Unit | Factory `*WithArgs` double-deploy (prerequisite) |
| Script unit (optional) | Bind resolution priority; abandoned-address guard; attack-mode skip logic via harness |
| Fork / BC dry | Prefer local `InitBcService` patterns already used in TestBases; live BC is the real gate |
| Post-deploy verify | Cast `code` checks, vault loupe, router `getVault`, package code presence — checklist in runbook |

CI does **not** need to broadcast to BattleChain. CI should keep building scripts under `FOUNDRY_PROFILE` constraints that still compile phase scripts (or isolate heavy protocol scripts if OOM).

## 11. Deliverables & milestones

### M0 — Prerequisites

- [ ] Idempotent `*WithArgs` factory paths + tests  
- [ ] Agreement on generation tag / salt prefix  
- [ ] Abandoned factory address recorded for guards  

### M1 — Shared base + Phase 1 greenfield

- [ ] `BCPhaseScriptBase` (or equivalent)  
- [ ] Phase 1 script greenfield-ready  
- [ ] Phase 1 runbook + commands  
- [ ] Live BC Phase 1 broadcast + manifests  
- [ ] `BC_TESTNET` + Deployed Addresses for Phase 1  
- [ ] X: factories + core stubs  

### M2 — Phase 2 Balancer complete (inventory-aligned)

- [ ] Bind from Phase 1 manifest  
- [ ] TimelockAuthorizer  
- [ ] Full pool-type set or explicit 2a/2b split documented in inventory  
- [ ] Live BC Phase 2 + manifests + docs  
- [ ] X: Balancer V3 ready  

### M3 — Phase script template for 3–13

- [ ] Template script + manifest helpers  
- [ ] Readiness checklist documented  
- [ ] First later phase (likely Aave or highest-readiness port) proves template  

### M4 — Ongoing

- [ ] One script + runbook + X per inventory phase as ports mature  
- [ ] Inventory updated if phases split/merge  

## 12. Risks

| Risk | Mitigation |
|------|------------|
| Script still points at abandoned factory | Manifest/env first; reject known abandoned address |
| Agents update docs from stale JSON | Overwrite SoT JSON on each successful Phase 1; commit with constants |
| TimelockAuthorizer misconfig locks vault admin on testnet | Sensible testnet delays; document role holders = deployer; escape hatch only if intentional |
| Incomplete ports force half-scripts | Readiness gate; sub-phase flags; honest X copy |
| Gas OOG mid-phase | `-g 400+`; factory idempotency for resume |
| Double attack-mode revert | Skip when factory already linked |
| Stack-too-deep in large scripts | Split helpers (existing Wave A pattern); no viaIR |
| Naming churn (Promo vs Phase) | Aliases + docs map; one canonical name per phase |

## 13. Resolved decisions (2026-07-23)

| # | Topic | Decision |
|---|--------|----------|
| D1 | **Naming** | Rename to `Script_BC_PhaseN_*` **now** (e.g. `Script_BC_Phase1_Factories`, `Script_BC_Phase2_BalancerV3`). Drop `Script_Promo_*` as the canonical names; optional thin aliases only if needed for a short transition. |
| D2 | **TimelockAuthorizer** | **Deployer as admin**; **short testnet delays** (e.g. ≤ 1 day) so BC promo ops stay practical. Document exact `minDelay` in the Phase 2 script/runbook. |
| D3 | **Full-stack script** | **Yes** — add `Script_BC_FullStack.s.sol` chaining Phase 1 then Phase 2 for operator convenience. Standalone Phase 1/2 scripts remain primary and must work alone. |
| D4 | **Manifest paths** | **Overwrite** `battlechain-sepolia.json` (and Phase 2 balancer JSON) as live SoT. Gen-1 abandoned; do not keep gen-1 as the live path. |
| D5 | **Phase 2 bar** | **Ship 2a first**, then **2b+** pool types. **2a:** vault + TimelockAuthorizer + router + Weighted/Stable/ConstProd. **2b+:** Gyro 2-CLP/E-CLP, LBP, CoW pool+router, ReClamm when ready. X copy must match what shipped. |
| D6 | **Agreements** | **One agreement per generation only.** Phase 1 creates/adopts + `requestAttackMode` on Create3Factory (`ChildContractScope.All`). Later phases **never** create agreements; children are covered by factory scope. |
| D7 | **Timelock minDelay** | **1 hour** on BC testnet (admin = deployer). |
| D8 | **CREATE3 salts** | **Reuse existing salt strings** (`bc-promo-*`, Wave B salts, etc.). New factory root already namespaces addresses; no generation salt rewrite required. |
| D9 | **Phase 1 sample token** | **Include** CBCP-style sample ERC20Permit diamond (proves package + diamond factory). |
| D10 | **FullStack shape** | **One Solidity script, one forge broadcast** — `run()` executes Phase 1 then Phase 2. Standalone Phase 2 remains for resume after partial FullStack failure. |
| D11 | **Phase 2a router surface** | **Match current Wave B** router facet set (swap/add/remove/init/common/batch/buffer/composite) + Weighted/Stable/ConstProd packages. |
| D12 | **Abandoned factory guard** | **Hard revert** if bound `CREATE3_FACTORY` equals gen-1 `0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A` (and document that constant as `ABANDONED_CREATE3_FACTORY`). |

### Implications for implementation

- Phase 2 script: no `createAndAdoptAgreement` / no secondary agreement salt; attack-mode skip is default (factory already linked by Phase 1).
- Full-stack script: single broadcast session; must still write both Phase 1 and Phase 2 manifests; mid-Phase-2 failure → re-run Phase 2 alone (factory idempotency + D12 guard on Phase 1 address).
- Inventory X for first Balancer ship: wording for 2a only until 2b+ lands.
- Promo script filenames in existing runbooks (`WAVE_B_*`, `battlechain.md`) need a follow-up path update when renames land.
- TimelockAuthorizer: `minDelay = 1 hours`; deployer is admin.
- Keep salt strings from Launch/Wave B; do not invent `crane-bc-gf-*` salts for this cutover.
- Shared base: constant for abandoned factory + `require(factory != ABANDONED, ...)`.

## 14. Acceptance criteria (program)

This PRD is satisfied when:

1. Phase 1 and Phase 2 scripts meet §7.3–7.4 and have been broadcast on BC testnet under a **new** factory root.  
2. Shared bind/manifest/attack-skip patterns exist for later phases.  
3. Inventory ops loop is executable from runbooks without tribal knowledge.  
4. Abandoned gen-1 is not the live bind target in scripts or `BC_TESTNET`.  
5. No diamondCut was used to “repair” gen-1.  
6. Remaining phases have a clear template + readiness gate, even if not yet implemented.

## 15. References

| Doc / code | Role |
|------------|------|
| [`BC_GREENFIELD_INVENTORY.md`](./BC_GREENFIELD_INVENTORY.md) | Phase scope + X lines + ops loop |
| [`battlechain.md`](./battlechain.md) | BC security gate policy |
| [`2026-07-23-create3-package-idempotency-and-bc-redeploy.md`](../superpowers/plans/2026-07-23-create3-package-idempotency-and-bc-redeploy.md) | Factory fix + greenfield decision |
| [`2026-07-23-bc-balancer-v3-wave-b.md`](../superpowers/plans/2026-07-23-bc-balancer-v3-wave-b.md) | Prior Wave B plan (NullAuthorizer era) |
| [`WAVE_B_BALANCER_V3_RUNBOOK.md`](./WAVE_B_BALANCER_V3_RUNBOOK.md) | Gas, attack-mode skip lessons |
| `scripts/foundry/Script_Promo_BC_Launch.s.sol` | Phase 1 baseline |
| `scripts/foundry/Script_Promo_BC_BalancerV3.s.sol` | Phase 2 baseline |
| `contracts/constants/networks/BC_TESTNET.sol` | Committed constants (to be rewritten post-greenfield) |
| `contracts/InitBcService.sol` | Factory bootstrap on BC |
| `docs/protocols/status.md` | Port maturity honesty |

---

## Appendix A — Inventory → script checklist (quick)

| Phase | Script name (proposed) | Status |
|-------|------------------------|--------|
| 1 Factories | `Script_BC_Phase1_Factories` | Evolve from Launch |
| 2 Balancer V3 | `Script_BC_Phase2_BalancerV3` | Evolve from Balancer Wave B |
| 3 Aave | `Script_BC_Phase3_Aave` | Not started |
| 4 Euler | `Script_BC_Phase4_Euler` | Not started |
| 5 Comet | `Script_BC_Phase5_Comet` | Not started |
| 6 Aerodrome+Slipstream | `Script_BC_Phase6_Aerodrome` | Not started |
| 7 Uniswap extras | `Script_BC_Phase7_Uniswap` | Not started |
| 8 Camelot | `Script_BC_Phase8_Camelot` | Not started |
| 9 Liquity | `Script_BC_Phase9_Liquity` | Not started |
| 10 Sky | `Script_BC_Phase10_Sky` | Not started |
| 11 Resupply | `Script_BC_Phase11_Resupply` | Not started |
| 12 Reliquary | `Script_BC_Phase12_Reliquary` | Not started |
| 13 Pendle/Frax/… | Per-slice scripts | Not started |

## Appendix B — Review notes (inventory quality)

The inventory is **directionally correct and operationally usable** as a phase backlog. For script work it is intentionally thin on:

- constructor/init order inside each protocol,  
- exact salt lists,  
- TimelockAuthorizer parameters,  
- and which later phases have a compile-ready deploy graph.

That thinness is appropriate for an inventory; **this PRD** owns script contracts, bind rules, manifests, and readiness gates. Keep inventory as the human-facing phase list + X copy; keep this PRD as the engineering contract for implementers.
