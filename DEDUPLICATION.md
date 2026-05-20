# Crane Deduplication Report

**Generated:** 2026-05-15 — **Updated:** 2026-05-16 (after substantial execution; re-verified against on-disk state on the same day)

> **New session starting here? Read [Status](#status-2026-05-16--start-here) and [Outstanding work](#outstanding-work-checklist-for-the-next-session) first.**
> The middle of this document (§§1–7) is the original analysis — useful as reference but not the operational state.

## Status (2026-05-16) — start here

> **THE DEDUP ARC IS EFFECTIVELY COMPLETE.** All true byte-identical / structurally-identical duplicates that could be collapsed under the corrected principle (see below) have been collapsed. The "outstanding work" listed in earlier versions of this report was wrong about what counts as dedup — much of it was actually API migrations or version upgrades that, on inspection, would change semantics rather than just collapse copies. See [What remains is NOT dedup](#what-remains-is-not-dedup-2026-05-16) for the post-correction view.

This report was generated on 2026-05-15 from a broad multi-agent inventory and then substantially executed across six sessions ending 2026-05-16. The §2a Aave 3.6 legacy-OZ migration arc is closed: 3 of its files (legacy `Ownable`, `Context`, `AccessControl`) are deleted; the remaining 4 are Aave-specific proxy infrastructure that aren't duplicates (step 5 won't-fix). The total commit count on `dedupe` since `c4422a71` is large but a significant portion of session-6 was a sequence of mistakes + reverts — see [Session-6 mistakes and their correction](#session-6-mistakes-and-their-correction) below for the architectural lesson.

> **Important principle (learned the hard way in session 6):** Crane-native libraries at `contracts/access/*`, `contracts/utils/*`, etc. are **NOT** duplicates of OpenZeppelin's libraries at `contracts/external/openzeppelin-contracts/*`. They are intentionally separate implementations: Crane's `Ownable` wraps Solady and omits `Context` inheritance; OZ's `Ownable` extends `Context` and supports meta-tx via `_msgSender()`. The fact that they have similar method signatures doesn't make them duplicates — they live at different paths because they have different semantics. **Migration target rule: if a consumer uses OZ semantics (Context, `_msgSender`, string reverts, v4 constructor patterns), it routes to `external/openzeppelin/`. If a consumer is Crane-native code, it can use `contracts/access/` / `contracts/utils/`. NEVER cross those boundaries during dedup.**

> **What "dedup" means in this report (post-session-6 definition):** collapsing two files that contain the SAME code (byte-identical or structurally identical at the same OZ version) when one is a per-port bundled copy and the other is centrally vendored. It does NOT mean: migrating across OZ major versions, swapping Crane-native for OZ-vendored (or vice versa), or moving consumers from one canonical declaration to another canonical declaration with the same name. Those are all API/architectural changes, not deduplication.

A re-verification pass at the start of the most recent session confirmed every file count in [Top-level structure](#top-level-structure-post-migration-2026-05-16) below matches on-disk state. That pass found three drift items, two of which were trivial leftovers and one of which was a wrong claim in the outstanding-work list — all addressed in the same session:

- `contracts/external/pendle/` was an empty leftover from the Pendle promotion — `rmdir`'d in `8414f608`.
- `contracts/external/openzeppelin-contracts/interfaces/IERC5805.sol.bak` was a stray backup from the `ed6bb9b5` revert — deleted in `8414f608`.
- §7 step 4 claimed "UnsafeMath — both unused, no consolidation needed." Re-verification found UnsafeMath *is* consumed in both V3 (`SqrtPriceMath` + `SqrtPriceMathPartial`) and V4 (`Pool` + `SqrtPriceMath`). V4 is a strict superset of V3 (adds `simpleMulDiv`); both standalone copies consolidated to `protocols/dexes/uniswap/libraries/UnsafeMath.sol` in `dd1ee41f`. Euler EulerSwap's own UnsafeMath has a different API surface (uint8/int256 overloads) and stays separate.

Other work landed in session 5:
- `3653fd67` — dropped zero-consumer Camelot V2 `UQ112x112.sol` stub. The other three Camelot↔UniV2 stub pairs (`Math`, `SafeMath`, `UniswapV2Library`) are *not* consolidatable — different scopes, different APIs, or protocol-specific (different ICamelot vs IUniswapV2 interfaces). Kept as-is.
- `17d26d96` — moved OZ vendored `security/Pausable.sol` to `utils/Pausable.sol` (mirroring OZ v5's directory layout, mirroring the `4e73ec37` ReentrancyGuard pattern). 3 consumer imports repointed.
- `4be175dd` — dropped zero-consumer OZ vendored `security/PullPayment.sol`. The `security/` directory is now empty and gone, completing §7 step 5's flattening of the historical-path duplicates.
- Aave §2a sequence steps 2-4 landed but with WRONG migration targets — see next section.

Session lesson reinforced (4th time, sessions 1-5): suffix-based greps must catch *both* `@crane/` absolute and `./` / `../` relative imports. Each of the UnsafeMath delete, the Camelot/UniV2 SafeMath check, and the legacy Aave Address.sol delete hit consumers via relative imports that the absolute-path grep missed. Pattern that worked: grep by basename or by trailing path fragment (e.g. `dependencies/openzeppelin/contracts/Address.sol` AND `contracts/Address.sol`).

## Session-6 mistakes and their correction

The Aave §2a migrations from sessions 5 and 6 (steps 2 / 3 / 4 plus the v5-Ownable + ECDSA/ERC20/Multicall/MessageHashUtils portions of step 6b) ALL picked the wrong migration target: they routed Aave's OZ-style consumers to Crane-native libraries (`contracts/access/Ownable.sol` Solady-based, `contracts/utils/{Address,Context}.sol` Crane re-implementations) or to a different-major-version Crane-vendored OZ (`external/openzeppelin/access/AccessControl.sol` v5 when Aave's bundled was v4, removing `_setupRole`). Then forced "fixes" for compile breaks: replaced `_msgSender()` with `msg.sender` (lost meta-tx support), renamed `_setupRole` to `_grantRole` (API change disguised as dedup), and changed v4 `transferOwnership(owner)` patterns to v5 `Ownable(initialOwner)` constructor initializers (observable event-emission change).

**These were API migrations disguised as deduplication, not deduplication.** Per user direction during session 6: "they are not duplicate code. You should have kept the OpenZeppelin Ownable, and kept it in the external/ path for OpenZeppelin."

All session-5-and-6 OZ-migrations were reverted/retargeted in session 6:

| Original commit | What it did wrong | Revert commit |
|---|---|---|
| `9ec14b08` (step 2 Address+Context) | Routed to `@crane/contracts/utils/{Address,Context}.sol` (Crane native) | `a6fe3562` — retargeted to `@crane/contracts/external/openzeppelin-contracts/utils/{Address,Context}.sol` |
| `bbb0e03d` (step 3 Ownable, 9 consumers) | Routed to `@crane/contracts/access/Ownable.sol` (Crane Solady-native, no Context), forced v5 constructor pattern, removed `_msgSender()` from Faucet | `c286cbee` — retargeted to `@crane/contracts/external/openzeppelin-contracts/access/Ownable.sol` (vendored OZ v4.9.0, extends Context); restored v4 `transferOwnership(owner)` constructor pattern; restored Faucet `_msgSender()` |
| `12d144c7` (step 4 AccessControl, ACLManager) | Migrated v4 → v5 with `_setupRole` → `_grantRole` rename | `2b1a1573` — restored bundled v4 `AccessControl.sol`; reverted `_setupRole` |
| `701736a6` (step 6b ECDSA/ERC20/Multicall/MessageHashUtils + v5 Ownable + OwnableWithGuardian `_msgSender` removal) | Routed v5.x consumers to Crane-vendored v5.5 (version drift); v5 Ownable consumers to Crane native | `0cae89a5` — all retargeted back to Aave bundled paths; restored OwnableWithGuardian `_msgSender()` |

**What stayed shipped from session 6:** `72fcbeb9` (SafeCast migration, byte-identical v5.1.0 files between Crane vendored and Aave bundled — a true byte-for-byte duplicate collapse, the only one). 19 Aave consumers now import SafeCast from `@crane/contracts/external/openzeppelin-contracts/utils/math/SafeCast.sol` instead of the bundled copy.

**What stayed shipped from session 5:** The Aave step-3 + step-4 + step-6b code-changes were reverted, but the **legacy `dependencies/openzeppelin/contracts/{Ownable,Context}.sol` deletions stayed** because those files ARE genuine duplicates of the vendored OZ files Crane has at `external/openzeppelin/`. After the retargeting, Aave consumers import directly from `external/openzeppelin/`, removing the per-port bundled copy. Net: 2 OZ files collapsed (Ownable, Context); AccessControl restored because it was a different version, not a dedup target.

**The new dedup baseline (post-revert):** Aave 3.6 still has its `dependencies/openzeppelin-contracts/` v5.x bundle (large), and its `dependencies/openzeppelin-contracts-upgradeable/` v5 upgradeable bundle. Migrating those to Crane-vendored OZ requires Crane to first vendor the equivalent v5.x files (Crane currently has v4.9.0 in `external/openzeppelin/`). That's a separate "extend Crane's vendored OZ to v5.x" piece of work that's out of scope for the dedup sweep.

### Plan coverage

| §7 step | Status | Commits |
|---|---|---|
| **1.** Canonical sources policy | shipped | `da8c0e56` |
| **2.** Protocol promotions (Uniswap V3, Pendle, Redstone) | shipped | `336d3e07`, `1599455a`, `f147084d`, `602fd282` |
| **3.** Bundled-dep removal in ported protocols | **partial** — Euler stubs ✓, launchpad ✓, Aave steps 1-3 ✓ (retargeted to vendored OZ); step 4 reverted; step 5 won't-fix | `8ab87dc4`, `7060ae39`, `ffb6bece`, `514a1e6c`, `cb95c725` (Euler); `06c9e931` (launchpad); `18588888` (Aave step 1); `9ec14b08` + `a6fe3562` (Aave step 2: orig + retarget to vendored OZ); `bbb0e03d` + `c286cbee` (Aave step 3: orig + retarget to vendored OZ); `12d144c7` + `2b1a1573` (Aave step 4: orig + revert); `72fcbeb9` (Aave step 6 SafeCast — only same-version OZ dedup); `701736a6` + `0cae89a5` (Aave step 6b: orig + revert) |
| **4.** Math + TransferHelper consolidation | partial — 6/8 math files + V2 TransferHelper + Camelot UQ112x112 | `2ef70c75`, `7b3e7100`, `dd1ee41f`, `3653fd67` |
| **5.** OZ internal flattening | shipped (incl. `security/` removed) | `4e73ec37`, `7bc71bff`, `1250c9b8`, `17d26d96`, `4be175dd` |
| **6.** forge-std stub | closed as won't-fix | `c52cd2dd` |
| §5 OZ submodule vs vendored investigation | closed as keep-both | `60a99f9d` |

### Commits chronologically (29 total on `dedupe` since `c4422a71`)

1. `336d3e07` — refactor(deps): promote Uniswap V3 into protocols hierarchy
2. `1599455a` — refactor(deps): promote Pendle into protocols/perps hierarchy
3. `f147084d` — fix(deps): repoint import sites missed in 336d3e07 and 1599455a
4. `602fd282` — docs(deps): document RedStone retention policy
5. `197bad2f` — docs: add deduplication plan, mark step 2 as shipped
6. `2ef70c75` — refactor(deps): consolidate Uniswap V3↔V4 duplicated math libraries (5 of 8)
7. `63a8ef93` — docs: mark §7 step 4 partial
8. `c52cd2dd` — docs: close §7 step 6 as won't-fix
9. `7b3e7100` — refactor(deps): consolidate Camelot V2 / Uniswap V2 TransferHelper
10. `83566650` — docs: mark TransferHelper shipped
11. `da8c0e56` — docs: decide canonical sources for utility libraries (§7 step 1)
12. `4e73ec37` — refactor(deps): flatten internal OZ duplicates
13. `e21ea1cd` — docs: mark step 5 shipped + flag follow-ups
14. `7bc71bff` — refactor(deps): sweep zero-consumer thin aliases in OZ interfaces/
15. `60a99f9d` — docs: investigate OZ submodule vs vendored, close as keep-both
16. `8ab87dc4` — refactor(deps): drop 12 unused Euler stubs
17. `7060ae39` — refactor(deps): migrate Euler V3 OracleLibrary to canonical
18. `ffb6bece` — refactor(deps): migrate Euler V4 UniswapHook to canonical (incl API drift)
19. `514a1e6c` — refactor(deps): migrate Euler FeeFlowController off Solmate no-op stubs
20. `cb95c725` — refactor(deps): migrate Euler RedstoneCoreOracle off no-op stubs
21. `79778891` — docs: record Euler stubs migration status
22. `06c9e931` — refactor(deps): remove launchpad bundled deps, migrate to canonical (~80k lines)
23. `8085af81` — docs: record launchpad bundled-dep removal
24. `f626cccf` — docs: Aave 3.6 bundled-OZ investigation findings
25. `18588888` — refactor(deps): drop 7 zero-consumer Aave legacy OZ files (Aave step 1)
26. `15e2d3bd` — fix(deps): collapse broken OZ IERC20 to Crane-canonical re-export (superseded by `1250c9b8`)
27. `1250c9b8` — refactor(deps): delete the OZ-vendored IERC20, point Redstone at canonical
28. `0f93ce75` — refactor(deps): sweep 3 zero-consumer real-definition OZ interfaces (reverted by `ed6bb9b5`)
29. `ed6bb9b5` — Revert "sweep 3 zero-consumer real-definition OZ interfaces"
30. `8414f608` — chore(deps): remove leftover .bak file and empty external/pendle dir
31. `dd1ee41f` — refactor(deps): consolidate Uniswap V3↔V4 UnsafeMath (§7 step 4)
32. `3653fd67` — refactor(deps): drop zero-consumer Camelot UQ112x112 stub
33. `17d26d96` — refactor(deps): flatten OZ security/Pausable to utils/ (§7 step 5 follow-up)
34. `4be175dd` — refactor(deps): drop zero-consumer OZ security/PullPayment
35. `9ec14b08` — refactor(deps): Aave 3.6 step 2 — Address + Context migration (§7 step 3)
36. `bbb0e03d` — refactor(deps): Aave 3.6 step 3 — Ownable migration (§7 step 3)
37. `12d144c7` — refactor(deps): Aave 3.6 step 4 — AccessControl migration (§7 step 3)

### Rules of thumb learned during execution

1. **Stage modifications explicitly before committing renames.** `git mv` / `git rm` auto-stages the file moves but NOT modifications you made to consumer files with sed/Edit. Mistake committed in `336d3e07` and `1599455a`, fixed in `f147084d`. Always `git add` modified files in the same commit as the rename.
2. **Migrating from a stub to a real implementation is a runtime behavior change.** Where stubs are no-ops (Euler's Solmate `SafeTransferLib` did nothing; Redstone's `RedstoneDefaultsLib.getOracleNumericValueFromExtraData` returned 0), migrating to canonical "starts the contract actually working" — usually a correctness fix, but document the behavior change and verify test coverage before considering the contract production-ready.
3. **API drift between stubs and canonical is common when stubs were a snapshot of an older upstream.** Examples this session: Uniswap V4's `SwapParams` moved out of `IPoolManager`; `BeforeSwapDelta` became a value type (no `memory`); RedStone's `getOracleNumericValue` was renamed to `getOracleNumericValueFromTxMsg`; Solady's `SafeTransferLib` takes `address` rather than `ERC20`. Plan for per-consumer code edits in addition to import rewrites.
4. **Use the `@crane/` remapping for every import.** User-mandated rule (see `feedback_crane_imports.md` memory). Convert any surviving relative imports (`./X.sol`, `../libraries/X.sol`, `../../libraries/X.sol`) to the absolute `@crane/contracts/...` form as part of any migration.
5. **Suffix-based sed is the right tool for bulk import rewriting.** Patterns like `s|protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/utils/|utils/|g` rewrite correctly regardless of whether the original used `@crane/` or bare `contracts/` prefix. Saves enumerating both forms.
6. **OZ-vendored tree deletions need TWO greps.** Zero-Crane-consumer files inside `contracts/external/openzeppelin-contracts/` may still be load-bearing for OZ-internal cross-references. `IERC1967.sol` looked deletable but `ERC1967Upgrade` consumes it; same for `IERC6909`/`ERC6909`. **Always verify BOTH Crane-side grep AND OZ-internal grep before deleting.** Mistake in `0f93ce75`, reverted in `ed6bb9b5`.
7. **Foundry build cache can mislead after restructuring.** If you delete or rename files and `forge build` errors with stale paths after sed succeeds, run `rm -rf cache out` and rebuild. Hit once during the V3↔V4 math consolidation.

## Purpose

The Crane repo absorbed code from many upstream sources. The intended layout is:

- `contracts/protocols/<category>/<protocol>/...` — DeFi protocol logic, organized by category (`dexes`, `lending`, `cdps`, `oracles`, `staking`, `tokens`, `wallets`, `l2s`, `launchpads`, `perps`, `utils`).
- `contracts/external/<source>/...` — shared / transitive dependencies of the ported protocols, organized by upstream source (OpenZeppelin, Solady, forge-std, etc.) so multiple protocols can re-use one vendored copy.

In practice the convention is only partially honored. This report inventories what is duplicated, where, and what should be consolidated.

## Top-level structure (post-migration, 2026-05-16)

```
contracts/
  access/            -- Crane-canonical Ownable, Ownable2Step + ERC8023/operable/reentrancy patterns
  interfaces/        -- Crane-canonical IERC20 / IERC20Metadata / ...
  solady/            -- vendored Solady (top-level) -- expanded from 12 to 15 files during the launchpad cleanup
  tokens/            -- Crane-canonical ERC20 stack (incl. SafeTransferLib)
  utils/             -- Crane-native utility wrappers (Strings, SafeCast, SafeCastLib, Math, ...)

  external/                                           current   notes
    balancer/                                         465 .sol  Full Balancer V3, intentionally placed here -- the
                                                                Diamond refactor at protocols/dexes/balancer/v3/
                                                                consumes it (Balancer pattern).
    redstone/                                         175 .sol  Vendored RedStone, retained for future reference
                                                                (no Crane consumers under protocols/, see
                                                                RETENTION.md inside the tree).
    openzeppelin/                                     168 .sol  Crane-modified OZ fork (mixed v4.9 + v5.4),
                                                                NOT a pristine snapshot. Has Crane-imported
                                                                SafeERC20, etc. Keep-both alongside the submodule.
    openzeppelin-upgradeable/                         160 .sol  Vendored OZ upgradeable v5.0.
    pyth/                                               6 .sol  Pyth interface-only.
    ds-test/                                            1 .sol  Dappsys test base.
    forge-std/                                          2 .sol  Mock stubs; submodule has the rest. Kept (won't-fix).
    layerzero/                                          0 .sol  Symlinks only; submodule not initialised.
    -- previously external/uniswap/ (137 .sol)         DELETED in 336d3e07 -- protocols/dexes/uniswap/v3/ canonical
    -- previously external/pendle/ (430 .sol)          MOVED to protocols/perps/pendle/ in 1599455a

  protocols/                                          current   notes
    cdps/sky/                                          84 .sol
    dexes/aerodrome/                                   86 .sol  (v1 + Slipstream)
    dexes/balancer/                                   150 .sol  (V3 Diamond refactor; depends on external/balancer/)
    dexes/camelot/                                     12 .sol  (V2 fork; TransferHelper consolidated)
    dexes/uniswap/                                    291 .sol  (V2/V3/V4 + shared libraries/ for the 5 math files)
    launchpads/ape-express/                             1 .sol
    launchpads/uniswap/continuous-clearing/            34 .sol  (down from ~430; dependencies/ deleted in 06c9e931)
    lending/aave/                                     757 .sol  (down from 764; Aave step 1 dropped 7 dead files)
    lending/euler/                                    246 .sol  (down from 270; stubs/ mostly purged, layerzero kept)
    oracles/chainlink/                                  3 .sol  (interfaces only)
    perps/pendle/                                     430 .sol  (NEW category created during the Pendle promotion)
    staking/reliquary/                                 20 .sol
    tokens/wrappers/                                    5 .sol  (WETH9 + facet)
    utils/permit2/                                     15 .sol
    utils/gsn/                                          2 .sol
    wallets/gnosis/                                     1 .sol
    l2s/superchain/                                    22 .sol
```

## Headline findings

1. **Four `external/` subdirectories contain full ported protocols (Balancer V3, Uniswap V3, Pendle, Redstone). Decisions: Balancer V3 stays in `external/` (the Diamond refactor at `protocols/dexes/balancer/v3/` depends on it); Uniswap V3 promotes into `protocols/dexes/uniswap/v3/`; Pendle promotes into a new `protocols/perps/pendle/`; Redstone stays in `external/` for future reference.**
2. **At least three protocol families ship private vendored copies of OpenZeppelin and/or Solady inside their own tree**, instead of importing from `contracts/external/`.
3. **Aave v3.6 carries two competing OpenZeppelin versions** (`dependencies/openzeppelin/` ^0.8.0 *and* `dependencies/openzeppelin-contracts/` ^0.8.20) plus an upgradeable variant — three OZ generations live inside one ported protocol.
4. **Cross-protocol duplication** of common files reaches 7–9 copies for the most common basenames (`IERC20`, `ERC20`, `Ownable`, `SafeERC20`, `SafeTransferLib`, `ReentrancyGuard`, `SafeCast`).
5. **Most protocols, however, have clean import boundaries** — they don't reach into sibling protocols. The duplication is bundled, not entangled, so a consolidation pass is mostly a path-rewrite plus delete operation rather than a refactor.

---

## 1. Protocol-shaped contents of `contracts/external/`

Four `external/` subdirectories hold what *looks like* protocol logic at first glance — full vault contracts, pool factories, routers. An initial pass through this report recommended moving all four under `contracts/protocols/`. That recommendation was wrong for at least Balancer and partly wrong for the others. Corrected analysis based on import-graph evidence:

| Path | Size | Diamond-refactored consumer in `protocols/` | Other consumers | Status |
|---|---:|---|---|---|
| `contracts/external/balancer/v3/` | 465 | `contracts/protocols/dexes/balancer/v3/` — 112 of 150 files import from it; vault & router were refactored to Diamond facets at `vault/diamond/facets/` and `router/diamond/facets/` because the monolithic Vault was too large to deploy; pool-weighted / pool-stable / pool-gyro / pool-constProd / pool-cow / pool-utils / reclamm / rateProviders / hooks all live in `protocols/` and consume `external/`'s interfaces, libraries, and solidity-utils. | 2 files in `dexes/uniswap` and 2 in `dexes/camelot` (only for `IWETH`). | **Decision: leave in place.** `external/balancer/v3/` is the upstream-pinned source for the Diamond refactor. |
| `contracts/external/uniswap/` | 137 | None today — `protocols/dexes/uniswap/` does not import from `external/uniswap/`; it carries its own V2/V3/V4 trees independently. | `protocols/lending/euler/v1/` imports V3 interfaces for the EulerSwap oracle adapter. | **Decision: promote into `contracts/protocols/dexes/uniswap/`.** Move `external/uniswap/v3-core/` and `external/uniswap/v3-periphery/` under the existing `protocols/dexes/uniswap/v3/` hierarchy (merging where filenames already coexist), then rewrite Euler's V3 interface imports to the new paths. Once moved, `external/uniswap/` is gone from `external/`. |
| `contracts/external/pendle/` | 430 | No Pendle Diamond consumer exists today. | `protocols/lending/euler/v1/` — 4 files import Pendle interfaces (oracle adapters for PT/YT). | **Decision: promote in full into `contracts/protocols/perps/pendle/`** (new `perps` category under `contracts/protocols/`). Keep the entire 430-file tree intact as the upstream source, then rewrite Euler's 4 Pendle imports to the new paths. |
| `contracts/external/redstone/` | 173 | None. | **Zero importers anywhere under `contracts/protocols/`.** The only imports from `external/redstone/` are inside `external/redstone/` itself. | **Decision: keep in `external/` for future reference and use.** No move; no deletion. Document that this tree currently has no consumers but is intentionally retained. |

Key insight: `contracts/external/<protocol>/` directories are not automatically misplaced just because they contain protocol-shaped contracts. The Balancer V3 case shows one valid pattern — the upstream-pinned source lives in `external/` and the Diamond-refactored facets that consume its interfaces/libraries/utils live in `protocols/`. Redstone shows another — a vendored protocol that is intentionally retained for future reference even with no current consumer. Uniswap V3 and Pendle, by contrast, are being promoted into `protocols/` because that's the more natural home for an upstream that the team owns and intends to refactor or extend in-place.

Cross-tree imports already point to `external/balancer/v3/` as a library (e.g. `dexes/uniswap` and `dexes/camelot` import `IWETH` from `@crane/contracts/external/balancer/v3/interfaces/.../IWETH.sol`). That import is fine in shape but suggests IWETH should be promoted to a more neutral home (e.g. `contracts/external/openzeppelin-contracts/.../IWETH.sol`-equivalent or `contracts/tokens/wrappers/`) rather than reach into Balancer's tree for a generic interface.

---

## 2. Misnested vendored dependencies inside protocols

Three protocol trees ship private copies of libraries that already exist in `contracts/external/` and/or as Crane-canonical replacements at the repo root.

### 2a. `contracts/protocols/lending/aave/v3.6/dependencies/`

Aave v3.6 vendors **three OpenZeppelin generations** in parallel:

- `dependencies/openzeppelin/contracts/...` — old style (^0.8.0), files like `Ownable.sol` (1.6 KB), `Address.sol` (5.9 KB)
- `dependencies/openzeppelin-contracts/contracts/...` — modern v5.x (^0.8.20), full duplicate set: `Ownable.sol`, `Ownable2Step.sol`, `Address.sol`, `Context.sol`, `AccessControl.sol`, `Initializable.sol`, `ReentrancyGuard.sol`, `ReentrancyGuardTransient.sol`, `ERC20.sol`, `IERC20.sol`, `SafeERC20.sol`, `ECDSA.sol`, etc., plus `certora/harnesses/` mocks
- `dependencies/openzeppelin-contracts-upgradeable/contracts/...` — upgradeable variants
- Aave-specific math kept here: `WadRayMath.sol`, `PercentageMath.sol`, `MathUtils.sol` — these *do* belong with Aave (protocol-specific)
- Plus the surprising `dependencies/openzeppelin-contracts/lib/forge-std/src/interfaces/IERC20.sol` — forge-std's stub interface vendored four levels deep inside Aave's inlined OZ checkout

Recommendation: keep the WadRay/Percentage/MathUtils libraries (Aave-specific), drop the entire `dependencies/openzeppelin*` trees, and rewrite imports to `@crane/contracts/external/openzeppelin-contracts/...` (or to the Crane-canonical `contracts/access/`, `contracts/utils/`, `contracts/tokens/ERC20/` wrappers, depending on which the rest of the repo prefers).

### 2a investigation (2026-05-16) — facts before any code changes

| Bundled tree | Files | Aave consumers | OZ era |
|---|---:|---:|---|
| `dependencies/openzeppelin/` | 14 | 17 | v4.4.1, pragma `^0.8.10` |
| `dependencies/openzeppelin-contracts/` | 318 | 126 | v5.x, pragma `^0.8.20` |
| `dependencies/openzeppelin-contracts-upgradeable/` | 195 | 5 | v5.x upgradeable, pragma `^0.8.20` |

**Legacy tree (`dependencies/openzeppelin/`) — narrowest scope, best starting point:**

- Only 4 of the 14 files have any consumer at all. Imports per file:
  - `Ownable.sol` — 9 imports
  - `Address.sol` — 3
  - `Context.sol` — 2
  - `AccessControl.sol` — 1
- 3 files in the `upgradeability/` subtree are consumed by Aave's `misc/aave-upgradeability/` adapters:
  - `BaseUpgradeabilityProxy.sol` → `BaseImmutableAdminUpgradeabilityProxy.sol`
  - `InitializableUpgradeabilityProxy.sol` and `Proxy.sol` → `InitializableImmutableAdminUpgradeabilityProxy.sol`
- 7 files have **zero consumers anywhere in the repo and are safely deletable as a single-commit cleanup**:
  - `ERC165.sol`
  - `IAccessControl.sol`
  - `Strings.sol`
  - `upgradeability/AdminUpgradeabilityProxy.sol`
  - `upgradeability/BaseAdminUpgradeabilityProxy.sol`
  - `upgradeability/InitializableAdminUpgradeabilityProxy.sol`
  - `upgradeability/UpgradeabilityProxy.sol`
  All four upgradeability deletions form a closed dead cluster — they only reference each other internally, and nothing outside the cluster touches them.
- `AccessControl.sol` (still used by 1 Aave consumer) is itself wired oddly: it imports `IAccessControl`, `Context`, `Strings`, and `ERC165` **from the v5.x tree**, not the sibling legacy files. So the legacy tree is partly cross-wired to the modern tree.

**API drift risks for migrating the 4 actively-used legacy files to Crane natives:**

- `Address.sol` (3 consumers, stateless library) → `@crane/contracts/utils/Address.sol`. API surface is essentially unchanged across OZ v4→v5. **Likely a clean import-only rewrite.**
- `Context.sol` (2 consumers, inheritance with `_msgSender`) → `@crane/contracts/utils/Context.sol`. Same story. **Likely clean.**
- `Ownable.sol` (9 consumers, inheritance) → `@crane/contracts/access/Ownable.sol`. **API-breaking.** Aave's legacy Ownable uses the v4 `constructor()` pattern that auto-assigns `msg.sender` as owner. Crane's `contracts/access/Ownable.sol` wraps Solady's Ownable which follows the v5+ `Ownable(initialOwner)` pattern — every Aave contract that inherits `is Ownable` would need its constructor updated to pass `msg.sender` explicitly. Needs per-consumer code edit and Aave-test verification.
- `AccessControl.sol` (1 consumer, inheritance). Crane has no native AccessControl (per §7 step 1 table — the Crane-native alternative is `contracts/access/operable/`). Migrating would be either (a) repoint to `@crane/contracts/external/openzeppelin-contracts/access/AccessControl.sol` (which the canonical-sources table calls the "fallback when a port needs the exact upstream API") or (b) refactor to `operable`. Option (a) is the lower-risk choice.

**v5.x tree (`dependencies/openzeppelin-contracts/`) — top imported paths:**

`SafeCast.sol` (35×), `Math.sol` (17×), `Address.sol` (17×), `ECDSA.sol` (12×), `SafeERC20.sol` (9×), `Strings.sol` (8×), `IGovernor.sol` (8×), `Checkpoints.sol` (7×), `TransparentUpgradeableProxy.sol` (7×), `draft-IERC6093.sol` (7×), `Arrays.sol` (6×), `IERC20Permit.sol` (6×), `IAccessControl.sol` (6×), `Time.sol` (5×), `EnumerableSet.sol` (5×).

All these exist in Crane's vendored OZ at `contracts/external/openzeppelin-contracts/...`. API-compatible in principle (both v5.x), but Crane's vendored fork has internal import rewrites (e.g. `SafeERC20.sol` imports `IERC20` from `@crane/contracts/interfaces/IERC20.sol` rather than the OZ sibling). Migrating 126 Aave consumer imports would route Aave through Crane's slightly-modified OZ — **net effect: Aave starts depending on `contracts/interfaces/IERC20.sol`** instead of the bundled `dependencies/openzeppelin-contracts/.../IERC20.sol`. Likely fine in practice (interfaces are structural) but warrants verification.

**Upgradeable tree (`dependencies/openzeppelin-contracts-upgradeable/`) — top imported paths:**

`PausableUpgradeable.sol` (2×), `ERC20PermitUpgradeable.sol` (2×), `Initializable.sol` (2×), `ReentrancyGuardUpgradeable.sol` (1×), `ERC4626Upgradeable.sol` (1×), `ERC20Upgradeable.sol` (1×), `OwnableUpgradeable.sol` (1×), `AccessControlUpgradeable.sol` (1×).

These have analogues in `contracts/external/openzeppelin-upgradeable/`, but the Crane-canonical preference (per §7 step 1) for new code is **Diamond's `PostDeployHookFacet` pattern**, not OZ's upgradeable `Initializable`. Aave's choice of OZ upgradeable proxies is a design decision baked into how it deploys — not something to flip lightly.

**Recommended migration sequence for Aave (per-step):**

1. **Cleanup — zero-consumer legacy file deletion (low risk, single commit).** Delete the 7 dead legacy files. Expected impact: 7 file deletions, 0 import rewrites, no consumer-side changes.
2. **Migrate legacy `Address.sol` and `Context.sol` consumers to Crane natives** (low risk, ~5 consumer-file rewrites).
3. **Migrate legacy `Ownable.sol` consumers** (medium risk, 9 consumer files; each needs constructor signature update to pass `msg.sender` explicitly; needs Aave test verification).
4. **Migrate legacy `AccessControl.sol` consumer** (medium risk, 1 consumer file; choice between OZ vendored fallback and Crane `operable` rewrite).
5. **After 1-4: delete the entire legacy `dependencies/openzeppelin/` tree** (saves 14 files including the 7 from step 1 plus the 4 actively used after migration plus the 3 used by `misc/aave-upgradeability/` adapters — those 3 also need migration to a canonical proxy implementation, or accept that they're Aave-specific frozen artifacts).
6. **(Large) Migrate the 126 v5.x `dependencies/openzeppelin-contracts/` consumers to `@crane/contracts/external/openzeppelin-contracts/...`.** Expect to spend most of the effort here. Run Aave's test suite after each batch — Aave already has ~75 pre-existing failures, so noise/signal separation is itself work.
7. **(Largest) Migrate the 5 `dependencies/openzeppelin-contracts-upgradeable/` consumers** — but consider deferring or design-discussing whether Aave should stay on OZ upgradeable patterns at all.

Each step needs Aave's test suite run after migration (`forge test` excluding fork tests). Per `MEMORY.md`, the full non-fork test suite is ~8-9 minutes and currently has ~75 failing tests of unrelated provenance — pre-existing/environmental failures must be distinguished from new ones introduced by the migration.

### 2b. `contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/`

This single launchpad ships **396 vendored .sol files**:

- `dependencies/openzeppelin-contracts/contracts/...` — complete OZ checkout (88 files)
- `dependencies/solady/src/...` — complete Solady checkout (251 files)
- `dependencies/v4-periphery/...` — Uniswap V4 periphery (52 files)
- `dependencies/blocknumberish/` — 5 files

Both OZ and Solady are also vendored elsewhere in the repo (see §3). Recommendation: drop the `dependencies/openzeppelin-contracts/` and `dependencies/solady/` subtrees entirely, point its imports at `contracts/external/openzeppelin-contracts/...` and `contracts/solady/...`. The `v4-periphery/` subtree should consolidate with `contracts/protocols/dexes/uniswap/v4/`.

**Completed 2026-05-16** in commit `06c9e931`. The entire `dependencies/` tree was deleted (~390 vendored files, 80,168 lines). Investigation found only 10 of the ~396 bundled files were actually imported by launchpad code; the rest were transitive. Migration:

| Dep file | Canonical replacement |
|---|---|
| `blocknumberish/src/BlockNumberish.sol` | promoted to `protocols/launchpads/uniswap/continuous-clearing/src/libraries/BlockNumberish.sol` (launchpad-specific utility, kept in launchpad tree) |
| `openzeppelin-contracts/.../token/ERC1155/IERC1155.sol` | `external/openzeppelin/token/ERC1155/IERC1155.sol` |
| `openzeppelin-contracts/.../utils/Create2.sol` | `utils/Create2.sol` (Crane-native, per §7 step 1) |
| `solady/src/tokens/ERC20.sol` | `solady/tokens/ERC20.sol` (already vendored) |
| `solady/src/utils/FixedPointMathLib.sol` | `solady/utils/FixedPointMathLib.sol` (already vendored) |
| `solady/src/utils/ReentrancyGuardTransient.sol` | promoted to `solady/utils/ReentrancyGuardTransient.sol` (expand Crane's Solady curation) |
| `solady/src/utils/SSTORE2.sol` | promoted to `solady/utils/SSTORE2.sol` (expand Crane's Solady curation) |
| `solady/src/utils/SafeCastLib.sol` | `utils/SafeCastLib.sol` (Crane canonical; byte-identical Solady file) |
| `solady/src/utils/SafeTransferLib.sol` | `solady/utils/SafeTransferLib.sol` (already vendored) |
| `v4-periphery/src/libraries/ActionConstants.sol` | `protocols/dexes/uniswap/v4/libraries/ActionConstants.sol` (Crane V4 port) |

Plus `solady/src/tokens/ERC1155.sol` was promoted to `solady/tokens/ERC1155.sol` (used by `contracts/test/stubs/MockERC1155.sol`). Total: 4 files promoted into canonical locations, 36 consumer files repointed (both `@crane/` and bare `contracts/` prefix forms), entire `dependencies/` tree deleted.

forge build green.

### 2c. `contracts/protocols/lending/euler/v1/stubs/`

Euler v1 carries protocol-stub copies of dependencies it links against:

- `stubs/solmate/tokens/ERC20.sol` (~18 lines)
- `stubs/solmate/utils/SafeTransferLib.sol` (~12 lines)
- `stubs/openzeppelin/...`
- `stubs/pyth/...`
- `stubs/redstone/...`
- `stubs/pendle/...`
- `stubs/uniswap/...`
- `stubs/layerzero/...`

These are deliberately tiny — they exist so Euler's oracle adapters can `import { … } from "stubs/…"` without hauling the full upstream libs. Now that the corresponding full libs exist under `contracts/external/`, the stubs are stale aliases. Recommendation: rewrite Euler's adapter imports to point at `contracts/external/<source>/...` and delete `lending/euler/v1/stubs/`.

**Status as of 2026-05-16** (commits `8ab87dc4`, `7060ae39`, `ffb6bece`, `514a1e6c`, `cb95c725`):

| Stub category | Action taken | Notes |
|---|---|---|
| `stubs/uniswap/v3-core/contracts/interfaces/` (IUniswapV3Factory, IUniswapV3Pool) | **Deleted** — 0 consumers | Aliased by zero-consumer sweep in `8ab87dc4`. |
| `stubs/uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol` | **Deleted** — migrated to canonical | Repointed `UniswapV3Oracle.sol` to `@crane/contracts/protocols/dexes/uniswap/v3/periphery/libraries/OracleLibrary.sol` in `7060ae39`. |
| `stubs/uniswap/v4-core/src/{interfaces,libraries,types}/` + `stubs/uniswap/v4-periphery/src/utils/BaseHook.sol` (7 files) | **Deleted** — migrated to canonical | Repointed `UniswapHook.sol` to Crane V4 in `ffb6bece`. Required real code refactor: `SwapParams` moved out of `IPoolManager`, `BeforeSwapDelta` is now a value type (no `memory`), `Hooks.validateHookPermissions` takes `IHooks` instead of `address`. |
| `stubs/openzeppelin/{governance/TimelockController,token/ERC20/extensions/ERC20Wrapper}.sol` | **Deleted** — 0 consumers | Aliased by zero-consumer sweep in `8ab87dc4`. |
| `stubs/pyth/{IPyth,PythStructs}.sol` | **Deleted** — 0 consumers | Aliased by zero-consumer sweep in `8ab87dc4`. |
| `stubs/pendle/core-v2/interfaces/{IPMarket,IPPYLpOracle,IPPrincipalToken,IPYieldToken,IStandardizedYield}.sol` | **Deleted** — 0 consumers | After commit `f147084d` repointed Euler's Pendle oracle adapter to the promoted `protocols/perps/pendle/` tree, these became orphan. Aliased by `8ab87dc4`. |
| `stubs/solmate/{tokens/ERC20,utils/SafeTransferLib}.sol` | **Deleted** — migrated to canonical | The Solmate `SafeTransferLib` stub was a complete no-op (every transfer function was empty). `FeeFlowController` was effectively deployment-broken. Migrated to `@crane/contracts/utils/SafeERC20.sol` (OZ-API wrapper around Solady) in `514a1e6c` — **runtime behavior change**: transfers now actually move tokens. |
| `stubs/redstone/evm-connector/{core/RedstoneDefaultsLib,data-services/PrimaryProdDataServiceConsumerBase}.sol` | **Deleted** — migrated to canonical | The stubs returned 0 prices; `RedstoneCoreOracle.updatePrice()` would have always reverted with `PriceOracle_InvalidAnswer`. Migrated to `contracts/external/redstone/packages/evm-connector/contracts/...` in `cb95c725` — **runtime behavior change**: real RedStone primary-prod signer validation now active. Required renaming `getOracleNumericValue` → `getOracleNumericValueFromTxMsg` and adding `override` to `validateTimestamp`. |
| `stubs/layerzero/...` (4 files: IOFT, ILayerZeroComposer, OFTAdapterUpgradeable, OFTCore) | **Kept (won't-fix)** | The canonical at `contracts/external/layerzero/` is broken symlinks to `lib/evk-periphery/lib/layerzero-devtools/` (submodule not initialized in this checkout), and `paths.txt` says the real source is expected from `node_modules/@layerzerolabs/...` (not present). 5 Euler consumers depend on these stubs (`FeeFlowControllerEVK`, `MintBurnOFTAdapter`, `OFTFeeCollectorGulper`, `OFTAdapterUpgradeable`, `OFTFeeCollector`). Cannot migrate without first initializing the Layerzero submodule or installing the npm package — out of scope for this dedup pass. |
| `stubs/openzeppelin/{governance,token,...}/` parents and `stubs/layerzero/.../oapp/OAppSender.sol` | **Deleted** — 0 consumers | Aliased by zero-consumer sweep in `8ab87dc4`. |
| `stubs/hardhat/console.sol` | **Kept intentionally** | A no-op `library console` used by Pendle (`ActionMarketAuxStatic.sol`) and Redstone (`HardhatLoggerLib.sol`) to silently swallow `console.log` calls in production. Switching to `forge-std/console.sol` (the canonical) would print logs during tests, changing runtime behavior. Keep as the no-op shim. |

After this pass `stubs/` contains only the layerzero/ subtree and the hardhat/ console shim — both intentionally retained for the reasons above.

---

## 3. Cross-tree duplication of common files

Top duplicate basenames across the entire `contracts/` tree (excluding test directories):

| Basename | Copies | Notes |
|---|---:|---|
| `SafeCast.sol` | 9 | OZ, Uniswap V3, Uniswap V4, Pendle Kyber, Aave OZ ×2, launchpad OZ, Crane top-level, Crane utils |
| `IERC721.sol` | 9 | OZ + per-protocol vendored copies |
| `IERC1271.sol` | 9 | same pattern |
| `Errors.sol` | 8 | each protocol has its own |
| `ERC721.sol` | 8 | OZ, Solady, launchpad OZ, launchpad Solady, Aave OZ, top-level, etc. |
| `ERC20.sol` | 8 | (see breakdown below) |
| `ReentrancyGuard.sol` | 7 | (see breakdown below) |
| `Ownable.sol` | 7 | (see breakdown below) |
| `Multicall.sol` | 7 | OZ, Uniswap V3 periphery, launchpad ×2, etc. |
| `IERC721Receiver.sol`, `IERC721Metadata.sol`, `IERC721Enumerable.sol`, `IERC4626.sol`, `IERC20Metadata.sol`, `IERC20.sol`, `IERC1155Receiver.sol`, `IERC1155.sol` | 7 each | OZ + per-protocol vendored interface copies |
| `UUPSUpgradeable.sol`, `TransferHelper.sol`, `SafeTransferLib.sol`, `Proxy.sol`, `Math.sol`, `Initializable.sol`, `IERC1155MetadataURI.sol`, `ERC4626.sol`, `EIP712.sol`, `ECDSA.sol` | 6 each | same pattern |

Concrete breakdowns for the most-duplicated runtime contracts:

### `IERC20.sol` (7 copies)
```
contracts/interfaces/IERC20.sol                                                                          [Crane canonical]
contracts/tokens/ERC20/IERC20.sol                                                                        [Crane canonical, ERC20 dir]
contracts/external/openzeppelin-contracts/interfaces/IERC20.sol                                                    [OZ alias]
contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol                                                   [OZ canonical]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/interfaces/IERC20.sol      [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol     [drop with §2b]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/lib/forge-std/src/interfaces/IERC20.sol                   [drop with §2a]
```
Even after §2 cleanup, the remaining four (`contracts/interfaces/`, `contracts/tokens/ERC20/`, `external/openzeppelin/interfaces/`, `external/openzeppelin/token/ERC20/`) need a policy decision: **which one is canonical?** The two OZ copies should reduce to one (the OZ `interfaces/` file is just an alias for the `token/ERC20/` file). The two Crane copies overlap with each other and with OZ; the repo should pick one (probably `contracts/interfaces/IERC20.sol`) and have the others re-export.

### `ERC20.sol` (8 copies)
```
contracts/solady/tokens/ERC20.sol                                                                        [Solady canonical]
contracts/tokens/ERC20/ERC20.sol                                                                         [Crane canonical]
contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol                                                    [OZ canonical]
contracts/protocols/lending/euler/v1/stubs/solmate/tokens/ERC20.sol                                      [drop with §2c]
contracts/protocols/dexes/uniswap/v4/external/solmate/tokens/ERC20.sol                                   [vendored Solmate inside V4]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/solady/src/tokens/ERC20.sol      [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol  [drop with §2b]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol                       [drop with §2a]
```
Five of eight collapse via §2. The remaining three (Crane, OZ, Solady) coexist legitimately as different implementations; the repo just needs a doc note on when each is preferred.

### `SafeERC20.sol` / `SafeTransferLib.sol` (10 copies combined)
```
contracts/utils/SafeERC20.sol                                                                            [Crane wrapper -> SafeTransferLib]
contracts/solady/utils/SafeTransferLib.sol                                                               [Solady canonical]
contracts/tokens/ERC20/utils/SafeTransferLib.sol                                                         [Crane canonical for ERC20 stack]
contracts/external/openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol                                          [OZ canonical]
contracts/protocols/lending/euler/v1/stubs/solmate/utils/SafeTransferLib.sol                             [drop with §2c]
contracts/protocols/dexes/uniswap/v4/external/solmate/utils/SafeTransferLib.sol                          [vendored Solmate inside V4]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/solady/src/utils/SafeTransferLib.sol      [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/solady/src/utils/ext/zksync/SafeTransferLib.sol  [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol  [drop with §2b]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol  [drop with §2a]
```
After §2: four copies remain (Crane wrapper, Crane ERC20-stack, Solady, OZ). `contracts/utils/SafeERC20.sol` already wraps Solady's `SafeTransferLib` — clarify policy on whether `contracts/tokens/ERC20/utils/SafeTransferLib.sol` is meant to be that same wrapper or a separate Solady fork.

### `Ownable.sol` (7 copies, with 5 more `Ownable2Step`/`Upgradeable` siblings)
```
contracts/access/Ownable.sol                                                                             [Crane canonical]
contracts/solady/auth/Ownable.sol                                                                        [Solady canonical]
contracts/external/openzeppelin-contracts/access/Ownable.sol                                                       [OZ canonical]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin/contracts/Ownable.sol                    [drop with §2a]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/solady/src/auth/Ownable.sol      [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/access/Ownable.sol  [drop with §2b]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/access/Ownable.sol   [drop with §2a]
```
Plus: Ownable2Step duplicated identically across the same paths; `OwnableUpgradeable.sol` and `Ownable2StepUpgradeable.sol` duplicated under `external/openzeppelin-upgradeable/` and Aave's `openzeppelin-contracts-upgradeable/` (drop with §2a); Aave-specific `OwnableWithGuardian.sol` is legitimate and stays.

### `ReentrancyGuard.sol` (7 copies, plus 8 transient/upgradeable variants)
```
contracts/utils/ReentrancyGuard.sol                                                                      [Crane canonical]
contracts/solady/utils/ReentrancyGuard.sol                                                               [Solady canonical]
contracts/external/openzeppelin-contracts/security/ReentrancyGuard.sol                                             [OZ legacy path]
contracts/external/openzeppelin-contracts/utils/ReentrancyGuard.sol                                                [OZ modern path -- internal OZ dup]
contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol      [drop with §2a]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol  [drop with §2b]
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/solady/src/utils/ReentrancyGuard.sol       [drop with §2b]
```
Note the OZ vendored copy itself contains an internal duplicate (`security/` path *and* `utils/` path) — that is an upstream-OZ historical artifact still present in the vendor and should also be reduced.

### `FullMath.sol` (5 copies)
```
contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol                                              [Crane Uniswap V3 fork]
contracts/protocols/dexes/uniswap/v4/libraries/FullMath.sol                                              [Crane Uniswap V4 fork]
contracts/external/uniswap/v3-core/contracts/libraries/FullMath.sol                                      [vendored upstream V3 -- drop with §1]
contracts/protocols/lending/euler/v1/euler-swap/math/FullMath.sol                                        [Euler EulerSwap copy]
contracts/external/pendle/contracts/core/StandardizedYield/implementations/Kyber/libraries/FullMath.sol  [Pendle/Kyber adapter copy -- moves with §1]
```
Within Uniswap, V3 and V4 carry near-identical copies (V3: 129 lines, V4: 120 lines, only pragma and comments diverge). Same pattern for `BitMath.sol`, `FixedPoint96.sol`, `FixedPoint128.sol`, `TickMath.sol`, `SqrtPriceMath.sol`, `SafeCast.sol`, `UnsafeMath.sol`. **Recommendation:** lift these into a single `contracts/external/uniswap-math/` (or `contracts/protocols/dexes/uniswap/libraries/`) shared by both V3 and V4 — they're the same library upstream split across versions only because Uniswap re-released them with cosmetic changes.

### `TransferHelper.sol` (6 copies)
- `contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol` (35 lines)
- `contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol` (35 lines, **identical to Camelot's**)
- `contracts/protocols/dexes/uniswap/v3/libraries/TransferHelper.sol` (19 lines)
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/TransferHelper.sol` (47 lines)
- plus copies inside Aave and the launchpad's vendored OZ
The Camelot/Uniswap V2 pair is a free win — identical files, easy consolidation.

### `Multicall.sol` (7 copies)
- OZ canonical + Aave/launchpad bundled copies (drop with §2a/§2b)
- `contracts/protocols/dexes/uniswap/v3/periphery/base/Multicall.sol` (Uniswap-specific batching variant — keep)

---

## 4. Internal duplicates inside `contracts/external/openzeppelin-contracts/`

The vendored OZ copy itself contains historical-path duplicates that should be flattened to its current canonical paths:

| File | Duplicate locations | Action |
|---|---|---|
| `IERC20.sol` | `interfaces/IERC20.sol` (alias) + `token/ERC20/IERC20.sol` (full) | Drop the alias, point importers at the full file |
| `ReentrancyGuard.sol` | `security/ReentrancyGuard.sol` + `utils/ReentrancyGuard.sol` | Pick one OZ path (modern is `utils/`), drop the other |
| `Initializable.sol` | `external/openzeppelin/proxy/utils/Initializable.sol` (166 lines, v5.1–5.2) vs `external/openzeppelin-upgradeable/proxy/utils/Initializable.sol` (228 lines, v5.0+) | Different OZ generations — note in a README which is intended for which use case |
| `EnumerableSet.sol` | `external/openzeppelin/utils/structs/EnumerableSet.sol` (792 lines, v5.x) vs `external/balancer/v3/solidity-utils/contracts/openzeppelin/EnumerableSet.sol` (176 lines, Balancer's pinned snapshot) | Move with §1 (Balancer relocation); Balancer's pinned subset can stay as a vendored choice inside `protocols/dexes/balancer/` |

---

## 5. Submodule vs vendored mismatches

| Upstream | Submodule (`lib/`) | Vendored (`contracts/external/`) | Resolution |
|---|---|---|---|
| forge-std | `lib/forge-std` (full, version 8b531a01) | `contracts/external/forge-std/mocks/{MockERC20,MockERC721}.sol` | **Keep the stub.** The submodule version no longer ships `src/mocks/`, but Aave's `test/foundry/spec/protocols/lending/aave/3.6/treasury/Collector.t.sol` actively imports `MockERC20` from the stub. Closed as won't-fix on 2026-05-15 (see §7 step 6). |
| OpenZeppelin | `lib/openzeppelin-contracts` (v5.6.1, 338 .sol files) | `contracts/external/openzeppelin-contracts/` (mixed v4.x/v5.x, Crane-modified, 169 .sol files) | **Keep both.** Investigation 2026-05-15 found the two are not interchangeable — see "OZ submodule vs vendored: investigation" below. |
| ds-test | none | `contracts/external/ds-test/test.sol` | Keep — Dappsys is intended as a vendored base |
| layerzero | (`lib/evk-periphery/lib/layerzero-devtools/` via symlinks) | `contracts/external/layerzero/` (symlinks only) | Keep — it's just a path indirection |

### OZ submodule vs vendored: investigation (2026-05-15)

The original analysis assumed `lib/openzeppelin-contracts` was v4.8 and `contracts/external/openzeppelin-contracts/` was v5.x — that "different major versions" framing was wrong. Findings:

**Submodule** (`lib/openzeppelin-contracts`, commit `5fd1781b` = OZ v5.6.1):
- Clean upstream snapshot.
- 338 `.sol` files.
- Resolves via Foundry's auto-discovery as `@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/`.
- Used by 82 consumers across the repo: Pendle (35 files), test fixtures (27), Redstone (9), Uniswap V4 ports (8), `contracts/tokens/` natives (2), `protocols/tokens/wrappers/` (1).
- Top imported symbols: `IERC20` (35×), `SafeERC20` (25×), `UUPSUpgradeable` (20×), `IERC20Metadata` (10×), `SafeCast` (8×), `Proxy` (4×).

**Vendored** (`contracts/external/openzeppelin-contracts/`, headers report v5.4.0 for most files):
- **Not a pristine snapshot — Crane-modified fork.** Examples:
  - `token/ERC20/IERC20.sol` (v5.4.0 header) has its **interface body entirely commented out** — dead code that compiles to nothing. Currently zero consumers in the repo so the build passes, but the file is broken. Surfaced earlier as a §7 step 5 follow-up.
  - `token/ERC20/utils/SafeERC20.sol` is **v4.9.3** (older than v5.4.0 elsewhere in the same tree) and has its imports **rewritten to point at Crane natives** — `import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";` instead of the upstream `import {IERC20} from "../IERC20.sol";`. Also imports `IERC20Permit` from a Crane-canonical path that the upstream v4.9.3 OZ never imports.
  - The `interfaces/` directory's alias re-exports were a v4.4.1-era pattern OZ removed in later versions (this dedup pass already swept the zero-consumer ones in commit `7bc71bff`).
- 169 `.sol` files (about half the submodule).
- Resolves via the explicit `@crane/contracts/=contracts/` remapping.

**Why both must stay:**

1. **Crane modifications inside the vendored tree.** Files like `SafeERC20.sol` have been intentionally rewired to depend on Crane-native `IERC20` / `IERC20Permit`. Migrating consumers from vendored to submodule would silently change which `IERC20` interface they're typed against — likely fine in practice (interfaces are structural) but a real semantic change.
2. **Mixed versions inside the vendored tree.** The vendored copy is a sampled patchwork (some v4.9.3, some v5.4.0, some Crane originals). Replacing it with the clean v5.6.1 submodule for *some* files would diverge the rest, increasing the maintenance surface rather than reducing it.
3. **Distinct namespaces serve different consumers.** The 82 `@openzeppelin/contracts/...` consumers — primarily ports (Pendle, Redstone, Uniswap V4) and tests — explicitly want the upstream API surface. Vendored consumers (the small set under `protocols/tokens/wrappers/`, internal vendored re-imports) want the Crane-modified one. Collapsing the two into a single namespace would force a choice that breaks one set of consumers.

**Outstanding cleanup (lower-priority, follow-ups for future passes):**

- Fix the broken `contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol` (uncomment the interface body) so the file is usable if any consumer ever imports it directly. Zero-consumer landmine.
- The vendored `SafeERC20.sol` is v4.9.3 while the submodule has v5.5.0. If someone wants the Crane wrapper to be on a current OZ baseline, bump the vendored copy and re-apply the Crane import rewrites.
- The mixed-version vendored tree should ideally be pinned to a single OZ version (e.g. v5.4.0 or v5.6.1 to match the submodule) with Crane modifications applied as a documented patch set, not as ad-hoc edits.

**Recommendation:** the §5 "submodule vs vendored mismatch" is not actually a duplication problem — it's two intentionally-different artifacts with similar names. Close §5 (OZ row) as **"keep both, document the distinction"** and reframe future cleanup as either (a) tightening the vendored fork's discipline or (b) per-consumer migration to Crane natives.

---

## 6. What is **not** broken

To frame the scope: most of the repo's import graph is clean. None of the four agent passes found protocol code reaching across into a sibling protocol's internals. Aave does not import from Euler, Sky does not import from Aave, Reliquary is self-contained, Aerodrome's Slipstream submodule only reaches its own `aerodrome/v1/` siblings (which is correct given it's the same protocol's forks), Sky/Chainlink/Reliquary are dependency-light.

Top-level `contracts/utils/` is a deliberately-curated set of Crane-native utilities (`Strings`, `SafeCast`, `SafeCastLib`, `Create2`, `Math`, `Address`, `Context`, `ReentrancyGuard`, `SafeERC20`, `BetterAddress`, `BetterBytes`, `BetterEfficientHashLib`, `LibString`, `Base64`, `Bytecode`, `Bytes32`, `Bytes4`, `LibBytes`, `Creation`, `TransientSlot`, `UInt256`, `Nonces`, `Panic`, `ShortStrings`, plus organized `cryptography/`, `introspection/`, `math/`, `collections/`). Nothing stray. This is the intended target for `contracts/external/openzeppelin-contracts/...` consumers to migrate to where a Crane-native equivalent already exists.

---

## 7. Recommended sequence

The cleanups have natural dependencies; doing them in this order minimizes churn.

1. **Decide canonical sources.** Write a one-page convention doc that specifies, for each duplicated category, which path is the import target:
   - ERC20 interface: `contracts/interfaces/IERC20.sol`?
   - ERC20 implementation: `contracts/tokens/ERC20/ERC20.sol` vs OZ vs Solady?
   - SafeTransferLib: `contracts/utils/SafeERC20.sol` (the existing wrapper) or import Solady directly?
   - Ownable / ReentrancyGuard / EIP712 / ECDSA: Crane's `contracts/access/` and `contracts/utils/` versus vendored OZ?
   The downstream dedup work all keys off these decisions.

   **Decision (2026-05-15): prefer Crane-native; vendored only when a port truly needs the exact upstream API.** Default canonical = Crane-native paths. Vendored copies under `contracts/external/openzeppelin-contracts/`, `contracts/external/openzeppelin-upgradeable/`, and `contracts/solady/` stay as-is for ported protocols (Aave 3.6, the launchpad, Euler) that depend on their exact upstream API surface. New Crane code targets the natives.

   ### Canonical-sources table

   For every category below, the **Canonical** column is the single import target Crane code should use. The **Fallback** column applies only when a ported protocol genuinely depends on the upstream API surface and rewriting would change behavior (Step 3 will be case-by-case rather than a sweep).

   | Symbol | Canonical (Crane-native) | Fallback (vendored, when port requires it) | Notes |
   |---|---|---|---|
   | `IERC20` | `contracts/interfaces/IERC20.sol` | `contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol` | The duplicate at `contracts/tokens/ERC20/IERC20.sol` should be deprecated or made a re-export of the `interfaces/` copy. |
   | `IERC20Metadata` | `contracts/interfaces/IERC20Metadata.sol` | `contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol` | Same dedup needed for `contracts/tokens/ERC20/IERC20Metadata.sol`. |
   | `IERC20Permit` | `contracts/tokens/ERC20/IERC20Permit.sol` | `contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol` | No `contracts/interfaces/` copy. |
   | `ERC20` | `contracts/tokens/ERC20/ERC20.sol` | `contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol` | |
   | `ERC20Permit` (impl) | *(no Crane native)* | `contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol` | If Crane needs a native, add one under `contracts/tokens/ERC20/extensions/`. |
   | `SafeERC20` | `contracts/utils/SafeERC20.sol` | `contracts/external/openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol` | Crane wrapper delegates to Solady's `SafeTransferLib`. |
   | `SafeTransferLib` | `contracts/tokens/ERC20/utils/SafeTransferLib.sol` | `contracts/solady/utils/SafeTransferLib.sol` | Solmate copies under `protocols/lending/euler/v1/stubs/solmate/` and `protocols/dexes/uniswap/v4/external/solmate/` are removable in Step 3 once consumers migrate. |
   | `Ownable` | `contracts/access/Ownable.sol` | `contracts/external/openzeppelin-contracts/access/Ownable.sol` | Crane also has `contracts/access/ERC8023/` (multi-step ownable, [ERC-8023](https://eips.ethereum.org/EIPS/eip-8023)) and `contracts/access/operable/` (Diamond operable pattern) — choose whichever fits the contract's role; `Ownable.sol` is the default. |
   | `Ownable2Step` | `contracts/access/Ownable2Step.sol` | `contracts/external/openzeppelin-contracts/access/Ownable2Step.sol` | Or use `contracts/access/ERC8023/` for the Diamond multi-step pattern. |
   | `AccessControl` | *(no Crane native)* — use `contracts/access/operable/` instead, or vendored OZ if you need the OZ role-based API exactly | `contracts/external/openzeppelin-contracts/access/AccessControl.sol` | Crane's `operable` pattern is the Diamond-native equivalent. |
   | `ReentrancyGuard` | `contracts/utils/ReentrancyGuard.sol` | `contracts/external/openzeppelin-contracts/utils/ReentrancyGuard.sol` | For Diamond facets specifically, prefer `contracts/access/reentrancy/` (storage-slot-aware variant). |
   | `Math` | `contracts/utils/Math.sol` | `contracts/external/openzeppelin-contracts/utils/math/Math.sol` | `contracts/utils/math/` holds Crane-specific math (`BetterMath`, `ConstProdUtils`, AMM utils) — different scope, not a replacement for `Math.sol`. |
   | `SafeCast` | `contracts/utils/SafeCast.sol` (wraps `SafeCastLib`) | `contracts/external/openzeppelin-contracts/utils/math/SafeCast.sol` | The Solady-based `contracts/utils/SafeCastLib.sol` is the underlying impl; prefer `SafeCast.sol` as the public surface. |
   | `Address` | `contracts/utils/Address.sol` | `contracts/external/openzeppelin-contracts/utils/Address.sol` | |
   | `Strings` | `contracts/utils/Strings.sol` | `contracts/external/openzeppelin-contracts/utils/Strings.sol` | Wraps Solady `LibString`. |
   | `Context` | `contracts/utils/Context.sol` | `contracts/external/openzeppelin-contracts/utils/Context.sol` | |
   | `Create2` | `contracts/utils/Create2.sol` | `contracts/external/openzeppelin-contracts/utils/Create2.sol` | |
   | `Nonces` | `contracts/utils/Nonces.sol` | `contracts/external/openzeppelin-contracts/utils/Nonces.sol` | |
   | `Panic` | `contracts/utils/Panic.sol` | `contracts/external/openzeppelin-contracts/utils/Panic.sol` | |
   | `ECDSA` | `contracts/utils/cryptography/ECDSA.sol` | `contracts/external/openzeppelin-contracts/utils/cryptography/ECDSA.sol` | |
   | `EIP712` | `contracts/utils/cryptography/EIP712.sol` | `contracts/external/openzeppelin-contracts/utils/cryptography/EIP712.sol` | The `contracts/utils/cryptography/EIP712/` directory holds `EIP712Repo.sol` (Diamond storage helper) — companion, not replacement. |
   | `MerkleProof` | *(no Crane native)* | `contracts/external/openzeppelin-contracts/utils/cryptography/MerkleProof.sol` | Add under `contracts/utils/cryptography/` if Crane needs one. |
   | `EnumerableSet` | *(no Crane native — Crane uses different patterns)* — use `contracts/utils/collections/sets/{Address,Bytes32,Bytes4,String,UInt256}SetRepo.sol` for typed Diamond sets | `contracts/external/openzeppelin-contracts/utils/structs/EnumerableSet.sol` | Crane's `*SetRepo.sol` are Diamond-storage-aware typed sets, not a drop-in OZ replacement. Use the OZ vendored when you need the OZ API. |
   | `Initializable` | *(no Crane native; Diamond pattern uses `PostDeployHookFacet` instead — see CLAUDE.md memory)* | `contracts/external/openzeppelin-upgradeable/proxy/utils/Initializable.sol` | Only relevant for upgradeable proxy contracts; Diamond contracts don't use it. |
   | `IERC4626` | `contracts/tokens/ERC4626/IERC4626.sol` (verify exists) | `contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol` | |
   | `ERC4626` | `contracts/tokens/ERC4626/ERC4626.sol` (verify exists) | `contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol` | |
   | `Multicall` | *(no Crane native)* | `contracts/external/openzeppelin-contracts/utils/Multicall.sol` | Or use Crane's Diamond facet pattern for multicall behavior. |
   | `IERC721`, `ERC721`, `IERC1155`, `ERC1155`, `IERC165`, `ERC165` | `contracts/tokens/ERC721/`, `contracts/tokens/ERC1155/`, `contracts/utils/introspection/` (verify) | `contracts/external/openzeppelin-contracts/...` | Crane has token-stack natives for these too. |

   ### Implications for Step 3

   The "delete in-protocol vendored OZ" sweep doesn't happen as one mechanical pass. Each ported protocol's bundled OZ must be evaluated against:

   1. **Is the bundled OZ version API-compatible with the chosen canonical?** (e.g. Aave 3.6 ships OZ v5.x in `dependencies/openzeppelin-contracts/`; that *might* be API-compatible with `contracts/external/openzeppelin-contracts/` v5.x — but Aave also ships an older `dependencies/openzeppelin/` ^0.8.0 that almost certainly is not API-compatible with anything modern.)
   2. **Does the protocol use any OZ-version-specific behavior?** (Aave's WadRayMath/PercentageMath/MathUtils stay regardless — those are Aave-specific.)
   3. **Are the test harnesses (Certora, etc.) bundled with the OZ copy still used?**

   The fallback column above is what those ports keep importing if migration risks API breakage.

2. **Execute the protocol-promotion moves** (§1, decided): **completed 2026-05-15** in commits `336d3e07` (Uniswap), `1599455a` (Pendle), `f147084d` (missed import-rewrite fix-up), `602fd282` (Redstone retention doc). Outcome: `external/uniswap/` deleted (the protocols/ Crane port was already canonical); `external/pendle/contracts/` flattened to `protocols/perps/pendle/`; `external/redstone/` retained with a new `RETENTION.md`. forge build green; non-fork test suite shows zero new failures attributable to the moves. Detail of what each commit shipped:
   - **Balancer V3**: leave in place under `external/` — the Diamond refactor at `protocols/dexes/balancer/v3/` already depends on it correctly.
   - **Uniswap V3**: `git mv contracts/external/uniswap/* contracts/protocols/dexes/uniswap/v3/` (with subtree merging where filenames already coexist), then rewrite all `@crane/contracts/external/uniswap/...` imports — primarily inside `contracts/protocols/lending/euler/v1/` — to the new `@crane/contracts/protocols/dexes/uniswap/v3/...` paths. Verify with `forge build` and the standard non-fork test run.
   - **Pendle**: create `contracts/protocols/perps/pendle/`, `git mv contracts/external/pendle/* contracts/protocols/perps/pendle/`, rewrite the 4 Euler import sites and any internal cross-references inside the Pendle tree (e.g. its `Kyber/` and `BalancerStable/` SY adapters reach into Chainlink interfaces — those imports stay, only the source-tree prefix changes). Verify with `forge build`.
   - **Redstone**: no change. Add a brief README under `contracts/external/redstone/` noting the tree is retained for future reference and currently has no `protocols/` consumers.

   **Import-rewrite convention (applies to every move above and to all future edits):** every import in the moved trees and at every consumer site must use the `@crane/` remapping — e.g. `import {Foo} from "@crane/contracts/protocols/dexes/uniswap/v3/...";`. No relative imports (`../`, `./`), no bare `contracts/...`, no other prefix. After each move, grep the touched files for non-`@crane/` import lines and convert any survivors before committing.

3. **Delete in-protocol vendored OZ / Solady / Solmate trees** (§2a, §2b, §2c). Each deletion needs imports inside the affected protocol rewritten to the canonical paths chosen in step 1.

4. **Consolidate Uniswap V3↔V4 math** by extracting the V3/V4 shared math libraries into a single location (`contracts/protocols/dexes/uniswap/libraries/` or `contracts/external/uniswap-math/`). Same for `TransferHelper.sol` between Camelot V2 and Uniswap V2 (literally identical files).

   **Partial completion 2026-05-15** in commit `2ef70c75`. Five files (`BitMath`, `FixedPoint96`, `FixedPoint128`, `FullMath`, `SafeCast`) consolidated to `contracts/protocols/dexes/uniswap/libraries/`. Three deferred:
   - `TickMath` — V4 renamed `MIN_SQRT_RATIO`→`MIN_SQRT_PRICE`, `getSqrtRatioAtTick`→`getSqrtPriceAtTick`, plus added `MIN_TICK_SPACING`/`MAX_TICK_SPACING`/`maxUsableTick`/`minUsableTick`. 38 V3 + 42 V4 consumers each use their own surface.
   - `SqrtPriceMath` — V4 substantial rewrite (typed errors, currency vs token terminology, dropped `LowGasSafeMath` dep).
   - ~~`UnsafeMath` — both unused, no consolidation needed.~~ **Wrong claim — superseded by `dd1ee41f` (2026-05-16).** Both files actually had consumers. V4 is a strict superset (adds `simpleMulDiv`); consolidated to the shared `libraries/` location. Euler EulerSwap has its own UnsafeMath with `int256`/`uint8` overloads, kept separate.

   Camelot V2 ↔ Uniswap V2 `TransferHelper.sol` consolidation **completed 2026-05-15** in commit `7b3e7100`. Moved to `contracts/protocols/dexes/uniswap/v2/libraries/TransferHelper.sol`; both stub copies deleted; two consumer imports repointed (CamelotRouter, UniV2Router02).

5. **Flatten the internal OZ duplicates** (§4) — drop the OZ `interfaces/IERC20.sol` alias and the OZ `security/ReentrancyGuard.sol` legacy path.

   **Completed 2026-05-15** in commit `4e73ec37`. Both files deleted; one internal OZ relative-import consumer (`crosschain/polygon/CrossChainEnabledPolygonChild.sol`) repointed to the modern `utils/ReentrancyGuard.sol` via a `@crane/` path. **New finding flagged for follow-up:** the canonical OZ IERC20 file at `contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol` is itself entirely commented out — the interface body is dead code. Currently nothing imports it so the build passes, but the file should be either uncommented or replaced if the OZ-vendored IERC20 is ever needed. Similarly, the OZ `interfaces/` directory still has ~20 other alias files (`IERC1155.sol`, `IERC1271.sol`, `IERC1363.sol`, `IERC1820*.sol`, `IERC1967.sol`, `IERC2309.sol`, `IERC2612.sol`, `IERC2981.sol`, `IERC3156*.sol`, `IERC4626.sol`, `IERC4906.sol`, `IERC5267.sol`, etc.) following the same re-export pattern; same dedup could be applied if any of them have zero consumers. The OZ `security/` directory still has `Pausable.sol` and `PullPayment.sol`; check whether OZ v5.x moved these to `utils/` and dedup analogously.

6. **Resolve submodule vs vendored mismatches** (§5) — at minimum drop `contracts/external/forge-std/`.

   **Closed as won't-fix on 2026-05-15.** The stub at `contracts/external/forge-std/mocks/{MockERC20,MockERC721}.sol` was investigated for removal. The `lib/forge-std` submodule (commit `8b531a01`) no longer ships `src/mocks/`, and Aave's `test/foundry/spec/protocols/lending/aave/3.6/treasury/Collector.t.sol` imports `MockERC20` from the stub. The stub is the only available source for that test, so it is intentionally retained. (If forge-std re-adds mocks in a future submodule bump, revisit then.) The OZ-submodule v4.8 vs vendored v5.x part of §5 remains pending.

Each step ends with `forge build` + `forge test --no-match-path 'test/foundry/fork/*'` (the standard ~8-minute non-fork run) to catch regressions.

## 8. Rough file-count payoff

- §1 (decided): Balancer V3's 465 files stay in `external/`; Redstone's 173 stay in `external/` for future reference. Uniswap V3 (137 files) moves into `contracts/protocols/dexes/uniswap/v3/`. Pendle (430 files) moves into `contracts/protocols/perps/pendle/` (new `perps` category). Net `external/` shrinks by ~567 files; `protocols/` grows by the same amount; only Euler's V3 / Pendle interface imports need rewriting on the consumer side.
- §2a removes ~3 OZ generations × dozens of files from `lending/aave/v3.6/dependencies/openzeppelin*/` once consolidated. Aave's WadRayMath / PercentageMath / MathUtils stay (Aave-specific).
- §2b removes ~88 OZ + ~251 Solady files from `launchpads/uniswap/continuous-clearing/dependencies/`.
- §2c removes the small `lending/euler/v1/stubs/` set (~10–20 files).
- §3 cross-protocol duplicate count for the top dozen basenames drops from ~85 instances to roughly ~25.

After cleanup, `contracts/external/` would contain only OpenZeppelin (regular + upgradeable), Pyth, ds-test, layerzero, and ds-test/forge-std stubs (the latter likely removed). Every remaining ported protocol would import from one of: `contracts/interfaces/`, `contracts/utils/`, `contracts/tokens/`, `contracts/access/`, `contracts/solady/`, or `contracts/external/openzeppelin*/` — making the dependency story uniform.

---

## What remains is NOT dedup (2026-05-16)

After the session-6 correction the dedup arc is closed. The work originally labeled "outstanding" in this section was mostly mislabeled — on closer inspection it's API migration, OZ-version upgrade, or unused-code cleanup. Listed below as separate work items so they don't get confused with dedup again.

### Confirmed done — dedup shipped

| Area | Shipped commits | Net |
|---|---|---|
| Quick wins (`UnsafeMath` consolidation, Camelot `UQ112x112` delete, empty `external/pendle/` rmdir, stray `.bak` delete) | `dd1ee41f`, `3653fd67`, `8414f608` | True consolidations |
| OZ `security/` flattening (Pausable → utils/, PullPayment deletion) | `17d26d96`, `4be175dd` | `security/` dir removed |
| Aave §2a steps 1-3 retargeted to vendored OZ | `18588888` (step 1), `a6fe3562` (step 2), `c286cbee` (step 3) | Legacy `dependencies/openzeppelin/contracts/{Ownable,Context}.sol` deleted (duplicates of vendored OZ); 14 consumers now import from `external/openzeppelin/` |
| Aave step 6a SafeCast | `72fcbeb9` | 19 consumers; only byte-identical v5.1.0 ↔ v5.1.0 dedup possible |
| Step 5 OZ-internal flattening (interfaces/ thin-alias sweep) | `4e73ec37`, `7bc71bff`, `1250c9b8` | 14 + 1 + 1 zero-consumer aliases removed |

### Not dedup — separate cleanup tasks

These are reasonable repo-hygiene items, but they're not "removing duplicates":

- [ ] **3 zero-consumer OZ canonical interfaces** (`IERC1967`, `IERC2612`, `IERC6909`) live in `external/openzeppelin/interfaces/`. `7bc71bff` explicitly kept them as "real interface declarations, preserved even with zero current consumers." Whether to delete now is a separate "keep or delete unused canonical OZ" judgment call, not dedup.
- [ ] **OZ `interfaces/` consumer migration was already correct** — the report's earlier suggestion ("migrate ~17 thin aliases") was wrong. Audit shows the remaining 20 files in `external/openzeppelin/interfaces/` are canonical OZ interface declarations (each has events/functions or composes named EIP interfaces); they're not aliases that re-export to a different file. No dedup work here.

### Not dedup — Aave migration items blocked by OZ-version drift

These were originally framed as Aave steps 6 / 7, but on closer inspection they require API migrations or new Crane vendor work:

- [ ] **Aave step 6 — 126 v5.x `dependencies/openzeppelin-contracts/` consumers** (less the 19 SafeCast already done in `72fcbeb9`). **Blocker:** Crane's `external/openzeppelin/` is mostly v4.x (`Address` v4.9, `SafeERC20` v4.9.3, `Initializable` v4.9, etc.); Aave's bundled is v5.x. Migrating would either introduce silent version drift (NOT a duplicate per the session-6 lesson) or require first bumping Crane's vendored OZ to v5.x (a Crane refactor, not dedup). One true byte-identical case was SafeCast; the rest don't have dedup targets in the current Crane vendored tree.
- [ ] **Aave step 7 — 5 `dependencies/openzeppelin-contracts-upgradeable/` consumers**. Same blocker plus a design decision about whether Aave should stay on OZ upgradeable patterns at all.
- [ ] **Aave step 4 — AccessControl migration**. Reverted in `2b1a1573`. Aave bundled is v4 AccessControl with `_setupRole`; Crane vendored is v5 with `_grantRole`. Migration would require an API rename — not pure dedup. Either bump Crane vendored to v4-compatible (matching what Aave needs), or leave Aave on its bundle.

### Not dedup — API migrations that look like dedup

- [ ] **Aave step 5 — `dependencies/openzeppelin/upgradeability/` (4 files)**. Won't-fix per [Step 5 reasoning](#session-6-mistakes-and-their-correction). Aave-pinned v4-era proxy infrastructure; no equivalent in Crane vendored; migrating to v5 `ERC1967Proxy` is a deployment-pattern rewrite, not dedup.
- [ ] **Uniswap V3 ↔ V4 TickMath / SqrtPriceMath**. V4 renamed methods (`MIN_SQRT_RATIO`→`MIN_SQRT_PRICE`, `getSqrtRatioAtTick`→`getSqrtPriceAtTick`) and added new ones. 38 V3 + 42 V4 consumers each compile against their own API. Consolidating means migrating one side to the other's API — an API change, not dedup.
- [ ] **Camelot V2 ↔ UniV2 stub pairs (`Math.sol`, `SafeMath.sol`, `UniswapV2Library.sol`)**. Investigated; different scopes (24-line min/sqrt vs 586-line full math), different APIs (DappHub ds-math vs OZ v4.4), or protocol-specific (wraps ICamelotPair vs IUniswapV2Pair). Not duplicates.

### Not dedup — fork-discipline hygiene

- [ ] **Pin `contracts/external/openzeppelin-contracts/` to a single OZ baseline.** Currently mixed v4.x/v5.x (`Address` v4.9, `SafeERC20` v4.9.3, `Pausable` v4.7, `SafeCast` v5.1, `ECDSA` v5.5, `Multicall` v5.5, etc.). Picking a single baseline (e.g. v5.6.1 to match the submodule) and resetting every file would be a Crane refactor with audit-trail value. **This is the single biggest enabler** — it unblocks Aave step 6/7 because once Crane vendored is at v5.x, the consumers in Aave's bundled v5 tree have a real dedup target. But the refactor itself is fork-management work, not dedup.
- [ ] **Pendle's 44 `@openzeppelin/contracts/...` imports** auto-resolve via the submodule (v5.6.1). Could be repointed to Crane vendored for consistency once the OZ baseline above is pinned. Same as above: not dedup until the baseline is matched.

### Blocked

- [ ] **Euler Layerzero stubs (4 files, 5 consumers).** Canonical at `external/layerzero/` is broken symlinks to a submodule that's not initialized. Migration unblocked only after the Layerzero toolchain is wired up.

### Out of scope here (already settled)

- forge-std stub at `external/forge-std/mocks/` — kept; can't remove until Aave test imports change. Documented in §5 and §7 step 6.
- OZ submodule vs vendored — kept-both; the two serve different consumers and aren't really duplicates. Documented in §5.
- Balancer V3 at `external/balancer/v3/` — correctly placed as the upstream dependency for the Diamond refactor at `protocols/dexes/balancer/v3/`. Documented in §1.
- RedStone at `external/redstone/` — intentionally retained for future reference. Documented in §1 and the tree's own `RETENTION.md`.

### Lessons-learned reference for future work

**The relative-import trap** (burned 4× in earlier sessions: UnsafeMath delete, Camelot SafeMath check, Aave step 2 Address delete, OZ Pausable count). When deleting or repointing imports, grep BOTH the absolute `@crane/contracts/...` form AND the trailing-basename / relative-prefix form (e.g. `./X.sol`, `../X.sol`, `../../X.sol`). Suffix-based sed worked best for the actual rewrites, but consumer-discovery still needs both forms.

**The Crane-native ≠ OZ trap** (burned 4× in session 6: Address+Context, Ownable, AccessControl, v5-Ownable; all reverted). Before any migration, check whether the consumer uses OpenZeppelin-style semantics (Context, `_msgSender`, string reverts, v4 constructor patterns) vs Crane-native semantics (Solady-wrapping, `msg.sender`, typed errors). If OZ-style, target `external/openzeppelin/`. If Crane-native style, target `contracts/access/` or `contracts/utils/`. Never cross those boundaries — they're not duplicates regardless of how similar the surfaces look.

**The "dedup" definition** (codified above). Two files are "duplicates" eligible for collapse only if they contain the SAME code (byte-identical or structurally identical at the same OZ version) AND collapsing them doesn't change any consumer's compile semantics. Anything that requires an API change, version bump, or rewrite is a different kind of work item.
