---
project: pons (ponsfamily) launchpad port into Crane
version: 1.0
status: draft
created: 2026-07-28
last_updated: 2026-07-28
owner: Crane core
related:
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
  - https://docs.ponsfamily.com/v2
---

# PRD: Port pons (ponsfamily) into Crane

## 1. Purpose

Port the **pons** token launchpad smart contracts from
[ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) into Crane as a
**faithful domain port** with shared dependencies remapped to Crane’s existing
external trees, under:

```text
contracts/protocols/launchpads/ponsFamily/
```

so that:

1. Hermetic Foundry tests can deploy real pons bytecode (factory, token, math)
   against Crane’s Uniswap V3 hermetic stack — not mocks of the SUT.
2. Robinhood Chain fork tests can bind the live factory, locker, WETH, and V3
   stack via network constants.
3. Crane / IndexedEx consumers get a first-class **Service / Aware / TestBase**
   surface for launch, predict-address, graduation reads, and post-launch trade
   wiring on Robinhood Chain (chain ID `4663`).

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
| Network constants for active/legacy factory + locker | Fork tests invent addresses |
| `TestBase_PonsFamily` chain | No shared setup for launchpad consumers |
| Crane Service / Aware wrappers | Diamond/strategy code has no idiomatic launch helpers |
| Protocol-faithful locker stub | Locker is **not** in the upstream source tree (interface only) |

Without this port, launchpad strategies, bots, and IndexedEx integrations either
mock pons (forbidden for SUT) or depend only on fragile live fork state.

---

## 3. Goals

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G1** | Faithful v1 domain port | Factory, token, libraries, interfaces compile under Crane solc **0.8.35** |
| **G2** | Shared-dep remap (no private OZ tree) | Upstream `contracts/lib/openzeppelin-contracts/**` **not** copied; imports → `@crane/contracts/external/openzeppelin-contracts-v5/...` |
| **G3** | Hermetic launch path | Deploy factory + locker stub + V3 periphery → `launchToken` → pool + locked position NFT + optional initial buy |
| **G4** | Predictable addresses | `predictTokenAddress` / vanity helpers match CREATE2 results |
| **G5** | Graduation reads | `graduationStatus` uses locked position principal (not fake wallet depth) |
| **G6** | Anti-snipe behavior | Token buy limits enforced during restriction window; unrestricted after |
| **G7** | Network constants | Active + legacy factory/locker + reference token/pool on `ROBINHOOD_MAIN` |
| **G8** | Crane wrappers | Interfaces + `PonsLaunchService` + `PonsLaunchAwareRepo` + TestBase/Behaviors |
| **G9** | Fork parity | Robinhood fork: live factory `extcodesize` > 0; read launch record / graduation for known token |
| **G10** | Docs & skills | CODEBASE_MAP + `docs/protocols/status.md`; keep pons skills aligned with on-disk port |

---

## 4. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| **pons v2** (bonding curve → Uniswap V4 graduation) | **Not present** in [ponsdotdev/ponsfamily](https://github.com/ponsdotdev/ponsfamily) as of pin below; docs-only / unaudited; separate PRD when source + addresses publish |
| Re-implementing Uniswap V3 | Reuse Crane `protocols/dexes/uniswap/v3/` |
| Frontend, subgraphs, HTTP APIs (`ponsfamily.com/api/*`) | Off-chain; skills already cover integration |
| Redeploying pons on BattleChain / greenfield chains without product ask | Robinhood-first; other chains only if factory is deployed |
| Porting the full OZ tree nested under pons | Remap to `contracts/external/` |
| Claiming official partnership | Attribution: product **pons**; no implied endorsement |
| Enabling `viaIR` | Forbidden; fix stack-too-deep with structs |
| Full bytecode-identical deploy of live locker | Locker source is **not** in the public repo; hermetic uses a **protocol-faithful stub** implementing `IPonsLaunchLocker` |

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
6. **OZ major must match behavior.** Upstream vendored tree includes OZ **v5**
   markers (`IERC1363`, `draft-IERC6093`, `Ownable(initialOwner)` constructor).
   Remap to **`openzeppelin-contracts-v5`**, not Crane’s default OZ **4.9.6**
   tree (`contracts/external/openzeppelin-contracts/`).
