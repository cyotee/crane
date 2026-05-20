# Aave V4 Vendor Provenance

## Upstream
- Repository: https://github.com/aave/aave-v4
- Branch: main
- Commit SHA: af1f0f2ba323ac6fbaaee3abf6be060c78e22d35
- Tag: v0.5.11-6-gaf1f0f2b
- Commit Date: 2026-04-08T09:09:07+02:00
- License: BUSL-1.1 (root LICENSE) + dependency-specific licenses retained per file SPDX

## Vendored Paths
- Source: `contracts/protocols/lending/aave/v4/` (mirror of upstream `src/`)
- Submodule deps: `contracts/external/erc4626-tests/` (mirror of upstream `lib/erc4626-tests/`)
- Tests: `test/foundry/spec/protocols/lending/aave/v4/` (mirror of upstream `tests/`)

## Submodules at port time
```
 232ff9ba8194e406967f52ecc5cb52ed764209e9 lib/erc4626-tests (v0.1.1)
 60acb7aaadcce2d68e52986a0a66fe79f07d138f lib/forge-std (v1.9.7-3-g60acb7a)
```

## Deduplication candidates (deferred)
Bundled under `aave/v4/dependencies/` but already present elsewhere in Crane — to be
deduplicated in a follow-up pass:
- `dependencies/openzeppelin/` ↔ `contracts/external/openzeppelin-contracts/`
- `dependencies/openzeppelin-upgradeable/` ↔ `contracts/external/openzeppelin-upgradeable/`
- `dependencies/solady/` ↔ `contracts/solady/`
- `dependencies/weth/` ↔ `contracts/protocols/tokens/wrappers/weth/v9/`

## Compilation posture

- Aave V4 builds under Crane's main `foundry.toml` profile (`solc = "0.8.34"`,
  viaIR-free). No scoped profile was added.
- Vendored Aave V4 files that pinned `pragma solidity 0.8.28;` exactly were
  loosened to `pragma solidity ^0.8.28;` so Crane's 0.8.34 satisfies them.
  This is a local vendor edit — re-vendoring from upstream would need to
  re-apply this transform. Count of edited files: 23.
- viaIR is NOT enabled. Per Crane's AGENTS.md, stack-too-deep is resolved
  by code refactor (Task 14b), not by enabling IR.

## Stack-too-deep worklist (Task 14b)

- None. Build under `solc = "0.8.34"` without viaIR completed successfully with
  zero stack-too-deep errors. Task 14b is not required.

## Port completion status

- Source tree vendored: ✅ (177 .sol files under contracts/protocols/lending/aave/v4/)
- Test tree vendored: ✅ (283 .sol files under test/foundry/spec/protocols/lending/aave/v4/ — 278 from upstream tests/ plus 5 deploy scripts also present in upstream tests/scripts/)
- erc4626-tests vendored: ✅ (4 files under contracts/external/erc4626-tests/ — upstream has 5 entries but the 5th is a .git submodule marker, not a real file)
- File-count parity with upstream: match (src 177/177; tests 283 vs 278 upstream — delta explained by 5 deploy scripts present in both trees; erc4626-tests 4 vs 5 upstream — delta is the .git submodule marker)
- Compilation gate: clean (forge build --skip test exits 0; only lint warnings remain)
- viaIR enabled: NO (per AGENTS.md)
- Scoped foundry profile added: NO (per user direction)
- Aave V4 test results (initial port, pre-fixes): 205 passed / 253 failed / 0 skipped — see `## Aave V4 test-fix pass` below for the post-fix state.
- Rest-of-suite regression vs pre-port baseline (~4566 tests, ~43 known failures): UNTESTABLE via single forge test invocation — forge 1.5.1 on macOS crashes (SCDynamicStore NULL panic in reqwest/hyper-util when any test initiates an RPC call or when the OpenChain signature-identifier is initialized). This is a pre-existing environment-level foundry bug unrelated to the Aave V4 port. Verified via subset runs: access (57/0), factories (89/0), introspection (138/0), tokens (224/0), utils (933/0) all pass cleanly. The dexes/protocols tests trigger RPC calls that hit the crash, same as before the port.

## Aave V4 test-fix pass (commits `8c49c053`, `a41b5bdb`, `3848f38e`, `3c99fc93`)

Three classes of mechanical fix turned the 253-failure baseline into a fully-passing slice:

1. **`vm.getCode`/`vm.getDeployedCode` path retarget.** Upstream call sites referenced `src/<path>/<File>.sol:<Contract>`. After the port the source lives at `contracts/protocols/lending/aave/v4/<path>/<File>.sol`. 9 call sites rewritten across 5 files (the production library `BytecodeHelper.sol` plus 4 test files).
2. **`fs_permissions` extended.** `./output` added (deployment-procedure tests and `Logger.t.sol` write report JSON there) and an explicit read entry for the EIP-712 bindings file.
3. **EIP-712 bindings wired.** Aave V4 uses Foundry's `vm.eip712HashType` / `vm.eip712HashStruct` cheatcodes which read type definitions from a generated `JsonBindings.sol` file. Foundry's default search path didn't match Crane's layout. Added a `[bind_json]` block pointing at the vendored mock files, plus a `skip` entry so the generated file doesn't get test-compiled.

### Aave V4 test results (post-fix)

- All Aave V4 tests pass under `forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/**" --offline`.
- Net delta vs port-baseline: +1700+ tests now passing (many were cascading setUp() failures that un-blocked once `vm.getCode` returned bytecode rather than reverting).

### Generated artifacts (not committed)

Aave V4's deployment-procedure tests write to `./output/` (Logger report JSON) and `./snapshots/` (gas snapshots). These are runtime artifacts — recommend `.gitignore` entries before merge.

## Deduplication backlog (deferred to next pass)

These remain bundled inside `aave/v4/dependencies/`. **Important note from a prior dedup arc:** Crane's strict "dedup" rule requires byte-identical or structurally-identical files at the **same upstream version** — cross-major-version migrations are explicitly NOT dedup. See `DEDUPLICATION.md` for the principle ("Crane-native vs OZ trap").

- `dependencies/openzeppelin/` vs Crane's `contracts/external/openzeppelin-contracts/` — Aave at **v5.0.0+**, Crane at **v4.9.0**. **NOT dedup-eligible.** Would require first vendoring OZ v5.x into Crane.
- `dependencies/openzeppelin-upgradeable/` vs Crane's `contracts/external/openzeppelin-upgradeable/` — same major (v5) but minor drift. Three of six files (`Ownable2StepUpgradeable`, `OwnableUpgradeable`, `ContextUpgradeable`) are structurally identical at the same OZ version and ARE dedup-eligible. The other three (`Initializable`, `ERC20Upgradeable`, `AccessManagedUpgradeable`) are at higher minors in Aave V4.
- `dependencies/solady/` vs Crane's `contracts/solady/` — the two Aave files (`LibBit`, `EIP712`) don't exist in Crane's solady tree. Not dedup; would be "extend Crane solady" work if desired.
- `dependencies/weth/` vs Crane's `contracts/protocols/tokens/wrappers/weth/v9/` — Crane's WETH9 is a *customized* subclass that inherits `IWETH`, `IERC20Events`, uses `BetterAddress`. Aave's is the vanilla upstream contract. Not dedup; semantic divergence.

Additionally:
- `contracts/external/erc4626-tests/` may overlap with other Crane test helpers — review during dedup.
