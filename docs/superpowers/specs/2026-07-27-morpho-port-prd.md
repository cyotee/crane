---
project: Morpho lending stack port into Crane
version: 1.0
status: draft
created: 2026-07-27
last_updated: 2026-07-27
owner: Crane core
related:
  - docs/superpowers/plans/2026-07-27-morpho-port.md
  - docs/archive/internal-plans/DEFI_PORTING_PRD.md
  - docs/archive/internal-plans/DEFI_RESEARCH.md
  - docs/archive/internal-plans/DEFI_PORTING_PRIORITIZATION.md
  - docs/archive/internal-plans/MORPHO_PORTING_PRD.md
  - .claude/skills/crane-porting/SKILL.md
  - .claude/skills/crane-porting-verification/SKILL.md
  - contracts/constants/networks/
official_docs:
  - https://docs.morpho.org/developers/contracts/
  - https://docs.morpho.org/developers/contracts/addresses/
---

# PRD: Port Morpho into Crane

## 1. Purpose

Port the **Morpho lending protocol stack** into Crane as a **faithful domain port** with shared dependencies remapped to Crane’s existing external trees, so that:

1. Hermetic Foundry tests can deploy real Morpho bytecode (not mocks of the SUT).
2. Fork tests can bind live Morpho deployments via network constants.
3. Strategy vaults and other Crane consumers get a first-class **Service / Aware / TestBase** surface for Blue markets and Morpho vaults.

This PRD is the **authoritative definition of what to port, in what order, and when it is done**.  
Task-level execution: [`docs/superpowers/plans/2026-07-27-morpho-port.md`](../plans/2026-07-27-morpho-port.md) (includes **ported upstream tests** and **fork state-parity** gates).

Morpho is already ranked **Phase 1** in [`DEFI_PORTING_PRD.md`](../../archive/internal-plans/DEFI_PORTING_PRD.md) (§§C.3–C.4) and is the **strongest single lending recommendation** in [`DEFI_RESEARCH.md`](../../archive/internal-plans/DEFI_RESEARCH.md) §2.1: permissionless isolated markets plus a battle-tested ERC-4626 curator vault pattern.

---

## 2. Problem statement

Crane already ports Aave, Euler, Compound-style surfaces, and many DEXes, but **does not yet include Morpho as a first-class protocol port**. Today:

| Gap | Impact |
|-----|--------|
| No vendored Morpho Blue / MetaMorpho / Vault V2 | Cannot hermetically test Morpho-using strategies |
| Only a thin Frax `IMetaMorpho` interface + BC MockMorpho bind | Incomplete surface; not a production-faithful port |
| No Morpho `TestBase_*` / `Behavior_*` ladder | Fork and hermetic tests have no shared setup |
| No Crane Service/Aware wrappers | Diamond/strategy code has no idiomatic Morpho helpers |

Without this port, carry/loop and curator-vault work either mocks Morpho (forbidden for SUT) or depends only on fragile fork state.

---

## 3. Goals

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| **G1** | Faithful Morpho Blue core port | `Morpho.sol` + libs compile under Crane solc; hermetic market open + supply/borrow/repay/liquidate |
| **G2** | Production IRM + oracle factory | AdaptiveCurveIRM + ChainlinkOracleV2 factory hermetic deploy and fork-bind |
| **G3** | MetaMorpho V1.1 + Public Allocator | Hermetic vault over Blue markets; deposit / allocate / withdraw; PublicAllocator reallocate |
| **G4** | Vault V2 + core adapters | Factory deploy path + MarketV1/VaultV1 adapter smoke tests |
| **G5** | Bundler3 smoke path | Multicall encode/execute for common Blue/vault flows |
| **G6** | Network constants for fork tests | ETH, Base, OP, Arb, Sepolia, Base Sepolia, Robinhood, BC mock |
| **G7** | Crane wrappers | Interfaces + Service + AwareRepo + TestBase chains; Behaviors for consumer APIs |
| **G8** | Docs & agent skills | CODEBASE_MAP + protocol skill family after P0 is green |

---

## 4. Non-goals