7. **Semantic routing:** OZ Ownable / Context / ERC20 stay OZ-semantic. Do **not**
   swap onto Crane-native Ownable during “dedup”.
8. **Pragma:** relax `^0.8.30` to Crane **0.8.35** only as needed; document each
   change in `VENDOR.md`.
9. **Licenses:** preserve SPDX headers. Domain is **MIT** (sources); `PonsTickMath`
   is **GPL-2.0-or-later**. Record in `VENDOR.md`. (GitHub has no root `LICENSE`
   file as of research date — treat SPDX as authoritative.)

---

## 6. Users and use cases

### 6.1 Primary users

| User | Need |
|------|------|
| Crane / IndexedEx integrators | Hermetic launch + graduation for strategy/tests |
| Agents building on Robinhood | Service helpers + constants without inventing addresses |
| CI | Reproducible TestBase; optional fork suite behind RPC |
| Indexer / bot authors | Typed interfaces for `TokenLaunched` / launch records |

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
| `contracts/src/PonsLaunchFactory.sol` | CREATE2 factory: configs, launch, graduation | `.../ponsFamily/PonsLaunchFactory.sol` (or `src/`) |
| `contracts/src/PonsLauncherToken.sol` | Fixed-supply ERC-20 + anti-snipe + metadata | same tree |
| `contracts/src/interfaces/ILaunchpad.sol` | Thin V3 + locker + factory surfaces | `.../ponsFamily/interfaces/` |
| `contracts/src/libraries/PonsLiquidityMath.sol` | Locked liquidity → principal | `.../ponsFamily/libraries/` |
| `contracts/src/libraries/PonsTickMath.sol` | Tick → sqrtPriceX96 (GPL-2.0-or-later) | `.../ponsFamily/libraries/` |

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
| **Pons launch locker** implementation | Interface `IPonsLaunchLocker` only. Hermetic: `stubs/PonsLaunchLockerStub.sol` (custody NFT, `protocolFeeRecipient`, `lockPosition`, `setFeeRedirect`). Fork: bind live active/legacy locker addresses. |
| **Legacy factory bytecode** | Interface-compatible bind only (`0x0c37…`); may differ fee split era — do not assume identical source as active. |
| **pons v2** contracts | Out of scope until open-sourced |

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

### 8.1 Placement decision

**User-specified home:**

```text
contracts/protocols/launchpads/ponsFamily/
```

This matches the **CCA launchpad** placement style (domain under
`protocols/launchpads/...`) rather than a separate `contracts/external/pons/`
tree. Domain sources are small (~5 Solidity modules). Shared OZ **must not** be
nested under this path.

If a future cleanup wants raw upstream under `contracts/external/pons/`, wrappers
can stay under `protocols/launchpads/ponsFamily/` — not required for P0.

### 8.2 Proposed tree

```text
contracts/protocols/launchpads/ponsFamily/
├── VENDOR.md
├── README.md                          # short Crane-facing map (optional)
├── PonsLaunchFactory.sol              # or src/ — pick one style and stay consistent
├── PonsLauncherToken.sol
├── interfaces/
│   └── ILaunchpad.sol                 # upstream I* (faithful)
│   # optional Crane re-exports: IPonsLaunchFactory.sol if split later
├── libraries/
│   ├── PonsLiquidityMath.sol
│   └── PonsTickMath.sol
├── services/
│   └── PonsLaunchService.sol          # stateless helpers
├── aware/
│   └── PonsLaunchAwareRepo.sol        # factory / locker / default dex ids
├── stubs/
│   └── PonsLaunchLockerStub.sol       # hermetic locker (NOT a mock of factory)
└── test/bases/
    ├── TestBase_PonsFamily.sol        # hermetic: V3 periphery + factory + locker
    └── TestBase_PonsFamily_Fork.sol   # Robinhood fork bind

test/foundry/spec/protocols/launchpads/ponsFamily/
├── hermetic/
│   ├── PonsLaunchFactory_launch.t.sol
│   ├── PonsLaunchFactory_predict.t.sol
│   ├── PonsLaunchFactory_graduation.t.sol
│   ├── PonsLauncherToken_restrictions.t.sol
│   └── PonsLaunchService.t.sol
└── fork/
    └── PonsLaunchFactory_RobinhoodFork.t.sol
```

