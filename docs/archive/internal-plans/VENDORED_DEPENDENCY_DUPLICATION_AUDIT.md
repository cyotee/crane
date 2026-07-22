# Vendored Dependency Duplication Audit

**Date:** 2026-06-17  
**Scope:** `contracts/external/` vs `contracts/protocols/**` vendored transient dependencies  
**Context:** Post-port of upstream frameworks into `external/` to support protocol ports.

## Executive Summary

An earlier porting effort placed canonical copies of upstream libraries and frameworks under `contracts/external/` (OpenZeppelin, OpenZeppelin Upgradeable, Solady, Uniswap, Balancer, etc.). However, the ported protocol code under `contracts/protocols/` (primarily Aave) was imported with its own full vendored copies of its transitive dependencies.

This created large-scale duplication:

| Location | Files | Nature | Status |
|----------|-------|--------|--------|
| `protocols/lending/aave/v3.6/dependencies/` | **~1203** | Full copies of OZ contracts + upgradeable + solidity-utils + tests/docs | Active duplication |
| `protocols/lending/aave/v4/dependencies/` | **57** | Curated snapshot (OZ + 2 Solady files) | Active duplication |
| `protocols/dexes/uniswap/v4/hooks/public/dependencies/` | 19 | Test helpers + Pancake copies + protocol-fees interfaces | Localized support |
| `protocols/dexes/uniswap/v4/external/` | 13 | solmate + permit2 interfaces (intentional V4 vendoring) | Different category |
| `protocols/dexes/aerodrome/v1/stubs/dependencies/` | 1 | Single deprecated OZ Timers.sol (v4.4.1) | Minor |

**Primary offender:** Aave v3.6 carries a near-complete copy of the OpenZeppelin monorepos inside the protocol tree.

The duplication is **not purely byte-identical**. Some files match the current `external/`, others are version-drifted or reformatted. Imports inside Aave are a mix of:
- Still pointing at the local `.../dependencies/...` bundles (majority of Aave consumers)
- Already corrected to `@crane/contracts/external/...` (some deployment procedures and config)

Euler stubs were substantially cleaned previously (only layerzero + hardhat/console remain). The Uniswap continuous-clearing launchpad `dependencies/` tree was previously deleted.

## Background

Per the architecture documented in `DEDUPLICATION.md` and `AGENTS.md`:

- `contracts/external/<source>/` — shared vendored upstreams (the single source of truth for a given snapshot of an external library).
- `contracts/protocols/<category>/<protocol>/` — protocol-specific logic that should **import** from `external/` (or Crane natives), not re-vendor.

The porting agent violated this by copying the full `dependencies/` trees that came with the Aave (and to a lesser extent other) upstream ports, and leaving the import statements pointing inside those trees.

Foundry remappings already define:
```
"@openzeppelin/contracts/=contracts/external/openzeppelin-contracts/"
```
But Aave code largely bypasses this by using long explicit `@crane/contracts/protocols/.../dependencies/...` paths.

## Detailed Inventory

### 1. Aave v3.6 — `contracts/protocols/lending/aave/v3.6/dependencies/`

This is the dominant problem (1203 files, 243 directories).

**Contents:**
- `openzeppelin-contracts/` — full checkout (~268 contracts + tests, certora harnesses, scripts, docs, audits)
- `openzeppelin-contracts-upgradeable/` — full checkout (~195 contracts + tests/harnesses)
- `openzeppelin/` — small legacy tree (2 contracts + upgradeability proxies)
- `solidity-utils/` — Aave's internal utils (access-control, create3, oz-common, transparent-proxy)

**Actual usage by real Aave code (not the deps tree itself):**
Top imported basenames from the bundle (protocol + deployments + extensions):
- `Math.sol` (17), `Address.sol` (17), `SafeCast.sol` (14), `ECDSA.sol` (12), `SafeERC20.sol` (9), `Strings.sol` (8), `IGovernor.sol` (8), `Checkpoints.sol` (7), `Arrays.sol` (6), etc.

Some Aave files already import correctly:
```solidity
import {Ownable} from '@crane/contracts/external/openzeppelin-contracts/access/Ownable.sol';
```
Others still use the bundle:
```solidity
import {Multicall} from '@crane/contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/utils/Multicall.sol';
import {ECDSA} from '@crane/contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
```

**Identity analysis:**
- `SafeCast.sol` in v3.6 deps is **byte-identical** (sha256 matches `external/openzeppelin-contracts/utils/math/SafeCast.sol`).
- `ECDSA.sol` differs (header says v5.1.0 in bundle vs v5.5.0 in external; added notes about 2098 short signatures).

The `openzeppelin-contracts-upgradeable/` tree is largely unused by core protocol logic but is used by stata-token extensions and the Collector.

### 2. Aave v4 — `contracts/protocols/lending/aave/v4/dependencies/`

Much smaller and more deliberate (57 `.sol` files).