| Non-goal | Rationale |
|----------|-----------|
| Morpho Midnight (fixed-rate markets) | Separate product; Base-only today; own PRD later |
| TypeScript SDKs, subgraphs, liquidation bots | Not Solidity domain ports |
| Redeploying Morpho on BattleChain | BC provides MockMorpho — **bind only** |
| Building consumer strategy vaults (carry/loop) | Downstream of this port |
| Porting every Morpho chain’s full periphery | Add chains when a TestBase/script needs them |
| Re-vendoring OZ/Solady private trees under Morpho | Remap to `contracts/external/` |
| Enabling `viaIR` | Forbidden in Crane; fix stack-too-deep with structs |

---

## 5. Non-negotiable policy

Aligned with `crane-porting` and `DEFI_PORTING_PRD` A.4–A.6:

1. **Faithful domain, remapped deps.** Morpho’s own contracts stay logic-equivalent to a pinned upstream tag; OZ/Solady/Permit2/Chainlink go through `@crane/contracts/external/...` (or existing Crane ports).
2. **No new git submodules.** Copy sources in; pin in `VENDOR.md`.
3. **No new Foundry remapping aliases** for Morpho packages; use `@crane/` imports.
4. **BUSL clearance before vendoring** Morpho Blue / MetaMorpho sources. Until cleared: interfaces + fork-only tests are allowed; full vendor is gated.
5. **Production-first tests.** Never `vm.mockCall` Morpho/MetaMorpho as SUT; use ported bytecode or live forks.
6. **BattleChain:** bind `BC_TESTNET.MORPHO` only; never greenfield-deploy Morpho on BC.
7. **Pragma:** adapt to Crane Solidity **0.8.35** only where required for multi-version compile; document each relaxation in `VENDOR.md`.

---

## 6. Users and use cases

### 6.1 Primary users

| User | Need |
|------|------|
| Crane / IndexedEx vault authors | Hermetic Morpho markets + MetaMorpho as collateral/debt legs |
| Protocol integrators in Crane | Service helpers for supply/borrow/allocate without raw ABI glue |
| CI / agents | Reproducible TestBase setup and fork tests against constants |
| BC greenfield operators | Bind MockMorpho; optional Morpho-aware scripts later |

### 6.2 Core use cases

1. **Hermetic Blue market:** deploy Morpho + IRM + oracle → create market → supply → borrow → repay → withdraw → liquidate.
2. **Hermetic MetaMorpho:** create vault over markets → deposit → set caps / reallocate → withdraw.
3. **Fork parity:** at known block, read live Morpho market state and run one user op against mainnet/Base.
4. **Bundled UX path:** Bundler3 multicall for supplyCollateral + borrow (or deposit + allocate).
5. **Consumer CraneTest:** a Diamond or vault test uses `MorphoBlueService` without re-implementing MarketParams/Id math.

---

## 7. Upstream repository inventory

Sources: Morpho docs “Contracts” index and `morpho-org` GitHub (verified 2026-07-27).

### 7.1 Must-port (complete test inclusion)