**Comparator layout:** `contracts/protocols/launchpads/uniswap/continuous-clearing/`  
**TestBase inheritance (recommended):**

```text
CraneTest
  └── TestBase_Weth9
        └── TestBase_UniswapV3
              └── TestBase_UniswapV3Periphery
                    └── TestBase_PonsFamily
```

### 8.3 Dependency substitution map

| Upstream dependency | Crane target | Action |
|---------------------|--------------|--------|
| `@openzeppelin/contracts/...` (v5-shaped) | `@crane/contracts/external/openzeppelin-contracts-v5/...` | Remap all; expand v5 if a file is missing |
| Uniswap V3 factory / pool / PM / router (runtime) | Hermetic: Crane V3 + periphery TestBase; Fork: `ROBINHOOD_MAIN.UNISWAP_V3_*` | Do not re-vendor Uni under pons |
| Thin V3 interfaces in `ILaunchpad.sol` | Keep faithful for domain compile | Optional dual-import later |
| Locker implementation | `stubs/PonsLaunchLockerStub.sol` | Protocol-faithful stub |
| WETH | `TestBase_Weth9` / `ROBINHOOD_MAIN.WETH` | Reuse |

**Import rule:** all new/edited code uses `@crane/contracts/...` only.

Example remaps:

```solidity
// Upstream
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Crane
import {Ownable2Step} from "@crane/contracts/external/openzeppelin-contracts-v5/access/Ownable2Step.sol";
import {Math} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/math/Math.sol";
```

### 8.4 Crane wrapper surface (minimum APIs)

| Symbol | Responsibility |
|--------|----------------|
| `IPonsLaunchFactory` / `IPonsLaunchLocker` (from ported interfaces) | Typed consumer surface |
| `PonsLaunchService` | Encode/helpers: `launchToken`, fee+value packaging, `predictTokenAddress`, `graduationStatus` views, optional swap helpers post-launch |
| `PonsLaunchAwareRepo` | Diamond storage for factory, locker, default `dexId` / `launchConfigId` |
| `TestBase_PonsFamily` | Deploy locker stub + factory; register dex/launch configs matching live defaults (1% fee / tick spacing 200, 1e9 supply, 4.2 ETH threshold, etc.) |
| `TestBase_PonsFamily_Fork` | `vm.createSelectFork(robinhood_mainnet, DEFAULT_FORK_BLOCK)`; bind live addresses |
| `Behavior_IPonsLaunchFactory` (focused) | `getLaunchedToken`, `graduationStatus`, predict parity |

**Optional P1 (not P0 DoD):**

- Facet-Target-Repo exposing launch ops from a Diamond
- `PonsLaunchDFPkg` for deterministic factory packaging
- Adversarial suite (reentrancy via malicious pair token, fee donation, vanity salt griefing)

---

## 9. Network constants

Add to `contracts/constants/networks/ROBINHOOD_MAIN.sol` (and document in
`VENDOR.md`):

```text
PONS_LAUNCH_FACTORY_ACTIVE
PONS_LAUNCH_LOCKER_ACTIVE
PONS_LAUNCH_FACTORY_LEGACY
PONS_LAUNCH_LOCKER_LEGACY
PONS_ACTIVE_START_BLOCK          // 8991118
PONS_LEGACY_START_BLOCK          // 8600612
PONS_REFERENCE_TOKEN             // optional research pin
PONS_REFERENCE_POOL
```

Aliases may use shorter names if they match an existing constants style.  
**RPC:** `foundry.toml` already defines `robinhood_mainnet` → public RH RPC.

---

## 10. Functional requirements

### 10.1 Domain vendoring (P0)

| ID | Requirement |
|----|-------------|
| FR-D1 | Copy P0 Solidity modules from pinned upstream commit into `protocols/launchpads/ponsFamily/` |
| FR-D2 | Write `VENDOR.md` (pin, license, copy date, adaptations, excluded paths) |
| FR-D3 | Remap OZ → `openzeppelin-contracts-v5` via `@crane/`; **no** nested OZ tree |
| FR-D4 | Pragma / compile green under Crane 0.8.35 without `viaIR` |
| FR-D5 | Preserve MIT / GPL-2.0-or-later SPDX headers |

