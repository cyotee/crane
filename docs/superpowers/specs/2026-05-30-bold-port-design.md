# Liquity Bold Port — Design & Progress Log

**Status:** complete — 714 spec + 260 fork tests pass, `lib/bold` submodule removed
**Owner:** porting Liquity V2 (Bold + V2-gov) from https://github.com/liquity/bold into Crane.
**Created:** 2026-05-30
**Last updated:** 2026-05-31

---

## 1. Goal

Port the Liquity V2 contracts (Bold core + V2-gov), their transitive dependencies, and their tests into the Crane framework so we can integration-test against Bold without forking external chain state. Success = all original tests (fork + non-fork) pass when built under Crane's `forge` toolchain.

## 2. Source snapshot

- Submoduled at `lib/bold/` (will be removed after the port completes)
- Bold revision: `main` at clone time (commit captured in `.gitmodules`)
- File counts (.sol):
  - `lib/bold/contracts/src/`: 102
  - `lib/bold/contracts/test/`: 94
  - `lib/bold/contracts/lib/V2-gov/src/`: 27
  - `lib/bold/contracts/lib/V2-gov/test/`: 42
  - **Total: ~265**

## 3. Locked decisions (user-confirmed)

| Topic | Decision |
|---|---|
| OZ source | Use Crane's port at `contracts/external/openzeppelin-contracts/` (OZ v5.5.0); adapt Bold v4.9.5 call sites to v5 |
| Scope | Port everything — core, Zappers, V2-gov, all tests including fork & E2E |
| Fork test location | `test/foundry/fork/ethereum/protocols/staking/liquity/v2/` |
| Non-fork test location | `test/foundry/spec/protocols/staking/liquity/v2/{bold,gov}/` |
| DEX interfaces | Hybrid — reuse Crane's existing interfaces where byte-identical; keep Bold-local where signatures differ |
| Success criterion | All tests pass (fork + non-fork) |
| Pragma policy | Rewrite all Bold/V2-gov pragmas to `^0.8.35` (Crane's solc) |
| Solady | Reuse `contracts/solady/`; port missing pieces into the same tree |
| forge-std | Reuse `lib/forge-std` via remapping; port missing pieces into `contracts/external/forge-std/` |
| Execution | Approach A — phased: foundation/compile → non-fork tests → fork/E2E |
| Submodule | `lib/bold` kept until port completes, then removed |

## 4. Target file layout

### 4.1 Source contracts

```
contracts/protocols/staking/liquity/v2/
├── bold/                                  # bold/contracts/src/ mirrored 1:1
│   ├── ActivePool.sol
│   ├── AddressesRegistry.sol
│   ├── BoldToken.sol
│   ├── BorrowerOperations.sol
│   ├── CollSurplusPool.sol
│   ├── CollateralRegistry.sol
│   ├── DebtInFrontHelper.sol
│   ├── DefaultPool.sol
│   ├── GasPool.sol
│   ├── HintHelpers.sol
│   ├── MultiTroveGetter.sol
│   ├── RedemptionHelper.sol
│   ├── SortedTroves.sol
│   ├── StabilityPool.sol
│   ├── TroveManager.sol
│   ├── TroveNFT.sol
│   ├── Dependencies/        # AddRemoveManagers, AggregatorV3Interface, Constants,
│   │                        #   LiquityBase, LiquityMath, Ownable
│   ├── Interfaces/          # 30+ I*.sol
│   ├── NFTMetadata/         # MetadataNFT + utils/
│   ├── PriceFeeds/          # MainnetPriceFeedBase + WETH/RETH/WSTETH/Composite
│   ├── Types/               # BatchId, LatestTroveData, LatestBatchData, TroveChange
│   └── Zappers/             # BaseZapper, WETHZapper, GasCompZapper,
│                            #   LeverageWETHZapper, LeverageLSTZapper, LeftoversSweep
│       ├── Interfaces/
│       └── Modules/
│           ├── Exchanges/
│           │   ├── Curve/         # ICurvePool, ICurveStableswapNGPool (local unless ID-identical w/ Crane)
│           │   └── UniswapV3/     # IQuoterV2 etc.
│           └── FlashLoans/
│               └── Balancer/vault/   # IFlashLoanRecipient, IVault (local unless identical)
└── gov/                                   # bold/contracts/lib/V2-gov/src/ mirrored 1:1
    ├── BribeInitiative.sol
    ├── CurveV2GaugeRewards.sol
    ├── Governance.sol
    ├── UniV4MerklRewards.sol
    ├── UserProxy.sol
    ├── UserProxyFactory.sol
    ├── interfaces/
    └── utils/
```

### 4.2 Tests

```
test/foundry/spec/protocols/staking/liquity/v2/
├── bold/                                  # bold/contracts/test/* (non-fork)
│   ├── basicOps.t.sol, BoldToken.t.sol, borrowerOperations.t.sol, …
│   ├── Interfaces/
│   ├── TestContracts/        # BaseTest, DevTestSetup, mocks, *Tester
│   └── Utils/
└── gov/                                   # bold/contracts/lib/V2-gov/test/*

test/foundry/fork/ethereum/protocols/staking/liquity/v2/
└── bold/
    ├── OracleMainnet.t.sol
    ├── E2E.t.sol
    ├── InitiativeSmarDEX.t.sol
    ├── InitiativeUniV4Merkl.t.sol
    └── (zapper-leverage / interface tests requiring mainnet)
```

Triage of which tests are fork vs non-fork is **TBD** (Phase 2 boundary task).

### 4.3 Sinks for missing transitive deps

- Missing Solady pieces → `contracts/solady/<path>` (already in tree: ERC20, ERC721, LibString, SSTORE2, SafeTransferLib, ReentrancyGuard, ECDSA, FixedPointMathLib, LibClone, LibSort)
- Missing forge-std pieces → `contracts/external/forge-std/<path>` (currently absent; create when needed)

## 5. OpenZeppelin v4.9.5 → v5.5.0 adaptation strategy

### 5.1 Bold core (v4.9.5 → v5.5.0)

| OZ symbol | Used by | v4→v5 change | Adaptation |
|---|---|---|---|
| `ERC20Permit` | `BoldToken` | v4 takes name in ctor; v5 also takes name; storage subtly different; uses `Nonces.sol` mixin | Rewrite import; verify ctor chain compiles; verify `Nonces` mixin doesn't conflict with `BoldToken` storage |
| `ERC721` | `TroveNFT` | now `abstract`; hooks removed; custom errors | Bold doesn't override `_before/_afterTokenTransfer` — confirm by grep; ctor unchanged; error assertions in tests rewritten |
| `IERC20`, `IERC20Metadata`, `IERC20Permit`, `IERC5267` | many | interface-stable | Mechanical import rewrite |
| `SafeERC20` | Zappers, BorrowerOperations | string reverts → custom errors (`SafeERC20FailedOperation`) | Mechanical rewrite; test revert assertions adapted |
| `Math`, `SignedMath` | LiquityMath, Zappers | core methods stable; v5 adds extras | Mechanical |
| `IERC721Metadata` | TroveNFT | stable | Mechanical |

### 5.2 V2-gov (v5.0.2 → v5.5.0)

| OZ symbol | Used by | Adaptation |
|---|---|---|
| `IERC20`, `IERC20Permit`, `SafeERC20` | Governance, BribeInitiative, UserProxy | Mechanical |
| `Clones` | UserProxyFactory | Mechanical |
| `ReentrancyGuard` | several | Mechanical |

### 5.3 Mechanical bulk-rewrite rules for Phase 1

```
openzeppelin-contracts/contracts/   →   @crane/contracts/external/openzeppelin-contracts/
openzeppelin/contracts/             →   @crane/contracts/external/openzeppelin-contracts/
Solady/utils/                       →   @crane/contracts/solady/utils/
forge-std/                          →   forge-std/        (Crane's existing remap covers it)
src/                                →   @crane/contracts/protocols/staking/liquity/v2/bold/   (in tests)
../utils/                           →   path-rewritten to gov/utils/   (V2-gov tests)
```

### 5.4 Manual review

- `BoldToken.sol` — verify `ERC20Permit` ctor & `Nonces` storage compat
- `TroveNFT.sol` — verify no removed hook overrides
- Tests with `vm.expectRevert("ERC721: ...")` or string-based `expectRevert` → rewrite to v5 custom-error selectors (discovered by grep during Phase 2)
- Tests with `vm.expectRevert(abi.encodeWithSelector(...))` for OZ errors → update selector

## 6. Remappings, build config, and Solidity version

### 6.1 Remappings (added to `remappings.txt` and `foundry.toml`)

```
# Bold's import style "openzeppelin-contracts/contracts/X" → Crane's port
openzeppelin-contracts/contracts/=contracts/external/openzeppelin-contracts/

# V2-gov's import style "openzeppelin/contracts/X" → same target
openzeppelin/contracts/=contracts/external/openzeppelin-contracts/

# Bold imports "Solady/utils/X" → Crane's Solady
Solady/=contracts/solady/

# Bold tests use "src/X" — only used inside ported test files, rewritten manually to @crane paths
```

(`forge-std/` remap already exists in Crane's config — no change needed.)

### 6.2 Solidity version

- Rewrite every `pragma solidity 0.8.24;` → `pragma solidity ^0.8.35;`
- Verify EVM version: Bold uses `cancun`, Crane builds at `cancun` already
- viaIR: monitor for stack-too-deep; if it appears, refactor to structs (Crane convention — see CLAUDE.md)

### 6.3 Optimizer

Crane uses `optimizer_runs = 1`. Bold uses `200`, V2-gov uses `100000`. Don't change Crane's global setting; if a Bold contract exceeds the 24KB size limit at `runs = 1`, add it to the appropriate sizing exception list rather than diverging the global config.

## 7. Test infrastructure adaptation

### 7.1 Bold test base (`bold/contracts/test/TestContracts/`)

`BaseTest.sol`, `DevTestSetup.sol`, `*Tester.sol`, and the various mocks are heavily reused. They:
- Deploy a full Bold system (CollateralRegistry + per-collateral branches)
- Stub external dependencies (Chainlink mock, RETH/WSTETH mocks)
- Provide test users (Account list)

These port directly to `test/foundry/spec/protocols/staking/liquity/v2/bold/TestContracts/` with import rewrites. They do NOT need to integrate with Crane's `BehaviorBase`/`TestBase_` system — Bold tests are self-contained and should stay that way to preserve audit fidelity.

### 7.2 V2-gov test base

`V2-gov/test/` has its own pattern (uses `forge-std/Test` directly, plus a couple of local mocks). Port as-is to `test/foundry/spec/protocols/staking/liquity/v2/gov/`.

### 7.3 Fork test boundary

Triage by inspecting each `*.t.sol` for:
- Direct mainnet RPC use (`vm.createSelectFork`)
- Mainnet-pinned addresses
- Chainlink/oracle dependence

Files matching → `test/foundry/fork/ethereum/protocols/staking/liquity/v2/bold/`. Everything else → spec.

Known fork tests (preliminary): `OracleMainnet.t.sol`, `E2E.t.sol`, `InitiativeSmarDEX.t.sol`, `InitiativeUniV4Merkl.t.sol`. Will confirm by grep in Phase 2.

### 7.4 Fork config

Crane's existing fork-test pattern at `test/foundry/fork/base_main/slipstream/` uses `vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), <block>)`. Bold fork tests will follow the same convention.

## 6. Remappings & build config (TBD — Section 6)

Will add:
- New remappings for ported paths so Bold-style imports (e.g., `openzeppelin-contracts/contracts/...`) resolve under Crane
- foundry.toml additions if needed
- viaIR / optimizer_runs considerations (Bold runs with `optimizer_runs = 200`, V2-gov `100000`, Crane defaults to `1`)

## 7. Phase plan

### Phase 1 — Foundation & compile

- Add submodule (DONE — `lib/bold` present)
- Decide & document final remapping rules
- Scaffold target directories
- Port source files folder-by-folder, lowest-dependency-depth first:
  - `gov/utils/`, `gov/interfaces/`, then `gov/*.sol`
  - `bold/Dependencies/`, `bold/Types/`, `bold/Interfaces/`
  - `bold/PriceFeeds/`, `bold/NFTMetadata/`
  - `bold/` core contracts (BoldToken, TroveNFT, TroveManager, BorrowerOperations, StabilityPool, etc.)
  - `bold/Zappers/`
- Adapt OZ v4→v5 call sites file-by-file (BoldToken's `ERC20Permit`, TroveNFT's `ERC721`, any `SafeERC20` usage)
- Port any missing Solady/forge-std pieces into their sinks as compile errors uncover them
- **Phase exit criterion:** `forge build` succeeds with no Bold-related errors

### Phase 2 — Non-fork tests

- Port `test/TestContracts/` (BaseTest, DevTestSetup, mocks, *Tester) — much of this is shared infrastructure
- Triage `test/*.t.sol` into fork vs non-fork
- Port non-fork tests, rewriting imports
- Adapt test assertions that check OZ v4 revert strings → v5 custom errors
- **Phase exit criterion:** `forge test --no-match-path "test/foundry/fork/**"` passes for Bold + gov tests

### Phase 3 — Fork & E2E

- Port fork tests into `test/foundry/fork/ethereum/protocols/staking/liquity/v2/bold/`
- Wire `MAINNET_RPC_URL` and fork-block configuration per Crane's existing fork-test conventions (see `test/foundry/fork/base_main/slipstream/`)
- **Phase exit criterion:** fork tests pass against a mainnet fork

### Phase 4 — Cleanup

- Remove `lib/bold` submodule (`git submodule deinit lib/bold && git rm lib/bold`)
- Update `.gitmodules` and `.git/modules`
- Final `forge build` + full test run to confirm parity

## 8. Risks & open questions

- **Fork test data freshness:** E2E and OracleMainnet pin specific mainnet block numbers — they may need updating if state has moved on.
- **Bold ↔ V2-gov coupling at test boundary:** Bold tests sometimes need a deployed Governance; V2-gov tests need a stub BOLD token. Need to handle the test-base sharing without cross-spec contamination.
- **Liquity proprietary license:** Bold is BUSL-1.1. Keep `SPDX-License-Identifier: BUSL-1.1` on every ported file from `src/`; tests are MIT. Verify with maintainer that hosting BUSL-1.1 code inside Crane (Apache-2.0?) doesn't conflict.
- **viaIR & stack depth:** Liquity is known to need `viaIR = true` at low optimizer runs. Crane defaults to `viaIR = false, optimizer_runs = 1`. May need a `[profile.bold]` block or per-contract `unchecked` blocks if stack-too-deep appears.
- **Solady ↔ Crane native utils duplication:** Crane has both `contracts/solady/utils/LibString.sol` and `contracts/utils/LibString.sol`. Bold's MetadataNFT imports `Solady/utils/LibString.sol` — target `contracts/solady/utils/LibString.sol`.

## 9. Progress log

| Date | Phase | Status |
|---|---|---|
| 2026-05-30 | brainstorm | scope, OZ strategy, test split, success criteria, pragma policy, approach all locked |
| 2026-05-30 | brainstorm | submodule added at `lib/bold/` |
| 2026-05-30 | design | Sections 1–4 (layout) drafted & user-approved; 5–7 TBD |
| 2026-05-30 | design | Sections 5–7 added; user approved Section 5 (OZ adaptation); plan written |
| 2026-05-30 | Phase 1 | All 129 src files (gov + bold) ported & compile; bulk OZ-prefix rewrite to `@crane/contracts/external/openzeppelin-contracts/`; OZ shim files added for IERC20/IERC20Metadata/IERC20Permit; broad OZ remap reverted after it broke continuous-clearing tests |
| 2026-05-30 | Phase 2 (partial) | All 136 test files copied + import-rewritten; **user correction received: no new remappings without approval, no new submodules**. Reverted Solady remap (rewrote `Solady/X` → `@crane/contracts/solady/X` directly), reverted @chimera remap, removed `lib/chimera` submodule (ported into `contracts/external/chimera/` instead). Solady Base64 ported into `contracts/solady/utils/Base64.sol`. ERC20MinterMock rewritten (no OZ v4 preset chain). BoldToken IERC20 import added. Test compile still failing — many `IERC20` imports missing in test helpers, more OZ v4→v5 adaptations pending. |
| 2026-05-30 | Phase 2 | All 714 non-fork (spec) tests pass. Final fixes: shim IERC20Metadata to also re-export IERC20; ITroveNFT extends IERC721 + IERC721Metadata; BoldToken `nonces()` explicit override; V2-gov mocks `Ownable()` no-arg; basicOps revert assertions rewritten to OZ v5 `IERC20Errors.ERC20InsufficientAllowance/ERC20InsufficientBalance` selectors; bold_logo/reth_logo/wsteth_logo/weth_logo/geist assets copied to `utils/assets/`; added `read-write utils/assets/test_output` to fs_permissions. |
| 2026-05-30 | Phase 3 | Fork tests split: moved `OracleMainnet.t.sol`, `E2E.t.sol`, `ExchangeHelpers.t.sol`, `InitiativeSmarDEX.t.sol`, `InitiativeUniV4Merkl.t.sol`, `zapperLeverage.t.sol`, `Utils/{E2EHelpers,UseDeployment}.sol` to `test/foundry/fork/ethereum/protocols/staking/liquity/v2/bold/`; moved V2-gov `Curve/UniV4/Governance*/E2E/UserProxy/VotingPower` fork tests to `test/foundry/fork/ethereum/.../v2/gov/`. |
| 2026-05-31 | Phase 3 | 260 / 264 fork tests pass (4 skipped). RPC: rewrote `vm.envString("E2E_RPC_URL"/"MAINNET_RPC_URL")` and `vm.rpcUrl("mainnet")` to Crane's existing `ethereum_mainnet_alchemy` endpoint (avoided Infura HTTP 429). Mocked governance variants get `vm.warp(2592000)` to mirror V2-gov's upstream `block_timestamp` config (Crane's foundry.toml doesn't carry it). |
| 2026-05-31 | Phase 4 | `lib/bold` submodule removed; clean `forge build` succeeds; final test run reconfirms 714 spec + 260 fork = **974 tests passing**. |

## 11. Policy guardrails (user-set during execution)

- **No new remappings** without explicit user approval. Use absolute `@crane/...` paths in imports instead.
- **No new submodules**. Port external code into `contracts/external/<library>/`. Active goal: reduce submodule count, not add.
- **`.claude/settings.*` off-limits** (already in memory).

## 10. Next actions

1. Finish design sections 5 (OZ adaptation), 6 (remappings/build), 7 (test-base infra approach) and get user approval per section
2. Spec self-review
3. Hand off to writing-plans skill for the detailed implementation plan
4. Begin Phase 1 execution