**Structure (flat files, not full tree):**
- `openzeppelin/` — 49 specific files (AccessManager, SafeCast, SafeERC20, TransparentUpgradeableProxy, EnumerableSet, Math, etc.)
- `openzeppelin-upgradeable/` — 6 files (Initializable, ERC20Upgradeable, Ownable*, AccessManagedUpgradeable, Context)
- `solady/` — 2 files (EIP712.sol, LibBit.sol)

**Usage (real Aave v4 code):**
- SafeCast (11), SafeERC20 (10), IAccessManager (7), Math (4), IERC20Permit (3), EnumerableSet (3), Address (3), ...
- Also imports for TransparentUpgradeableProxy, ReentrancyGuardTransient, IERC4626, etc.

**Identity:**
- Many files differ in formatting/whitespace from current external (e.g., SafeCast indentation).
- `EIP712.sol` + `LibBit.sol` from Solady are **not present** in the current curated `external/solady/` (which is a small allow-list of 16 files).

Aave v4 appears to have been ported with a "take only what you need" snapshot rather than the full tree that v3.6 brought.

### 3. Uniswap v4 hooks/public/dependencies (19 files)

Located at:
`contracts/protocols/dexes/uniswap/v4/hooks/public/dependencies/`

**Contents:**
- `v4-core/test/*` (Deployers, PoolSwapTest, PoolModifyLiquidityTest, CurrencySettler, PoolTestBase)
- `v4-periphery/test/shared/Deploy.sol`
- `pancakeswap/v3-core/interfaces/*` (full interface set for Pancake V3)
- `protocol-fees/{interfaces, libraries}/*`

**Consumers:** Only 2 files inside the same `hooks/public/aggregator-hooks/` subtree:
- `BaseAggregatorHook.sol`
- `ProtocolFees.sol`

This is **not** a broad transient dependency duplication. It is localized test/support scaffolding + alternative interface copies for Pancake compatibility. Low priority.

### 4. Uniswap v4 `external/` subtree (13 files)

`contracts/protocols/dexes/uniswap/v4/external/`

- `solmate/` (auth/Owned, tokens/ERC20+ERC721+WETH, utils/CREATE3+FixedPointMathLib+SafeTransferLib)
- `permit2/interfaces/IERC1271.sol` + `permit2/libraries/SignatureVerification.sol`

This is **intentional vendoring** that came with the upstream Uniswap V4 port. Uniswap V4 was designed against solmate and its own permit2 subset. These are not the same as the broader Crane `external/` copies and are tightly coupled to the V4 implementation. Per prior decisions, the main Uniswap code lives under `protocols/dexes/uniswap/`.

Not the same class of problem as the Aave full-OZ bundles.

### 5. Aerodrome `stubs/dependencies/Timers.sol`

Single file, OZ v4.4.1 `Timers` library (explicitly marked deprecated in the source header). External has a `Timers.sol` under openzeppelin-contracts (different version).

Only one consumer (`GovernorSimple.sol`). Minor.

### 6. Euler stubs (mostly resolved)

Current state:
```
contracts/protocols/lending/euler/v1/stubs/
  layerzero/...
  hardhat/console.sol
```
(5 files total)

Layerzero stubs are intentionally retained (the `external/layerzero/` location contains only broken symlinks; submodule not initialized). Hardhat console is a deliberate no-op shim. Documented in `DEDUPLICATION.md`.

No broad duplication here now.

## Version & Equivalence Summary

| Category | Aave v3.6 bundle | Aave v4 bundle | Crane external | Notes |
|----------|------------------|----------------|----------------|-------|
| OpenZeppelin (regular) | v5.1.x mixed + full tree | Curated v5.x-ish snapshot | Mixed (some v4.9, some v5.5) | Not pristine in external either |
| OZ Upgradeable | Full v5.0 tree | 6 curated files | Full v5.0 tree | v4 uses subset |
| Solady | None in v3.6 deps | EIP712 + LibBit (flat) | Curated 16 files, no EIP712/LibBit | Gap in external |
| SafeCast (example) | Byte-identical to external | Different (formatting) | Current | v3.6 could dedup immediately |
| ECDSA | v5.1.0 | — | v5.5.0 | Drift |

External itself is **not a clean single-version snapshot** (see `DEDUPLICATION.md` §5). This makes mechanical "replace everything with external" risky.

## Architectural Problems

1. **Import paths encode the mistake.** Hundreds of imports hard-code the per-protocol dependency location instead of using the framework's canonical locations or the `@openzeppelin/contracts` remapping.

2. **Test/Certora baggage shipped with runtime.** The v3.6 `dependencies/openzeppelin-contracts/` includes full test suites, certora specs/harnesses, and audit PDFs. These bloat the repo and are only needed if you intend to re-run Aave's upstream verification.

3. **Inconsistent cleanup state.** Some files were already migrated to external during prior dedup passes; others were left behind. This creates a split-brain where two "sources of truth" for the same symbol coexist inside the build.

4. **Solady gap.** Aave v4 needs two Solady files that Crane has not yet promoted into `external/solady/`. This forces either (a) expanding the curated Solady in external, or (b) accepting the small local copy.

## Risks of Blind Consolidation