### 10.2 Hermetic factory + token (P0)

| ID | Requirement |
|----|-------------|
| FR-H1 | `PonsLaunchLockerStub` implements `IPonsLaunchLocker` sufficiently for launch + fee recipient |
| FR-H2 | Deploy factory with owner + locker + launch fee |
| FR-H3 | Owner adds DexConfig (V3 factory, PM, router, fee `10000`, tick spacing `200`) |
| FR-H4 | Owner adds LaunchConfig (WETH pair, 1e9 supply, anti-snipe params, graduation threshold default 4.2 ether-scale paired principal) |
| FR-H5 | `launchToken` succeeds: token CREATE2, pool init, one-sided mint, NFT at locker, `TokenLaunched` |
| FR-H6 | `predictTokenAddress` equals deployed token |
| FR-H7 | Optional initial buy path with `msg.value > launchFee` |
| FR-H8 | Anti-snipe: same-block non-creator buy reverts; max wallet / max tx enforced in window |
| FR-H9 | After `restrictionsEndBlock`, unrestricted transfers/buys (within ERC-20 rules) |
| FR-H10 | `graduationStatus` reflects locked principal vs threshold (use swaps or liquidity growth as appropriate) |

### 10.3 Crane wrappers (P0)

| ID | Requirement |
|----|-------------|
| FR-W1 | `PonsLaunchService` covers launch + predict + graduation helpers |
| FR-W2 | `PonsLaunchAwareRepo` stores factory/locker references |
| FR-W3 | `TestBase_PonsFamily` inherits Uni V3 periphery base; idempotent deploy |
| FR-W4 | Behavior checks for core views (or documented reuse of existing patterns) |

### 10.4 Fork (P0)

| ID | Requirement |
|----|-------------|
| FR-F1 | Constants for active factory/locker non-zero; `code.length > 0` on fork |
| FR-F2 | `getLaunchedToken` / `graduationStatus` against reference token (legacy or active) returns consistent shape |
| FR-F3 | Optional: one public view of live pool `slot0` for reference pool |

### 10.5 Docs / skills (P0 polish)

| ID | Requirement |
|----|-------------|
| FR-DOC1 | Update `docs/CODEBASE_MAP.md` and `docs/protocols/status.md` |
| FR-DOC2 | Point pons skills at on-disk paths (architecture already docs-complete) |
| FR-DOC3 | Archive stub `docs/archive/internal-plans/PONS_PORTING_PRD.md` → this PRD |

### 10.6 Out of P0 (P1+)

| ID | Requirement |
|----|-------------|
| FR-P1 | Diamond Facet / DFPkg for launch ops |
| FR-P2 | Adversarial tests (malicious ERC-20 pair, reentrancy on locker/fee, vanity salt exhaustion) |
| FR-P3 | pons v2 when source + addresses published |

---

## 11. Test strategy

Follow `crane-porting-verification` and production-first rules in `crane-testing`.

| Layer | What | Pass criteria |
|-------|------|---------------|
| **Compile** | Domain + wrappers | `forge build` without viaIR |
| **Hermetic** | Real factory/token + V3 + locker stub | Launch lifecycle green |
| **Behavior** | Consumer views | predict + launch record + graduation |
| **Fork** | Robinhood mainnet | Live factory code + known token reads |
| **Service** | Wrapper unit | Service helpers match direct factory calls |
| **Adversarial** | P1 | Value-bearing edge cases |

### 11.1 Minimum hermetic scenarios

1. Launch without seed buy → fee paid, position locked, record exists.
2. Launch with seed buy → balances and `initialBuyAmount` consistent.
3. Predict address before launch → equality after.
4. Buy in restriction window hits max tx / max wallet / same-block rules.
5. Graduation status false → true after sufficient paired principal in locked position.
6. Owner-only config mutations; non-owner reverts.

### 11.2 What not to do

