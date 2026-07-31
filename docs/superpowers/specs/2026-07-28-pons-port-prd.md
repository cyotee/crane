---
project: pons (ponsfamily) launchpad port into Crane
version: 1.1
status: draft
created: 2026-07-28
last_updated: 2026-07-28
owner: Crane core
decisions_locked: 2026-07-28
related:
  - docs/superpowers/plans/2026-07-28-pons-port.md
  - docs/archive/internal-plans/PONS_PORTING_PRD.md
  - docs/archive/internal-plans/DEFI_PORTING_PRD.md
  - .claude/skills/crane-porting/SKILL.md
  - .claude/skills/crane-porting-verification/SKILL.md
  - .claude/skills/pons-architecture/SKILL.md
  - .claude/skills/pons-integration/SKILL.md
  - .claude/skills/pons-operations/SKILL.md
  - contracts/constants/networks/ROBINHOOD_MAIN.sol
  - contracts/protocols/dexes/uniswap/v3/
  - contracts/protocols/launchpads/ponsFamily/
upstream:
  - https://github.com/ponsdotdev/ponsfamily
official_docs:
  - https://docs.ponsfamily.com/
  - https://docs.ponsfamily.com/llms.txt
---

# PRD: Port pons (ponsfamily) into Crane

## 0. Locked product decisions (2026-07-28)

| Topic | Decision |
|-------|----------|
| **First merge (“done”)** | **Minimum:** vendor + compile + hermetic `launchToken` + Robinhood fork bind. Service / Aware / Behaviors / full docs = follow-up unless free with the same PR. |
| **Domain path** | Upstream `contracts/src/**` → `contracts/protocols/launchpads/ponsFamily/pons/` |
| **OZ / shared deps** | **Reuse** Crane `contracts/external/...` (OZ v5 where semantics require). If a required symbol is missing, **expand external first**, then remap — do not nest a private OZ tree under `ponsFamily`. |
| **Wrappers path** | Crane surface (services, aware, stubs, test bases) under `contracts/protocols/launchpads/ponsFamily/` (sibling of `pons/`) |
| **Diamond / DFPkg** | **Not** in minimum or P0 packaging; Service + Aware + TestBase when wrappers land |
| **“v2”** | **Not in this port.** See §0.1 — docs-only product narrative; no v2 source in `ponsfamily` GitHub. |
| **Hermetic locker** | **Minimal stub** implementing `IPonsLaunchLocker` |
| **Seed buy / router** | **Real Uniswap V3 periphery only** — no thin router stub. Phase 0 spike: ensure Crane periphery (or real SwapRouter02 deploy) matches factory call shape; if mismatch, fix periphery wiring or adapt factory dex config to a real Crane-deployable router — do not invent a fake router. |
| **TestBase configs** | **Mirror live docs** (1% fee, 1e9 supply, ~4.2 ETH graduation, anti-snipe windows) |
| **Fork coverage (min)** | **Active** factory + locker only |
| **Fork CI** | **Opt-in:** requires `FOUNDRY_PROFILE` and Robinhood RPC **alias from `foundry.toml`** (`robinhood_mainnet` / related) |
| **Primary consumers** | Hermetic/integration testing **and** IndexedEx / strategy vaults |
| **Greenfield redeploy** | **Testnets only** (e.g. Robinhood testnet / local anvil) — not general multi-chain product deploy |

### 0.1 Clarification: why “pons v2” appeared in the draft PRD

There is **no separate public Solidity repository** for a “pons v2” in the
[ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) tree used for
this port. That GitHub repo is the **v1** CREATE2 + Uniswap V3 launchpad
(`PonsLaunchFactory`, `PonsLauncherToken`, etc.).

“v2” was mentioned because:

1. Official product docs publish a **v2** section at
   [docs.ponsfamily.com/v2](https://docs.ponsfamily.com/v2) describing a bonding
   curve → Uniswap V4 graduation model (and state that mainnet addresses are not
   published / audits in progress).
2. Crane already has **docs-scraped agent skills**
   (`.claude/skills/pons-architecture`, etc.) that summarize that v1 vs v2
   product narrative for integrators.

**This port is scoped only to the open-source `ponsfamily` contracts (v1).**  
Do not vendor, stub, or claim a v2 protocol surface unless a real source pin and
addresses appear later under a new PRD.

---

## 1. Purpose

Port the **pons** token launchpad smart contracts from
[ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) into Crane as a
**faithful domain port** with shared dependencies remapped to Crane’s existing
external trees.

**Domain home:**

```text
contracts/protocols/launchpads/ponsFamily/pons/
```

**Crane integration home (wrappers, stubs, TestBases):**

```text
contracts/protocols/launchpads/ponsFamily/
├── pons/                 # upstream contracts/src
├── services/             # post-minimum / P0 follow-up
├── aware/
├── stubs/
└── test/bases/
```

so that:

1. Hermetic Foundry tests can deploy real pons bytecode (factory, token, math)
   against Crane’s Uniswap V3 hermetic stack — not mocks of the SUT.
2. Robinhood Chain fork tests (profile-gated) can bind the live **active** factory,
   locker, WETH, and V3 stack via network constants + `foundry.toml` RPC aliases.
3. Hermetic and IndexedEx strategy work can later use Service / Aware / TestBase
   without re-inventing launch ABI glue (wrappers may land after the minimum merge).

This PRD is the **authoritative definition of what to port, in what order, and
when it is done**. Product architecture for agents already exists under
`.claude/skills/pons-*`; this PRD covers the **Solidity vendoring and
verification** work those skills assume.

**Product name:** always **pons** (lowercase). Repo / path name: `ponsFamily` /
`ponsfamily`.

---

## 2. Problem statement

Crane already has:

| Asset | Status |
|-------|--------|
| Uniswap V3 core + periphery + `TestBase_UniswapV3` / `TestBase_UniswapV3Periphery` | Present |
| Robinhood mainnet constants (WETH, V3 factory/PM/router/quoter) | Present in `ROBINHOOD_MAIN` |
| Agent skills for pons architecture / ops / integration | Present (docs-derived) |
| Empty target directory | `contracts/protocols/launchpads/ponsFamily/` |
| CCA launchpad port pattern under `launchpads/uniswap/continuous-clearing/` | Present (layout reference) |

Crane does **not** yet include:

| Gap | Impact |
|-----|--------|
| Vendored `PonsLaunchFactory` / `PonsLauncherToken` / math / interfaces | Cannot hermetically launch or test pons flows |
| Network constants for **active** factory + locker | Fork tests invent addresses |
| `TestBase_PonsFamily` chain | No shared setup for launchpad consumers |
| Minimal locker stub | Locker is **not** in the upstream source tree (interface only) |
| Service / Aware (post-minimum) | IndexedEx strategies lack idiomatic helpers until follow-up |

Without this port, launchpad strategies, bots, and IndexedEx integrations either
mock pons (forbidden for SUT) or depend only on fragile live fork state.

---

## 3. Goals

### 3.1 Minimum merge (first ship — required)

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G1** | Faithful domain port from GitHub `contracts/src` | Under `ponsFamily/pons/`; compiles under Crane solc **0.8.35** |
| **G2** | Shared-dep remap (no private OZ tree) | Reuse / expand `contracts/external/...`; imports `@crane/contracts/external/...` (OZ **v5** semantics where required) |
| **G3** | Hermetic launch path | Minimal locker stub + **real** V3 factory/PM/**periphery router** → `launchToken` → pool + locked NFT (+ seed buy if real router supports factory ABI) |
| **G4** | Predictable addresses | `predictTokenAddress` matches CREATE2 deploy |
| **G5** | Graduation reads | `graduationStatus` from locked position principal |
| **G6** | Anti-snipe behavior | Restriction window enforced then lifts |
| **G7** | Active network constants | Active factory + locker on `ROBINHOOD_MAIN` |
| **G8** | Fork bind (profile-gated) | `FOUNDRY_PROFILE` + `foundry.toml` Robinhood RPC alias; `code.length > 0` + read launch record |

### 3.2 Follow-up (same program, not required for first merge)

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G9** | Crane wrappers | `PonsLaunchService` + `PonsLaunchAwareRepo` + Behaviors |
| **G10** | Docs & skills | CODEBASE_MAP + `docs/protocols/status.md`; skills point at on-disk paths |
| **G11** | Testnet greenfield smoke | Deploy factory + stub locker on RH testnet / anvil with real Uni V3 stack |
| **G12** | Legacy constants (optional) | Legacy factory/locker for indexer historical work |

---

## 4. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| **Product “v2” launchpad** (curve → V4) | **No source in this GitHub repo**; only product docs / agent skills (§0.1). Not part of this port. |
| Re-implementing Uniswap V3 | Reuse Crane `protocols/dexes/uniswap/v3/` |
| Thin / fake swap routers for seed buy | **Real periphery only** (locked decision) |
| Frontend, subgraphs, HTTP APIs | Off-chain |
| Diamond Facet / DFPkg in this program’s first ships | Service + Aware + TestBase when wrappers land |
| General multi-chain greenfield product deploy | **Testnets only** for redeploy experiments |
| Nesting OZ under `ponsFamily/` | Expand `contracts/external` then remap |
| Claiming official partnership | Product name **pons** lowercase only |
| Enabling `viaIR` | Forbidden |
| Bytecode-identical live locker | Source unpublished; minimal stub hermetic only |

---

## 5. Non-negotiable policy

Aligned with `crane-porting` and `DEFI_PORTING_PRD` A.4–A.6:

1. **Faithful domain, remapped deps.** pons contracts stay logic-equivalent to a
   pinned upstream commit; OZ goes through `@crane/contracts/external/...`.
2. **No new git submodules.** Copy sources in; pin in `VENDOR.md`.
3. **No new Foundry remapping aliases** for pons; use `@crane/` imports only.
4. **Do not vendor** `contracts/lib/openzeppelin-contracts/` from upstream under
   `ponsFamily/` (anti-pattern; see CCA legacy `dependencies/` debt).
5. **Production-first tests.** Never `vm.mockCall` factory/token as SUT; use
   ported bytecode or live forks.
6. **OZ major must match behavior.** Upstream tree is OZ **v5**-shaped
   (`Ownable(initialOwner)`, IERC1363 / draft-IERC6093 in their vendor set).
   Prefer **`@crane/contracts/external/openzeppelin-contracts-v5/...`**. Expand
   that tree if a file is missing. Do **not** silently use OZ 4.9.6 when
   constructors/errors differ.
7. **Semantic routing:** OZ Ownable / Context / ERC20 stay OZ-semantic. Do **not**
   swap onto Crane-native Ownable during “dedup”.
8. **Pragma:** relax `^0.8.30` to Crane **0.8.35** only as needed; document each
   change in `VENDOR.md`.
9. **Licenses:** preserve SPDX headers. Domain is **MIT** (sources); `PonsTickMath`
   is **GPL-2.0-or-later**. Record in `VENDOR.md`. (GitHub has no root `LICENSE`
   file as of research date — treat SPDX as authoritative.)
10. **Real periphery only** for hermetic swaps/seed buy — no invented router fakes.
11. **Fork tests** require an explicit `FOUNDRY_PROFILE` and the Robinhood RPC
    alias already defined in `foundry.toml` (not always-on public CI).

---

## 6. Users and use cases

### 6.1 Primary users

| User | Need |
|------|------|
| Hermetic / integration testing | Reproducible launch + anti-snipe + graduation |
| IndexedEx / strategy vaults | Real pons SUT for strategy tests; Service later |
| CI | Hermetic always; fork only under `FOUNDRY_PROFILE` + RH RPC alias |
| Agents / integrators | Constants + typed interfaces; no invented addresses |

### 6.2 Core use cases

1. **Hermetic launch:** configure dex + launch config → `launchToken` → assert
   CREATE2 address, pool, position NFT at locker, `getLaunchedToken` fields.
2. **Optional seed buy:** pay `launchFee + buyValue` → token lands at fee wallet /
   initial buy recipient per factory rules.
3. **Trade after launch:** buy/sell via V3 router against the launched pool;
   assert anti-snipe reverts in window and success after `restrictionsEndBlock`.
4. **Graduation read:** fund pool until locked principal ≥ threshold →
   `graduationStatus` reports graduated.
5. **Fork bind:** on Robinhood mainnet, bind active factory; read a known launched
   token (e.g. reference PONS) and pool state.
6. **Consumer CraneTest:** strategy test uses `PonsLaunchService` without
   re-encoding factory calldata.

---

## 7. Upstream repository inventory

**Source:** [ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily)  
**Default branch pin (research 2026-07-28):** `main` @
`60fcd76499a8d84caa09a1b252b0b1ae46a7bd86`  
**Confirm at copy time** with `git ls-remote` / tag if one is cut later.

### 7.1 Must-port (P0)

| Path (upstream) | Role | Crane destination |
|-----------------|------|-------------------|
| `contracts/src/PonsLaunchFactory.sol` | CREATE2 factory: configs, launch, graduation | `.../ponsFamily/pons/PonsLaunchFactory.sol` |
| `contracts/src/PonsLauncherToken.sol` | Fixed-supply ERC-20 + anti-snipe + metadata | `.../ponsFamily/pons/PonsLauncherToken.sol` |
| `contracts/src/interfaces/ILaunchpad.sol` | Thin V3 + locker + factory surfaces | `.../ponsFamily/pons/interfaces/` |
| `contracts/src/libraries/PonsLiquidityMath.sol` | Locked liquidity → principal | `.../ponsFamily/pons/libraries/` |
| `contracts/src/libraries/PonsTickMath.sol` | Tick → sqrtPriceX96 (GPL-2.0-or-later) | `.../ponsFamily/pons/libraries/` |

### 7.2 Vendor metadata / non-Solidity (optional copy)

| Path | Action |
|------|--------|
| `README.md` | Summarize in `VENDOR.md`; do not treat as runtime |
| `abi.json` | Optional under `.../ponsFamily/artifacts/` or docs — frontend ABI for active factory |
| `contract-meta.json` | Pin compiler notes: solc **0.8.30**, optimizer **runs 300**, EVM **cancun** |
| `contracts/src/examples/**`, `media/**` | **Exclude** (assets only) |
| `contracts/lib/openzeppelin-contracts/**` | **Do not copy** — remap |

### 7.3 Not in upstream repo (must invent Crane-side)

| Component | Handling |
|-----------|----------|
| **Pons launch locker** implementation | Interface `IPonsLaunchLocker` only. Hermetic: **minimal** `stubs/PonsLaunchLockerStub.sol` (custody NFT, `protocolFeeRecipient`, `lockPosition`, `setFeeRedirect`). Fork: bind live **active** locker. |
| **Legacy factory bytecode** | Optional later; not required for minimum fork suite. |
| **Product “v2” contracts** | Not in this repo — not ported (§0.1). |

### 7.4 Live deployment map (Robinhood mainnet, chain 4663)

From official docs / existing Crane pons skills (verify on copy):

| Role | Address |
|------|---------|
| Active factory (`PonsLaunchFactory`) | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` |
| Active locker | `0x736D76699C26D0d966744cAe304C000d471f7F35` |
| Legacy factory | `0x0c37a24F5D23A486FA692d1500881d698B1F77a4` |
| Legacy locker | `0x31ca5E101941A93A7DD6d0497928700625CF54B5` |
| Uniswap V3 factory | `0x1f7d7550B1b028f7571E69A784071F0205FD2EfA` (= `ROBINHOOD_MAIN.UNISWAP_V3_FACTORY`) |
| Position manager | `0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3` |
| Swap router | `0xCaf681a66D020601342297493863E78C959E5cb2` |
| Quoter V2 | `0x33e885eD0Ec9bF04EcfB19341582aADCb4c8A9E7` |
| WETH (quote) | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` |
| Active factory start block | **8991118** |
| Legacy factory start block | **8600612** |

**Reference token (legacy factory, graduated):**

| Field | Value |
|-------|--------|
| Token | `0x39dBED3a2bd333467115dE45665cC57F813C4571` |
| Pool | `0x10CC6BD38112cAc182db90B6a71d8Bb5939526bA` |

### 7.5 Upstream API surface (consumer-facing)

#### Factory (`PonsLaunchFactory`)

| Category | Symbols |
|----------|---------|
| Views | `dexConfigCount`, `launchConfigCount`, `getDexConfig`, `getLaunchConfig`, `getLaunchedToken`, `graduationStatus`, `locker`, `launchFee`, … |
| Owner | `addDexConfig`, `setDexStatus`, `addLaunchConfig`, `updateLaunchConfig`, `setLaunchFee`, `setLaunchEnabled`, `setWhitelistedLauncher` |
| Launch | `launchToken(TokenParams, launchConfigId, dexId, salt)` payable |
| Predict | `predictTokenAddress`, `predictVanityTokenAddress`, `hasVanitySuffix` |
| Events | `TokenDeployed`, `TokenLaunched`, config/fee/whitelist updates |
| Key structs | `TokenParams`, `DexConfig`, `LaunchConfig`, `Socials`, `LaunchedToken` |

#### Token (`PonsLauncherToken`)

| Category | Symbols |
|----------|---------|
| Metadata | `liquidityPool`, `socials`, `getTokenInfo`, logo/description immutables |
| Limits | `maxWalletLimit` / `maxWalletAmount`, `maxTxLimit` / `maxTxAmount` |
| Errors | `LaunchBlockBuyBlocked`, `MaxWalletExceeded`, `MaxTxExceeded`, `NotLaunchFactory` |

#### Interfaces (`ILaunchpad.sol`)

Thin “Like” interfaces for V3 factory/pool/PM/routers + `IPonsLaunchFactory` +
`IPonsLaunchLocker`. Prefer keeping these for faithful factory compile; optional
later align with Crane’s full `IUniswapV3*` types where signatures match.

---

## 8. Architecture and target layout

### 8.1 Placement decision (locked)

| Layer | Path |
|-------|------|
| Domain (upstream `contracts/src`) | `contracts/protocols/launchpads/ponsFamily/pons/` |
| Crane stubs / TestBases / (later) services | `contracts/protocols/launchpads/ponsFamily/` |
| Shared OZ / Uni / etc. | `contracts/external/...` and existing Uni V3 ports — **never** under `pons/` |

### 8.2 Proposed tree

```text
contracts/protocols/launchpads/ponsFamily/
├── VENDOR.md
├── pons/                              # ← upstream contracts/src
│   ├── PonsLaunchFactory.sol
│   ├── PonsLauncherToken.sol
│   ├── interfaces/ILaunchpad.sol
│   └── libraries/
│       ├── PonsLiquidityMath.sol
│       └── PonsTickMath.sol
├── stubs/
│   └── PonsLaunchLockerStub.sol       # minimal IPonsLaunchLocker
├── services/                          # follow-up (not min-merge required)
│   └── PonsLaunchService.sol
├── aware/
│   └── PonsLaunchAwareRepo.sol
└── test/bases/
    ├── TestBase_PonsFamily.sol        # hermetic: real V3 periphery + factory + stub
    └── TestBase_PonsFamily_Fork.sol   # FOUNDRY_PROFILE + RH RPC alias

test/foundry/spec/protocols/launchpads/ponsFamily/
├── hermetic/
│   ├── PonsLaunchFactory_launch.t.sol
│   ├── PonsLaunchFactory_predict.t.sol
│   ├── PonsLaunchFactory_graduation.t.sol
│   └── PonsLauncherToken_restrictions.t.sol
└── fork/                              # profile-gated
    └── PonsLaunchFactory_RobinhoodFork.t.sol
```

**TestBase inheritance (recommended):**

```text
CraneTest
  └── TestBase_Weth9
        └── TestBase_UniswapV3
              └── TestBase_UniswapV3Periphery   # real PM + real router
                    └── TestBase_PonsFamily
```

**Configs:** mirror live docs (fee `10000`, tick spacing `200`, supply `1e9`,
graduation threshold ~`4.2 ether` paired principal, anti-snipe windows as documented).

### 8.3 Dependency substitution map

| Upstream dependency | Crane target | Action |
|---------------------|--------------|--------|
| `@openzeppelin/contracts/...` (v5-shaped) | `@crane/contracts/external/openzeppelin-contracts-v5/...` | Reuse; **expand external** if missing |
| Uniswap V3 factory / pool / PM / router | Hermetic: Crane V3 + **real** periphery; Fork: `ROBINHOOD_MAIN.UNISWAP_V3_*` | No re-vendor under pons; **no fake router** |
| Thin V3 interfaces in `ILaunchpad.sol` | Keep for faithful factory compile | Align router ABI with real periphery in Phase 0 |
| Locker implementation | `stubs/PonsLaunchLockerStub.sol` | Minimal |
| WETH | `TestBase_Weth9` / `ROBINHOOD_MAIN.WETH` | Reuse |

**Import rule:** all new/edited code uses `@crane/contracts/...` only.

### 8.4 Surfaces by ship stage

#### Minimum merge

| Symbol | Responsibility |
|--------|----------------|
| Domain under `pons/` | Faithful factory + token + libs |
| `PonsLaunchLockerStub` | Minimal locker |
| `TestBase_PonsFamily` | Hermetic deploy + live-like configs |
| `TestBase_PonsFamily_Fork` | Active factory/locker bind |
| Active constants | `ROBINHOOD_MAIN` |

#### Follow-up wrappers

| Symbol | Responsibility |
|--------|----------------|
| `PonsLaunchService` | launch / predict / graduation helpers for IndexedEx strategies |
| `PonsLaunchAwareRepo` | factory / locker / default config ids |
| `Behavior_IPonsLaunchFactory` | consumer view validation |

**Not in scope for this program’s early ships:** Diamond Facet / DFPkg (later if a Diamond consumer appears).

---

## 9. Network constants

**Minimum (required):**

```text
PONS_LAUNCH_FACTORY_ACTIVE    // 0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB
PONS_LAUNCH_LOCKER_ACTIVE     // 0x736D76699C26D0d966744cAe304C000d471f7F35
PONS_ACTIVE_START_BLOCK       // 8991118
```

**Optional follow-up:** legacy factory/locker, reference token/pool.

**RPC / CI:**

- Use `foundry.toml` aliases: `robinhood_mainnet` (and testnet aliases if greenfield smoke).
- Fork suite only under **`FOUNDRY_PROFILE`** (name to be chosen at implementation, e.g. `pons_fork` or reuse an existing RH profile) — hermetic suite always runs in default CI.

---

## 10. Functional requirements

### 10.1 Domain vendoring (minimum)

| ID | Requirement |
|----|-------------|
| FR-D1 | Copy GitHub `contracts/src/**` into `protocols/launchpads/ponsFamily/pons/` |
| FR-D2 | Write `VENDOR.md` at `ponsFamily/` (pin, license, OZ external policy, locker note) |
| FR-D3 | Remap OZ to existing/expanded `@crane/contracts/external/openzeppelin-contracts-v5/...`; **no** nested OZ |
| FR-D4 | Compile under Crane 0.8.35 without `viaIR` |
| FR-D5 | Preserve MIT / GPL-2.0-or-later SPDX headers |

### 10.2 Hermetic factory + token (minimum)

| ID | Requirement |
|----|-------------|
| FR-H1 | Minimal `PonsLaunchLockerStub` for launch + fee recipient |
| FR-H2 | Deploy factory with owner + locker + launch fee |
| FR-H3 | DexConfig uses **real** V3 factory, PM, and **real** periphery router (ABI-compatible) |
| FR-H4 | LaunchConfig mirrors live docs (1e9 supply, anti-snipe, ~4.2 ETH graduation, WETH pair) |
| FR-H5 | `launchToken` succeeds: CREATE2 token, pool, one-sided mint, NFT at locker |
| FR-H6 | `predictTokenAddress` equals deployed token |
| FR-H7 | Seed buy path with **real** router only (Phase 0 resolves SwapRouter02 vs Crane SwapRouter) |
| FR-H8 | Anti-snipe window enforced |
| FR-H9 | Post-window unrestricted ERC-20 behavior |
| FR-H10 | `graduationStatus` reflects locked principal vs threshold |

### 10.3 Fork (minimum)

| ID | Requirement |
|----|-------------|
| FR-F1 | Active factory + locker constants; `code.length > 0` on fork |
| FR-F2 | At least one successful read of `getLaunchedToken` and/or `graduationStatus` against a live token |
| FR-F3 | Suite gated by `FOUNDRY_PROFILE` + Robinhood RPC alias from `foundry.toml` |

### 10.4 TestBase (minimum)

| ID | Requirement |
|----|-------------|
| FR-T1 | `TestBase_PonsFamily` inherits real Uni V3 periphery chain; idempotent deploy |
| FR-T2 | Live-like default configs |

### 10.5 Follow-up (not minimum)

| ID | Requirement |
|----|-------------|
| FR-W1 | `PonsLaunchService` + tests |
| FR-W2 | `PonsLaunchAwareRepo` |
| FR-W3 | Focused Behavior library |
| FR-DOC1 | CODEBASE_MAP / status / skills path updates |
| FR-G1 | Testnet / anvil greenfield smoke (factory + stub + real V3) |
| FR-L1 | Optional legacy factory/locker constants |

### 10.6 Explicitly out

| ID | Requirement |
|----|-------------|
| — | Diamond / DFPkg (later, if needed) |
| — | Product “v2” domain (no source in this repo) |
| — | Thin fake routers |

---

## 11. Test strategy

Follow `crane-porting-verification` and production-first rules in `crane-testing`.

| Layer | When | Pass criteria |
|-------|------|---------------|
| **Compile** | Minimum | `forge build` without viaIR |
| **Hermetic** | Minimum | Real factory/token + real V3 periphery + minimal locker stub |
| **Fork** | Minimum (profile-gated) | Active factory/locker code + launch record read |
| **Service / Behavior** | Follow-up | Helpers match direct factory calls |
| **Testnet greenfield** | Follow-up | Deploy factory on RH testnet / anvil |

### 11.1 Minimum hermetic scenarios

1. Launch without seed buy → fee paid, position locked, record exists.
2. Launch with seed buy via **real** router (once ABI spike closed) → consistent `initialBuyAmount`.
3. Predict address before launch → equality after.
4. Restriction window buy limits.
5. Graduation status transitions after sufficient locked principal.
6. Owner-only config mutations.

### 11.2 What not to do

- `vm.mockCall` on factory/token under test.
- Thin fake routers.
- Nest OZ under `ponsFamily/`.
- Always-on fork in default CI without `FOUNDRY_PROFILE`.
- Claim product “v2” is ported from this GitHub repo.

### 11.3 Suggested commands

```bash
rm -rf cache out
forge build

# Hermetic (default CI)
forge test --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/hermetic/**' -vv

# Fork (profile + foundry.toml Robinhood RPC alias)
FOUNDRY_PROFILE=<pons_fork_profile> forge test \
  --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/fork/**' -vv
```

---

## 12. Phased delivery plan

### Phase 0 — Gates (before/at copy)

**Exit criteria:** pin locked; OZ v5 inventory; **real router ABI spike** resolved without fakes.

- [ ] Confirm upstream commit at copy time.
- [ ] Diff OZ imports vs `openzeppelin-contracts-v5`; expand external if needed.
- [ ] Determine which real router the factory calls for seed buy; wire Crane periphery or deploy real SwapRouter02-compatible bytecode from Crane trees — **no thin stub**.
- [ ] Draft `VENDOR.md`.
- [ ] Choose `FOUNDRY_PROFILE` name for fork suite.

### Phase 1 — Vendor + compile (**minimum**)

**Exit criteria:** FR-D1–FR-D5.

- [ ] Copy into `ponsFamily/pons/`.
- [ ] Remap imports to `@crane/...`.
- [ ] `forge build` green.

### Phase 2 — Hermetic TestBase + tests (**minimum**)

**Exit criteria:** FR-H1–FR-H10, FR-T1–FR-T2.

- [ ] Minimal locker stub.
- [ ] `TestBase_PonsFamily` with live-like configs + real periphery.
- [ ] Hermetic suite.

### Phase 3 — Constants + fork (**minimum**)

**Exit criteria:** FR-F1–FR-F3, G7–G8.

- [ ] Active factory/locker constants.
- [ ] Profile-gated Robinhood fork suite.

### Phase 4 — Wrappers + docs (**follow-up**)

**Exit criteria:** FR-W*, FR-DOC1, G9–G10.

- [ ] Service + Aware + Behavior.
- [ ] CODEBASE_MAP / status / skills paths.

### Phase 5 — Testnet greenfield smoke (**follow-up**)

**Exit criteria:** FR-G1, G11.

- [ ] Anvil / RH testnet deploy path for factory + stub + real V3.

---

## 13. Work packages (task index)

| ID | Package | Depends on | Ship stage |
|----|---------|------------|------------|
| **PF0** | OZ inventory + real router ABI spike | — | Gate |
| **PF1** | Vendor `pons/` + remap + build | PF0 | **Minimum** |
| **PF2** | Locker stub + TestBase + hermetic | PF1 | **Minimum** |
| **PF3** | Active constants + profile-gated fork | PF1 | **Minimum** |
| **PF4** | Service / Aware / Behavior | PF2 | Follow-up |
| **PF5** | Docs / skills / status | PF2–PF3 | Follow-up |
| **PF6** | Testnet greenfield smoke | PF2 | Follow-up |

**First mergeable port = PF0 + PF1 + PF2 + PF3.**

---

## 14. Risks and open questions

| Risk / question | Mitigation |
|-----------------|------------|
| **Locker source unpublished** | Stub for hermetic; fork for live behavior; never claim bytecode parity of locker |
| **OZ v5 vs Crane default OZ v4** | Explicit v5 remap; CI compile is the gate |
| **SwapRouter02 vs Crane SwapRouter** | Phase 0 ABI spike; must resolve with **real** periphery only (no fake router) |
| **CREATE2 salt / vanity** | Plain salt first; vanity optional fuzz |
| **Legacy vs active factory** | Minimum = active only; legacy optional later |
| **“v2” confusion** | Skills/docs mention a product v2; **this GitHub has no v2 source** — do not port it |
| **Public RPC rate limits** | Profile-gated fork; pin `DEFAULT_FORK_BLOCK`; Alchemy optional |
| **GPL TickMath** | Keep SPDX; no relicense |
| **Optimizer runs 300 vs Crane runs 1** | Prefer project defaults; document any profile override |

---

## 15. Definition of done

### 15.1 First merge (minimum) — **required**

1. Domain under `contracts/protocols/launchpads/ponsFamily/pons/`, pinned in `VENDOR.md`.
2. OZ remapped to existing/expanded `@crane/contracts/external/...` (v5 semantics); no nested OZ.
3. Minimal locker stub + `TestBase_PonsFamily` with **real** V3 periphery and live-like configs.
4. Hermetic launch + predict + restrictions + graduation tests green.
5. Active factory/locker constants; profile-gated Robinhood fork suite green when profile+RPC set.
6. No Diamond/DFPkg/fake routers; product “v2” not claimed.
7. Path-scoped hermetic `forge test` evidence in PR description.

### 15.2 Program complete (follow-up)

Minimum plus Service/Aware/Behavior, docs/skills paths, optional testnet greenfield smoke.

---

## 16. Acceptance checklist (copy into first PR)

- [ ] `forge build` clean
- [ ] Domain in `ponsFamily/pons/`
- [ ] `VENDOR.md` (pin, license, OZ external policy, locker note, no v2 claim)
- [ ] No nested OZ under `ponsFamily/`
- [ ] Imports `@crane/...`
- [ ] Minimal locker stub
- [ ] Real V3 periphery only (seed buy ABI resolved)
- [ ] Hermetic launch / predict / restrictions / graduation
- [ ] Active factory + locker constants
- [ ] Fork suite under `FOUNDRY_PROFILE` + `foundry.toml` Robinhood RPC alias
- [ ] Service/Aware/docs explicitly deferred if not in this PR

---

## 17. References

| Resource | URL / path |
|----------|------------|
| Upstream repo (this port) | https://github.com/ponsdotdev/ponsfamily |
| Live active factory | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` |
| Product docs | https://docs.ponsfamily.com/ |
| Product docs “v2” page (not source) | https://docs.ponsfamily.com/v2 |
| Crane porting / verification skills | `.claude/skills/crane-porting`, `crane-porting-verification` |
| Existing pons **docs** skills | `.claude/skills/pons-architecture` (etc.) — not a code pin |
| Uni V3 TestBases | `contracts/protocols/dexes/uniswap/v3/...` |
| Robinhood constants / RPC | `ROBINHOOD_MAIN.sol`, `foundry.toml` `robinhood_*` |

---

## 18. Summary table

| Item | Value |
|------|--------|
| Protocol | pons launchpad from open-source `ponsfamily` (GitHub) |
| Upstream | ponsdotdev/ponsfamily |
| Suggested pin | `main` @ `60fcd764…` (confirm at copy) |
| Domain path | `contracts/protocols/launchpads/ponsFamily/pons/` |
| Wrappers path | `contracts/protocols/launchpads/ponsFamily/{services,aware,stubs,test}` |
| Shared deps | Reuse/expand `contracts/external` (OZ v5); Crane Uni V3 |
| Locker | Minimal hermetic stub; live active on fork |
| Router | Real periphery only |
| Fork CI | `FOUNDRY_PROFILE` + RH RPC alias |
| Consumers | Hermetic tests + IndexedEx strategies |
| Greenfield | Testnets only (follow-up) |
| First merge | Vendor + hermetic + active fork bind |
| Not in this port | Product “v2” (docs only), Diamond/DFPkg, nested OZ, fake routers |