| Pri | Repository | What it provides | Crane vendor path |
|-----|------------|------------------|-------------------|
| P0 | [morpho-org/morpho-blue](https://github.com/morpho-org/morpho-blue) | Core singleton, markets, flash loans | `contracts/external/morpho/blue/` |
| P0 | [morpho-org/morpho-blue-irm](https://github.com/morpho-org/morpho-blue-irm) | AdaptiveCurve IRM | `contracts/external/morpho/blue-irm/` |
| P0 | [morpho-org/morpho-blue-oracles](https://github.com/morpho-org/morpho-blue-oracles) | ChainlinkOracleV2 + factory | `contracts/external/morpho/blue-oracles/` |
| P0 | [morpho-org/metamorpho-v1.1](https://github.com/morpho-org/metamorpho-v1.1) | MetaMorpho vaults V1.1 | `contracts/external/morpho/metamorpho-v1.1/` |
| P0 | [morpho-org/public-allocator](https://github.com/morpho-org/public-allocator) | Permissionless vault reallocation | `contracts/external/morpho/public-allocator/` |
| P1 | [morpho-org/vault-v2](https://github.com/morpho-org/vault-v2) | Vault V2 + MarketV1 / VaultV1 adapters | `contracts/external/morpho/vault-v2/` |
| P1 | [morpho-org/bundler3](https://github.com/morpho-org/bundler3) | Atomic batch executor + adapters | `contracts/external/morpho/bundler3/` |

### 7.2 Optional / later

| Pri | Repository | Notes |
|-----|------------|-------|
| P2 | [morpho-org/metamorpho](https://github.com/morpho-org/metamorpho) | V1.0 legacy — interfaces unless a specific vault needs it |
| P2 | [morpho-org/morpho-blue-bundlers](https://github.com/morpho-org/morpho-blue-bundlers) | Legacy bundlers; prefer Bundler3 |
| P2 | [morpho-org/universal-rewards-distributor](https://github.com/morpho-org/universal-rewards-distributor) | Rewards claim tests |
| P3 | MORPHO token repos | Interfaces + network constants only unless bridge tests needed |
| Out | [morpho-org/midnight](https://github.com/morpho-org/midnight) | Fixed-rate; separate PRD |
| Out | `sdks`, subgraphs, liquidation bot, deployment-only repos | Non-domain |

### 7.3 Suggested pins (confirm at copy time)

| Component | Suggested pin | License gate |
|-----------|---------------|--------------|
| morpho-blue | `v1.0.0` or latest audited tag matching live bytecode | **BUSL-1.1** — clear first |
| morpho-blue-irm | `v1.0.0` | Review SPDX |
| morpho-blue-oracles | `v1.0.0` / `v2.0.0` per factory | Review SPDX |
| metamorpho-v1.1 | Release/commit from address tables | **BUSL** — clear first |
| public-allocator | `v1.0.0` | Review SPDX |
| vault-v2 | Latest release | GPL-class (verify) |
| bundler3 | Latest release | GPL-class (verify) |

Each package **must** have `VENDOR.md` with upstream URL, pin, license note, copy date, and adaptations.

---

## 8. Architecture and target layout

### 8.1 Two trees (Crane rule)

```
contracts/external/morpho/          # Vendored upstream domain (faithful)
contracts/protocols/lending/morpho/ # Crane wrappers, stubs, TestBases
test/foundry/spec/protocols/lending/morpho/
```

### 8.2 Proposed tree

```
contracts/external/morpho/
├── blue/                 # morpho-blue/src → remapped
├── blue-irm/
├── blue-oracles/
├── metamorpho-v1.1/
├── public-allocator/
├── vault-v2/             # Phase 3
├── bundler3/             # Phase 3
└── <pkg>/VENDOR.md

contracts/protocols/lending/morpho/
├── blue/
│   ├── interfaces/       # IMorpho, IIrm, IOracle re-exports / Crane-facing
│   ├── services/MorphoBlueService.sol
│   ├── aware/MorphoBlueAwareRepo.sol
│   ├── stubs/            # Hermetic deploy helpers (real Morpho, not mocks)
│   └── test/bases/TestBase_MorphoBlue.sol
├── metamorpho/
│   ├── interfaces/
│   ├── services/MetaMorphoService.sol
│   ├── aware/MetaMorphoAwareRepo.sol   # if needed
│   ├── stubs/
│   └── test/bases/TestBase_MetaMorpho.sol
├── vault-v2/
│   └── …
└── bundler/
    └── …

test/foundry/spec/protocols/lending/morpho/
├── blue/                 # hermetic + unit
├── metamorpho/
├── vault-v2/
└── bundler/

test/foundry/fork/{ethereum,base}/protocols/lending/morpho/
└── …                     # fork parity suites
```

### 8.3 Dependency substitution map

| Upstream dependency | Crane target | Action |
|---------------------|--------------|--------|
| OZ ERC20, Ownable2Step, Multicall, SafeERC20, IERC4626 | `contracts/external/openzeppelin-contracts*` (match major) | Expand external if symbol missing; **do not** nest OZ under morpho |
| Solady math / transfer (if present) | `contracts/external/solady/` | Expand then remap |
| Permit2 (bundler) | Existing Crane Permit2 port | Reuse |
| Chainlink Aggregator interfaces | Existing oracle / external Chainlink | Reuse |
| Morpho Blue (for MetaMorpho/Vault V2) | This port’s `external/morpho/blue/` | Internal dependency order: Blue → vaults |

**Import rule:** all new/edited code uses `@crane/contracts/...` only.

### 8.4 Crane wrapper surface (minimum APIs)

#### Morpho Blue

| Symbol | Responsibility |
|--------|----------------|
| `IMorpho`, `IIrm`, `IOracle`, `MarketParams`, `Id` | Typed protocol surface |
| `MorphoBlueService` | `createMarket`, `supply`, `supplyCollateral`, `borrow`, `repay`, `withdraw`, `withdrawCollateral`, `liquidate`, `flashLoan`; `id` helpers |
| `MorphoBlueAwareRepo` | Storage for morpho / default IRM / oracle factory addresses |
| `TestBase_MorphoBlue` | Hermetic deploy + mintable collateral/loan tokens + oracle stub |
| `Behavior_IMorpho` (or focused Behaviors) | Consumer-facing view/ops validation |

#### MetaMorpho V1.1

| Symbol | Responsibility |
|--------|----------------|
| `IMetaMorpho`, `IMetaMorphoFactory`, `IPublicAllocator` | Vault + factory + allocator |
| `MetaMorphoService` | deposit/mint/withdraw/redeem; cap/queue/reallocate; role transitions |
| `TestBase_MetaMorpho` | Vault over `TestBase_MorphoBlue` markets |
| ERC-4626 Behavior | Share accounting, deposit/withdraw invariants |

#### Vault V2 / Bundler3 (P1)

| Symbol | Responsibility |
|--------|----------------|
| Vault V2 factory + adapter interfaces | Create vault, attach adapters |
| `MorphoVaultV2Service` | Minimal deposit/withdraw + adapter bind |
| `IBundler3` + `MorphoBundlerService` | Encode multicall sequences for common flows |

Optional later: **DFPkg** packaging MetaMorpho-style curated vault as a Diamond factory package (not required for P0 DoD).

---

## 9. Network constants (fork infrastructure)

Addresses from [Morpho addresses docs](https://docs.morpho.org/developers/contracts/addresses/) (2026-07-27).  
Solidity constants live under `contracts/constants/networks/`.

### 9.1 Coverage required by this PRD

| Library | Chain ID | Morpho surface |
|---------|----------|----------------|
| `ETHEREUM_MAIN` | 1 | Full stack |
| `BASE_MAIN` | 8453 | Full stack (+ Midnight constants optional) |
| `OPTIMISM_MAIN` | 10 | Blue + vaults + bundler + URD factory |
| `ARBITRUM_MAIN` | 42161 | Full stack (new library if absent) |
| `ETHEREUM_SEPOLIA` | 11155111 | Testnet Blue + vaults |
| `BASE_SEPOLIA` | 84532 | Testnet Blue + vaults |
| `ROBINHOOD_MAIN` | 4663 | Blue + Vault V2 + Bundler3 |
| `BC_TESTNET` | 627 | MockMorpho bind only |

### 9.2 Naming convention

```text
MORPHO / MORPHO_BLUE
MORPHO_ADAPTIVE_CURVE_IRM
MORPHO_CHAINLINK_ORACLE_V2_FACTORY
MORPHO_METAMORPHO_FACTORY_V1_1
MORPHO_METAMORPHO_FACTORY_V1_0          # legacy where deployed
MORPHO_PUBLIC_ALLOCATOR
MORPHO_VAULT_V2_FACTORY
MORPHO_VAULT_V1_ADAPTER_FACTORY
MORPHO_MARKET_V1_ADAPTER_V2_FACTORY
MORPHO_REGISTRY
MORPHO_BUNDLER3
MORPHO_GENERAL_ADAPTER_1
MORPHO_URD_FACTORY
MORPHO_TOKEN
```

### 9.3 Core Blue addresses (reference)

| Chain | Morpho | AdaptiveCurve IRM | Oracle V2 Factory |
|-------|--------|-------------------|-------------------|
| Ethereum | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | `0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC` | `0x3A7bB36Ee3f3eE32A60e9f2b33c1e5f2E83ad766` |
| Base | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | `0x46415998764C29aB2a25CbeA6254146D50D22687` | `0x2DC205F24BCb6B311E5cdf0745B0741648Aebd3d` |
| OP | `0xce95AfbB8EA029495c66020883F87aaE8864AF92` | `0x8cD70A8F399428456b29546BC5dBe10ab6a06ef6` | `0x1ec408D4131686f727F3Fd6245CF85Bc5c9DAD70` |
| Arbitrum | `0x6c247b1F6182318877311737BaC0844bAa518F5e` | `0x66F30587FB8D4206918deb78ecA7d5eBbafD06DA` | `0x98Ce5D183DC0c176f54D37162F87e7eD7f2E41b5` |
| Robinhood | `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` | `0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1` | `0xB7c16F6F8cF531447Bf27Ca7220f981E79C9cdF2` |
| Sepolia | `0xd011EE229E7459ba1ddd22631eF7bF528d424A14` | `0x8C5dDCD3F601c91D1BF51c8ec26066010ACAbA7c` | `0xa6c843fc53aAf6EF1d173C4710B26419667bF6CD` |
| Base Sepolia | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | `0x46415998764C29aB2a25CbeA6254146D50D22687` | `0x2DC205F24BCb6B311E5cdf0745B0741648Aebd3d` |
| BC Testnet | Mock `0x102CdAF4B7097752f2Bb336c6cDf39f0aBBbb58c` | n/a | n/a |

**Note:** Network constant libraries may already contain these values from preparatory work; this PRD still requires them as **fork infrastructure DoD**.

### 9.4 Chains deferred

Scroll, Linea, Polygon, HyperEVM, and other Morpho-listed chains are **out of constants scope** until a consumer needs them. Prefer adding a library over bloating unused chains.

---

## 10. Functional requirements

### 10.1 Morpho Blue (P0)

| ID | Requirement |
|----|-------------|
| FR-B1 | Vendor Morpho Blue sources with pin + VENDOR.md |
| FR-B2 | Remap shared deps; `forge build` green for Blue + IRM + oracles |
| FR-B3 | Hermetic deploy of Morpho singleton |
| FR-B4 | Hermetic AdaptiveCurveIRM deploy/bind |
| FR-B5 | Hermetic oracle (ChainlinkOracleV2 factory **or** minimal IOracle stub for unit tests) |
| FR-B6 | `createMarket(MarketParams)` with loan, collateral, oracle, IRM, LLTV |
| FR-B7 | Lender path: supply / withdraw loan asset |
| FR-B8 | Borrower path: supplyCollateral / borrow / repay / withdrawCollateral |
| FR-B9 | Liquidation path: unhealthy position → liquidate |
| FR-B10 | Optional: flashLoan path |
| FR-B11 | Fork: `extcodesize` of `ETHEREUM_MAIN.MORPHO` / `BASE_MAIN.MORPHO` > 0; one live market op |
| FR-B12 | `MorphoBlueService` + `MorphoBlueAwareRepo` + `TestBase_MorphoBlue` |

### 10.2 MetaMorpho + Public Allocator (P0)

| ID | Requirement |
|----|-------------|
| FR-M1 | Vendor metamorpho-v1.1 + public-allocator |
| FR-M2 | Factory-create MetaMorpho vault over hermetic Blue markets |
| FR-M3 | ERC-4626 deposit / mint / withdraw / redeem |
| FR-M4 | Allocator reallocate / set supply queue / caps as required by upstream |
| FR-M5 | PublicAllocator enabled path can pull liquidity across markets |
| FR-M6 | Fork: factory address code present; optional deposit against a known vault |
| FR-M7 | `MetaMorphoService` + `TestBase_MetaMorpho` |

### 10.3 Vault V2 + Bundler3 (P1)

| ID | Requirement |
|----|-------------|
| FR-V1 | Vendor vault-v2; hermetic factory + one adapter attach + deposit smoke |
| FR-V2 | Vendor bundler3; encode multicall for ≥1 Blue or vault flow |
| FR-V3 | Fork bind factories/bundler on ETH/Base/Arb |

### 10.4 Rewards / token (P2)

| ID | Requirement |
|----|-------------|
| FR-R1 | URD factory interfaces + optional fork claim smoke |
| FR-R2 | MORPHO token addresses in constants; interfaces only unless product needs more |

---

## 11. Test strategy

Follow `crane-porting-verification` and production-first rules in `crane-testing`.

| Layer | What | Pass criteria |
|-------|------|---------------|
| **Compile** | All vendored + wrapper packages | `forge build` without viaIR |
| **Hermetic unit/integration** | Real Morpho bytecode via stubs/TestBase | Market lifecycle + vault lifecycle green |
| **Behavior** | Interface contracts Crane consumers call | `Behavior_*` / ERC4626 checks green |
| **Fork** | ETH + Base at `DEFAULT_FORK_BLOCK` | Constants point at live code; one successful user op |
| **Adversarial (later)** | Liquidation, donation, bad oracle | Optional Phase 5; use `crane-adversarial-testing` for vault wrappers that hold value |
| **BC** | MockMorpho | Bind-only smoke if a script needs it; no redeploy |

### 11.1 Example fork setup

```solidity
function setUp() public {
    vm.createSelectFork(vm.rpcUrl("mainnet"), ETHEREUM_MAIN.DEFAULT_FORK_BLOCK);
    morpho = IMorpho(ETHEREUM_MAIN.MORPHO);
    irm = IIrm(ETHEREUM_MAIN.MORPHO_ADAPTIVE_CURVE_IRM);
    assertGt(ETHEREUM_MAIN.MORPHO.code.length, 0);
}
```

### 11.2 What not to do

- Mock Morpho / MetaMorpho under test with `vm.mockCall`.
- Invent interface-only fakes when hermetic port can deploy real contracts.
- Depend on `address(0)` facets or empty oracles in “success” paths without asserting revert.

---

## 12. Phased delivery plan

### Phase 0 — Gates and infrastructure

**Exit criteria:** license decision recorded; pins chosen; network constants present; import inventory complete.

- [ ] BUSL clearance decision for Blue + MetaMorpho (go / no-go / interfaces-only interim).
- [ ] Confirm upstream tags/commits; draft `VENDOR.md` stubs.
- [ ] Inventory Morpho imports vs `contracts/external/`.
- [ ] Ensure Morpho addresses in network constant libraries (G6).
- [ ] Open tracking tasks (M0–M6 below).

### Phase 1 — Morpho Blue (P0)

**Exit criteria:** FR-B1–FR-B12 green.

- [ ] Vendor blue + blue-irm + blue-oracles.
- [ ] Remap deps; compile.
- [ ] Service + Aware + TestBase + Behaviors.
- [ ] Hermetic lifecycle tests.
- [ ] Ethereum + Base fork tests.

### Phase 2 — MetaMorpho V1.1 + Public Allocator (P0)

**Exit criteria:** FR-M1–FR-M7 green; depends on Phase 1.

- [ ] Vendor metamorpho-v1.1 + public-allocator.
- [ ] Hermetic vault over Blue TestBase.
- [ ] Fork factory checks; optional live vault deposit.
- [ ] ERC-4626 Behavior coverage.

### Phase 3 — Vault V2 + Bundler3 (P1)

**Exit criteria:** FR-V1–FR-V3 green.

- [ ] Vendor vault-v2 + bundler3.
- [ ] Hermetic + fork smokes.
- [ ] Minimal Service wrappers.

### Phase 4 — Rewards / token (P2)

**Exit criteria:** FR-R1–FR-R2 as needed by consumers.

### Phase 5 — Polish

- [ ] Protocol skills under `.claude/skills/` (architecture, blue ops, vault ops).
- [ ] Update `docs/CODEBASE_MAP.md` and `docs/protocols/status.md`.
- [ ] Optional DFPkg for curated vault pattern.
- [ ] Optional adversarial suite for vault wrappers.

---

## 13. Work packages (task index)

| ID | Package | Depends on | Deliverables |
|----|---------|------------|--------------|
| **M0** | Gates + constants | — | License note, pins, network constants, import inventory |
| **M1** | Vendor Blue stack | M0 | `external/morpho/{blue,blue-irm,blue-oracles}`, compile |
| **M2** | Blue wrappers + hermetic tests | M1 | Service, Aware, TestBase, Behaviors, hermetic specs |
| **M3** | Blue fork tests | M2 | ETH + Base fork suite |
| **M4** | MetaMorpho + PublicAllocator | M2 | Vendor + Service + TestBase + hermetic + fork |
| **M5** | Vault V2 + Bundler3 | M4 (soft) | Vendor + smokes |
| **M6** | Docs / skills / optional URD | M4 | CODEBASE_MAP, skills, P2 extras |

---

## 14. Risks and mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| BUSL redistribution/relicensing | High | Clear before vendor; interim interfaces + fork-only if blocked |
| Bytecode pin ≠ live deployment | Medium | Prefer pin that matches mainnet codehash; document in VENDOR.md |
| Permissionless bad oracles in tests | Medium | Hermetic tests use controlled oracle; fork tests pick known markets |
| Curator / allocation risk misread as protocol bug | Medium | Document curator role; Behaviors assert role gates |
| Stack-too-deep / size on bundler trees | Medium | Struct packing; no viaIR; split packages |
| Duplicate OZ trees | High | Expand shared external first; remap; reject nested OZ |
| BC accidental Morpho deploy | Medium | Explicit bind-only policy; constants document mock address |

---

## 15. Success metrics / definition of done

A Morpho port is **done** only when **all** hold:

1. **P0 domain sources** under `contracts/external/morpho/` with pins and license notes in `VENDOR.md`.
2. **Shared deps remapped** to `@crane/contracts/external/...` (no new private OZ/Solady under Morpho).
3. **G1–G3 and G6–G7** satisfied (Blue + MetaMorpho + constants + wrappers).
4. **Hermetic** Blue + MetaMorpho tests green in CI (or documented local command).
5. **Fork** tests green on Ethereum and Base using network constants.
6. **No SUT mocks** for Morpho/MetaMorpho.
7. **Docs:** CODEBASE_MAP Morpho section updated; this PRD status → `complete` (or `active` with residual P1/P2 listed).
8. **Skills:** at least a Morpho architecture skill scheduled or landed (G8).

P1 (Vault V2, Bundler3) and P2 (URD/token) may ship in follow-up PRs but must be tracked; **P0 is the minimum mergeable “Morpho port”**.

---

## 16. Decisions

### 16.1 Locked (2026-07-27 clarification)

| # | Decision | Choice |
|---|----------|--------|
| D2 | Upstream pin | **Bytecode matching live deploy** (ETH/Base Morpho); record pin + license in `VENDOR.md` |
| D4 | First merge scope | **Full stack** including Vault V2 + Bundler3 (not Blue-only) |
| D7 | Upstream tests | **All portable tests must pass**; skip only with reason + replacement |
| D8 | Fork parity method | **Matching new markets** on live + local Morpho; exact state equality |

### 16.2 Still open (defaults apply if unset)

| # | Question | Default if unset |
|---|----------|------------------|
| D1 | License redistribution note for historical BUSL tags if pin is pre-GPL | Record SPDX as found at pin; prefer GPL-era pin if codehash matches |
| D3 | Hermetic oracle: full ChainlinkOracleV2 vs minimal IOracle stub? | **Minimal IOracle for unit speed** + factory path in integration / parity markets |
| D5 | DFPkg for MetaMorpho in first merge? | **No** — optional polish |
| D6 | Port legacy MetaMorpho V1.0 factory fully? | **Interfaces only** |
| D9 | Fork chains for parity CI | **Ethereum + Base required**; OP/Arb optional after |
| D10 | URD / MORPHO token in first merge? | **No** unless a Vault/Bundler upstream test needs them |

---

## 17. References

### Morpho official

- Contracts index: https://docs.morpho.org/developers/contracts/
- Addresses: https://docs.morpho.org/developers/contracts/addresses/
- morpho-blue: https://github.com/morpho-org/morpho-blue
- morpho-blue-irm: https://github.com/morpho-org/morpho-blue-irm
- morpho-blue-oracles: https://github.com/morpho-org/morpho-blue-oracles
- metamorpho-v1.1: https://github.com/morpho-org/metamorpho-v1.1
- public-allocator: https://github.com/morpho-org/public-allocator
- vault-v2: https://github.com/morpho-org/vault-v2
- bundler3: https://github.com/morpho-org/bundler3
- universal-rewards-distributor: https://github.com/morpho-org/universal-rewards-distributor

### Crane

- Port skill: `.claude/skills/crane-porting/SKILL.md`
- Verification skill: `.claude/skills/crane-porting-verification/SKILL.md`
- Program PRD: `docs/archive/internal-plans/DEFI_PORTING_PRD.md` §§C.3–C.4
- Research: `docs/archive/internal-plans/DEFI_RESEARCH.md` §2.1
- Exemplar ports: Lido (`external/lido/`), Euler (`protocols/lending/euler/`), Bold design (`docs/superpowers/specs/2026-05-30-bold-port-design.md`)

---

## 18. Document history

| Date | Change |
|------|--------|
| 2026-07-27 | v1.0 draft — full Morpho stack PRD for Crane port |
| 2026-07-27 | Locked scope: full stack + all portable upstream tests + matching-market fork parity + live bytecode pin |