- `vm.mockCall` on `PonsLaunchFactory` / `PonsLauncherToken` under test.
- Deploy with `address(0)` locker.
- Fake graduation by transferring tokens into a random wallet.
- Nest a second OpenZeppelin under `ponsFamily/`.
- Use OZ v4 trees for this port when constructors/errors assume v5.

### 11.3 Suggested commands

```bash
rm -rf cache out
forge build

forge test --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/**' -vv

# Fork (RPC required)
forge test --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/fork/**' -vv
```

---

## 12. Phased delivery plan

### Phase 0 — Gates and inventory

**Exit criteria:** pin locked; OZ v5 gap check; constants drafted; locker stub design agreed.

- [ ] Confirm upstream commit (or release tag) at copy time.
- [ ] Diff upstream OZ imports against `openzeppelin-contracts-v5` file list; expand external if missing.
- [ ] Draft `VENDOR.md` stub.
- [ ] Add `ROBINHOOD_MAIN` pons address constants (can land with Phase 1).
- [ ] Confirm hermetic path uses `TestBase_UniswapV3Periphery` (or document gap if SwapRouter02 shape differs from Crane `SwapRouter` — may need thin adapter or factory dex config pointing at a SwapRouter02-compatible stub).

**Note on routers:** upstream `ILaunchpad.sol` defines both `ISwapRouter02Like` (no deadline) and classic V3 router (with deadline). Factory code path for initial buy must match the **configured** router ABI. Hermetic dex config must point at a router Crane can deploy (or a minimal router stub implementing the used selector). Treat router ABI match as a Phase 0 spike before claiming FR-H7 green.

### Phase 1 — Vendor + compile (P0)

**Exit criteria:** FR-D1–FR-D5 green.

- [ ] Copy domain sources into `contracts/protocols/launchpads/ponsFamily/`.
- [ ] Remap imports; delete any accidental OZ nesting.
- [ ] `forge build` green.

### Phase 2 — Hermetic TestBase + core tests (P0)

**Exit criteria:** FR-H1–FR-H10, FR-W3 green.

- [ ] Implement locker stub.
- [ ] `TestBase_PonsFamily` with default configs.
- [ ] Hermetic launch / predict / restrictions / graduation tests.

### Phase 3 — Service + Aware + Behavior (P0)

**Exit criteria:** FR-W1–FR-W4 green.

- [ ] `PonsLaunchService`, `PonsLaunchAwareRepo`.
- [ ] Service tests via TestBase.
- [ ] Focused Behavior library.

### Phase 4 — Fork + constants (P0)

**Exit criteria:** FR-F1–FR-F3, G7 green.

- [ ] Constants committed.
- [ ] Robinhood fork suite.

### Phase 5 — Docs and polish

**Exit criteria:** FR-DOC1–FR-DOC3; G10.

- [ ] CODEBASE_MAP / status.
- [ ] Skills cross-links to on-disk port.
- [ ] Optional gas snapshot on `launchToken`.

### Phase 6 — P1 extensions (optional)

- Diamond / DFPkg, adversarial suite, v2 when available.

---

## 13. Work packages (task index)

| ID | Package | Depends on | Deliverables |
|----|---------|------------|--------------|
| **PF0** | Gates / OZ inventory / router spike | — | Decision notes in VENDOR draft |
| **PF1** | Vendor domain + remap + build | PF0 | Sources + VENDOR.md + compile |
| **PF2** | Locker stub + TestBase + hermetic suite | PF1 | FR-H* |
| **PF3** | Service / Aware / Behavior | PF2 | FR-W* |
| **PF4** | Constants + Robinhood fork | PF1 | FR-F* |
| **PF5** | Docs / skills / status | PF2–PF4 | FR-DOC* |
| **PF6** | P1 Diamond / adversarial / v2 | PF5 | Optional |

**Minimum mergeable port = PF1 + PF2 + PF4** (compile + hermetic launch + fork bind).  
**Full P0 DoD = PF1–PF5.**

---

## 14. Risks and open questions