- **API drift / version mismatch.** Not every file in the bundles is interchangeable with current external. Constructor patterns, error messages, `_msgSender()` vs `msg.sender`, and OZ v4 vs v5 differences have burned previous sessions (see DEDUPLICATION.md "Session-6 mistakes").
- **Upgradeable vs Diamond patterns.** Aave makes heavy use of OZ Initializable / UUPS / Transparent proxies. Crane's canonical pattern is Diamond + PostDeployHook. Migrating Aave's deployment infrastructure is a design change, not dedup.
- **Certora / test harnesses.** Some harnesses may have been intentionally modified by the Aave port.
- **Transitive internal imports.** Deleting a file from a bundle can break other files inside the same bundle that are still used.

## Recommended Remediation Plan

### Phase 0 — Policy (do first)

Reaffirm / extend the canonical sources table from `DEDUPLICATION.md` §7 step 1 specifically for the symbols Aave actually uses (SafeCast, SafeERC20, Address, ECDSA, Math, EnumerableSet, TransparentUpgradeableProxy, Initializable, AccessManager family, etc.).

Decide the Solady gap: promote EIP712 + LibBit into `external/solady/` or document that Aave v4 keeps its two-file snapshot.

### Phase 1 — Aave v3.6 (highest leverage)

1. Inventory exactly which files under `dependencies/openzeppelin*` have **any** consumers outside the `dependencies/` trees themselves (already partially done above).
2. For byte-identical files (e.g. SafeCast today), switch the consumers to `@crane/contracts/external/...` (or `@openzeppelin/contracts` remapping) and delete the local copy.
3. For drifted files, either:
   a. Align external to the Aave-pinned version (add as a documented patch), or
   b. Update Aave consumers to tolerate the external version (per-consumer edits + tests).
4. After consumers are migrated, delete the unused portions of the trees. Consider keeping a **thin** `dependencies/` only for Aave-specific math (WadRayMath, PercentageMath, MathUtils) and the aave-upgradeability proxy adapters if they are truly frozen artifacts.
5. Delete or `.gitignore` the certora/ + test/ + docs/ + scripts/ subtrees inside the bundles (they are already skipped via `foundry.toml` `skip`, but the files still occupy disk and git history).

### Phase 2 — Aave v4 (curated, higher risk)

Aave v4's snapshot is smaller and more recent. Treat it more like a "pinned compatible set" than a mistaken full copy.

Options:
- Expand `external/openzeppelin*` + `external/solady` until the exact set Aave v4 needs is available under canonical paths, then repoint.
- Or accept the curated `dependencies/` for v4 as a deliberate "compatibility lock" and document it (similar to how Balancer v3 stays in external as the upstream-pinned source).

Do **not** delete first.

### Phase 3 — Minor / Self-contained

- Uniswap v4 hooks `dependencies/`: Leave or move the 19 files under a `test/` or `support/` sibling if desired. Not a cross-protocol duplication.
- Aerodrome Timers: Migrate the one consumer or delete the deprecated file. Low value.
- Uniswap v4 `external/solmate + permit2`: Leave as part of the V4 port. Not the same problem.

### Phase 4 — Hygiene

- Add a CI or pre-commit check that fails if anything under `contracts/protocols/**` imports from a path containing `/dependencies/openzeppelin` or `/dependencies/solady` (except for explicitly allowed per-protocol compatibility dirs).
- Consider a `contracts/protocols/*/dependencies/README.md` convention that any surviving per-protocol dependencies tree must justify its existence.
- Periodically re-vendor `external/` from clean upstreams and document the exact commit.

## Quick Wins That Are Low Risk

- Switch all current byte-identical Aave v3.6 consumers of `SafeCast.sol` to the external path and delete the local one (one file, many consumers).
- Do the same for any other file where `sha256sum` matches between the bundle and external (run a systematic pass).
- Delete zero-consumer files inside the v3.6 bundles (the certora/ trees are already skipped, but entire subdirs of unused mocks, etc. can go).

## Files of Interest for Follow-up

- `contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/utils/math/SafeCast.sol` (byte match)
- `contracts/protocols/lending/aave/v3.6/protocol/pool/Pool.sol` (imports Multicall from bundle)
- `contracts/protocols/lending/aave/v3.6/treasury/Collector.sol` (mix of bundle + upgradeable imports)
- All files under `aave/v4/dependencies/` that Aave v4 core actually `import`s.
- `contracts/external/solady/` — consider adding EIP712 + LibBit if policy allows.

## Appendix: Counts (2026-06-17)

- Aave v3.6 `dependencies/`: 1203 files
- Aave v4 `dependencies/`: 57 files
- Uniswap v4 hooks `dependencies/`: 19 files
- Aerodrome stubs `dependencies/`: 1 file
- External openzeppelin-contracts (`.sol`): ~175
- External openzeppelin-upgradeable (`.sol`): ~160
- External solady (`.sol`): 16

---

**This report is intended for review and refinement.** Suggested next actions: decide policy on version pinning for external/, identify exact byte-identical candidates for immediate collapse, and scope the Aave v4 compatibility question before large-scale rewrites.