| Risk / question | Mitigation |
|-----------------|------------|
| **Locker source unpublished** | Stub for hermetic; fork for live behavior; never claim bytecode parity of locker |
| **OZ v5 vs Crane default OZ v4** | Explicit v5 remap; CI compile is the gate |
| **SwapRouter02 vs Crane SwapRouter** | Phase 0 ABI spike; stub router if needed for seed-buy path only |
| **CREATE2 salt / vanity** | Tests cover plain salt first; vanity search optional fuzz |
| **Legacy vs active factory** | Fork tests pin which factory; fee split era documented |
| **v2 confusion** | Skills mention v2; this PRD **excludes** v2 until source lands |
| **Public RPC rate limits** | Chunk logs; pin `DEFAULT_FORK_BLOCK`; prefer Alchemy for CI |
| **GPL TickMath** | Keep SPDX; no relicense of that file |
| **Optimizer runs 300 vs Crane runs 1** | Domain may use file-level / profile settings only if size requires — default to project solc; document any profile |

---

## 15. Definition of done (port complete)

A pons port is **done** only when all hold:

1. Domain sources under `contracts/protocols/launchpads/ponsFamily/`, pinned in `VENDOR.md`.
2. Shared OZ remapped to `@crane/contracts/external/openzeppelin-contracts-v5/...` (no private OZ under ponsFamily).
3. No new git submodules; no unauthorized remapping aliases.
4. Locker hermetic stub + live locker constants for fork.
5. Crane wrapper surface: interfaces + Service + Aware + TestBase (minimum).
6. Verification gates: compile, hermetic launch lifecycle, fork bind, Service tests green.
7. `ROBINHOOD_MAIN` pons addresses present.
8. Docs/CODEBASE_MAP/status updated; archive PRD pointer present.
9. Path-scoped `forge test` evidence captured in PR description.

---

## 16. Acceptance checklist (copy into PR)

- [ ] `forge build` clean for ponsFamily packages
- [ ] `VENDOR.md` present (pin, license, OZ v5 policy, locker note)
- [ ] No `ponsFamily/**/openzeppelin*` nested vendor tree
- [ ] All imports `@crane/...`
- [ ] Hermetic `TestBase_PonsFamily` deploys and launches
- [ ] Predict address parity test
- [ ] Restriction window tests
- [ ] Graduation status test
- [ ] Robinhood fork: factory code + known token read
- [ ] Service / Aware covered
- [ ] Constants for active/legacy factory + locker
- [ ] CODEBASE_MAP / status / skills links
- [ ] v2 explicitly out of scope in PR body

---

## 17. References

| Resource | URL / path |
|----------|------------|
| Upstream repo | https://github.com/ponsdotdev/ponsfamily |
| Live factory | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` |
| Docs v1 | https://docs.ponsfamily.com/ |
| Docs v2 (out of scope) | https://docs.ponsfamily.com/v2 |
| Crane porting skill | `.claude/skills/crane-porting/SKILL.md` |
| Crane verification skill | `.claude/skills/crane-porting-verification/SKILL.md` |
| pons agent skills | `.claude/skills/pons-architecture`, `pons-integration`, `pons-operations` |
| Uni V3 TestBases | `contracts/protocols/dexes/uniswap/v3/test/bases/`, `.../periphery/test/bases/` |
| Robinhood constants | `contracts/constants/networks/ROBINHOOD_MAIN.sol` |
| CCA layout comparator | `contracts/protocols/launchpads/uniswap/continuous-clearing/` |
| Morpho PRD format peer | `docs/superpowers/specs/2026-07-27-morpho-port-prd.md` |

---

## 18. Summary table

| Item | Value |
|------|--------|
| Protocol | pons (ponsfamily) v1 launchpad |
| Upstream | ponsdotdev/ponsfamily |
| Suggested pin | `main` @ `60fcd76499a8d84caa09a1b252b0b1ae46a7bd86` (confirm at copy) |
| Target path | `contracts/protocols/launchpads/ponsFamily/` |
| Chain focus | Robinhood mainnet `4663` |
| Shared deps | OZ v5 external; Uniswap V3 Crane port |
| Missing upstream | Locker implementation → hermetic stub |
| Out of scope | v2, frontends, nested OZ, viaIR |
| Min merge | Vendor + hermetic launch + fork bind |
| Full P0 | + Service/Aware/Behavior + docs |
