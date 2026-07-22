# Plan: Cautious, Systematic Removal of Vendored Transient Dependencies

**Date:** 2026-06-17  
**Focus:** Duplication created when porting Aave (primarily) and other protocols into `contracts/protocols/`, where full or partial copies of OpenZeppelin, Solady, and other frameworks were placed under `.../dependencies/`.  
**Guiding principle (from user direction):** Architectural hygiene / single source of truth. Preserve exact upstream Aave behavior. Expand canonical sources in `external/` first. Many small, independently reviewable steps.

## 1. Core Principles (Non-Negotiable)

1. **Expand first, migrate second, delete last.**
   - Never delete or repoint away from a vendored file until an equivalent (or better) version exists under a canonical path and relevant tests pass.

2. **Preserve exact observable behavior for Aave ports.**
   - Zero tolerance for changes in events, revert reasons, gas (where observable), constructor semantics, storage layout, or proxy deployment behavior.
   - When in doubt, keep using the vendored-OZ path in `external/openzeppelin*` rather than Crane natives.

3. **Default target for anything using classic OZ semantics = vendored OZ in `external/`.**
   - Context / `_msgSender`, upgradeable bases (`Initializable`, `ERC20Upgradeable`, etc.), `TransparentUpgradeableProxy`, `AccessManager`, `SafeERC20` from OZ, etc. → route through `@crane/contracts/external/...` or the `@openzeppelin/contracts` remapping.
   - Crane natives (`contracts/access/`, `contracts/utils/`) are **not** the target for these ports.

4. **Verification gate per change:** Relevant Aave tests under `test/foundry/spec/protocols/lending/aave/` (v3.6 and v4 subpaths) must pass. `forge build` is necessary but not sufficient.

5. **Small batches only.*
   - Prefer changes that touch one library (or a tiny coherent group) + its direct consumers.
   - One logical change per commit where practical.

6. **Always use `@crane/` import style** for new/edited imports. Convert relatives during cleanup.

7. **Aave-specific code is not duplication.**
   - Things like WadRayMath, PercentageMath, MathUtils (Aave math), `aave-upgradeability/VersionedInitializable`, BGD's `TransparentProxyFactory`, stata-token extensions, etc. stay inside the Aave tree (just not under a misleading `dependencies/` of external frameworks).

## 2. Scope

**In scope (everything, per answers):**
- Aave v3.6 `dependencies/` (~1200 files)
- Aave v4 `dependencies/` (57 curated files)
- Uniswap v4 `hooks/public/dependencies/` (19 files)
- Uniswap v4 `external/` (solmate + permit2, 13 files)
- Aerodrome `stubs/dependencies/Timers.sol`
- Any other vendored transient copies discovered during execution

**Categories to treat differently:**
- **Pure transient duplicates** (OZ, Solady pieces): promote to `external/`, repoint, delete.
- **Aave/BGD-specific** (solidity-utils transparent proxy factory, aave-upgradeability, Aave math libs): keep inside `protocols/lending/aave/...` but move out of `dependencies/` if it makes sense.
- **Test/support scaffolding** (Uniswap hook test Deployers etc.): evaluate for relocation inside test/support rather than "dependencies".
- **Intentional vendoring tightly coupled to a port** (Uniswap V4's use of solmate): document and likely leave, or move to a clearly named location.

## 3. Current State Snapshot (as of 2026-06-17)

**Major gaps that block pure repointing today:**
- `contracts/external/openzeppelin-contracts/access/manager/` only contains interfaces + `AuthorityUtils`. No `AccessManager.sol` or `AccessManaged.sol` (Aave v4 uses these directly).
- `contracts/external/solady/` is a small curated set (16 files). Missing `EIP712.sol` and `LibBit.sol` used by Aave v4.
- Some files in bundles have version/formatting drift vs current external (though a few like SafeCast in v3.6 are byte-identical).
- Aave v3.6 still has many active imports from its full bundled tree (Address, SafeERC20, TransparentUpgradeableProxy, ERC20/Upgradeable variants, ECDSA, Initializable, IERC*Permit, IERC4626, Multicall, etc.).
- Aave v4 uses a flatter, more targeted set (high volume on SafeCast/SafeERC20 + heavy AccessManager usage).

**Already partially cleaned:**
- Some helpers, deployment procedures, and tokenization base contracts in v3.6 already import successfully from `external/openzeppelin-contracts/`.
- Euler stubs largely reduced (only layerzero + hardhat/console remain).
- Launchpad dependencies tree previously deleted.

## 4. High-Level Phased Plan

### Phase 0: Foundations & Policy (Small, low risk)

1. Update / ratify the canonical sources guidance (extend the table from `DEDUPLICATION.md`).
   - Explicitly state that for Aave ports: vendored OZ in external is the target for OZ-semantic symbols.
2. Add a short `DEPENDENCIES.md` (or section) under `contracts/protocols/lending/aave/` explaining the allowed use of local deps during transition.
3. Agree on import convention:
   - Primary: `@crane/contracts/external/openzeppelin-contracts/...`
   - Convenience: the existing `@openzeppelin/contracts` remapping (already points to external).
   - Never add new imports that point into any `.../dependencies/...` tree.

4. **Prune non-runtime bloat early (Aave v3.6 only)** — independent of contract migration:
   - Delete or move out of git (via skip + eventual removal) under `aave/v3.6/dependencies/`:
     - `openzeppelin-contracts/certora/`
     - `openzeppelin-contracts/test/`
     - `openzeppelin-contracts/docs/`
     - `openzeppelin-contracts/scripts/`
     - `openzeppelin-contracts/audits/`
     - Equivalent trees under `openzeppelin-contracts-upgradeable/`
   - These are already in `foundry.toml` `skip`. Removing the files is safe for build/test and dramatically reduces the visible duplication.
   - Do this in one or two small PRs after a backup tag/branch.

### Phase 1: Expand `external/` to be a sufficient target (Prerequisite for migration)

Goal: Make it possible to delete every file from the Aave dependency trees without changing Aave behavior.

**Sub-steps (small batches):**

**1a. OpenZeppelin regular contracts**
- Add missing files needed by Aave, placed under the correct paths:
  - `access/manager/AccessManager.sol`
  - `access/manager/AccessManaged.sol`
  - Possibly `AccessManagerEnumerable` support if Aave has extensions (Aave v4 has `AccessManagerEnumerable.sol` locally — decide if it belongs in external or stays Aave-specific).
  - `proxy/transparent/TransparentUpgradeableProxy.sol` (already present, verify version match).
  - Any other files that Aave v3.6/v4 import from their bundles that are absent or wrong version in external (run a systematic diff).
- When adding, prefer the exact version/text that Aave currently compiles against where possible, or document the chosen baseline.
- Preserve Crane modifications that already exist in the vendored tree (e.g. SafeERC20 importing Crane's IERC20).

**1b. OpenZeppelin upgradeable**
- Ensure the small set used by Aave v3.6 stata tokens is present and matches:
  - `ERC20Upgradeable`, `ERC4626Upgradeable`, `AccessControlUpgradeable`, `ReentrancyGuardUpgradeable`, `Initializable`, `ContextUpgradeable`, `Ownable*Upgradeable`.
- Most are likely already there; verify and fill gaps.

**1c. Solady additions**
- Add `EIP712.sol` and `LibBit.sol` to `contracts/external/solady/` (or `utils/` subdir following existing layout).
- Decide on directory structure consistency (current external/solady is flat under `utils/` for most).

**1d. Other gaps discovered during 1a-1c**
- Any Pancake or other interface copies only if we decide they belong in external (probably not — document as out-of-scope for cross-protocol sharing).

After each sub-addition:
- `forge build`
- Run relevant Aave v3/v4 tests that would transitively benefit.

### Phase 2: Migrate consumers (many tiny steps)

**Order of attack (risk order, lowest first):**

1. **Pure stateless libraries with high confidence** (often byte-identical or trivial):
   - SafeCast, SafeERC20, Address, Math, ECDSA, Strings, Base64, etc.
   - Start with files where current bundle version == external version.

2. **Interfaces** (IERC20Permit, IERC4626, IERC20Metadata, draft-IERC6093, etc.).

3. **Common base contracts that Aave already partially uses from external** (build on the files that are already migrated in some places):
   - Ownable (some places already use external)
   - Context

4. **Proxy / Initializable related** (higher care):
   - TransparentUpgradeableProxy
   - Initializable (used in stata factory)
   - Be extremely careful with any upgrade-related deployment procedures.

5. **Upgradeable token bases** (used by stata-token):
   - ERC20Upgradeable, ERC4626Upgradeable, etc.

6. **Access control family (biggest for v4)**:
   - After 1a is complete: migrate IAccessManager, IAccessManaged, AccessManager, AccessManaged.
   - Then the role procedure files and AccessManagerEnumerable (if kept).

7. **Aave v4 Solady usages** (EIP712, LibBit, SignatureChecker).

8. **Anything using solidity-utils TransparentProxyFactory** — treat as Aave-specific. Do **not** try to move the factory itself into external. Instead, decide on a permanent home inside `aave/v3.6/deployments/` or `aave/v3.6/utils/`.

**Migration mechanics for each small batch:**
- Identify all direct importers (grep both `@crane/contracts/protocols/.../dependencies/` and any relative forms).
- Update each importer to the canonical `@crane/contracts/external/...` path (or `@openzeppelin/contracts/...`).
- Run `forge build`.
- Run the relevant test file(s) or directory for the changed consumers.
- If tests pass → commit.
- Only after all consumers of a specific file have moved → consider deleting the source from the bundle.

**Do not** bulk-sed the entire tree in one go. One library or one consumer module at a time.

### Phase 3: Delete from bundles (only after verified migration)

- Per file or small coherent groups.
- After deletion of a file:
  - `forge build --force` (clear cache)
  - Re-run the relevant Aave tests.
- Once a whole subtree is empty of needed files (e.g. most of `openzeppelin-contracts/contracts/utils/cryptography/`), delete the subtree.

Special case: After pruning non-.sol in Phase 0, the remaining `contracts/` directories inside the bundles will be much smaller and easier to reason about.

### Phase 4: Restructure / Document what remains

- Move any surviving Aave-specific "dependencies" (solidity-utils pieces that are really BGD infra, custom upgradeability) into better locations:
  - Example: `aave/v3.6/utils/transparent-proxy/` or `aave/v3.6/deployments/factories/`.
- Add `README.md` files in any remaining `dependencies/` dirs explaining why they exist (hopefully none for generic frameworks).
- Update `foundry.toml` skip lists and any path-based ignores.
- Add a repo-level guard (script or lint) that fails if new code under `protocols/` imports from a path containing `/dependencies/openzeppelin` or `/dependencies/solady`.

### Phase 5: Minor / Other Cases

- Uniswap v4 hooks `dependencies/`: After evaluating usage (currently only internal to two hook files), either:
  - Leave as-is (test support), or
  - Move contents under `.../hooks/public/test-support/` or similar.
- Aerodrome Timers.sol: Migrate the single consumer (GovernorSimple) to the version in external (or document why the deprecated v4.4.1 version is required), then delete.
- Uniswap v4 `external/solmate + permit2`: Document decision. Likely leave or promote the permit2 pieces if they are generic enough (low priority).

## 5. Detailed First 10 Steps (Actionable Starting Sequence)

1. Create this plan file + update `DEDUPLICATION.md` status with link to plan.
2. Prune non-.sol bloat from Aave v3.6/dependencies/ (certora, test, docs, scripts, audits inside the OZ trees). One commit. Verify build + a few Aave tests.
3. Inventory exact diff: produce a machine-readable list of every `.sol` that is imported from any `aave/.../dependencies/` by non-dependency code.
4. Compare each of those files against the equivalent path in `external/`. Classify: identical / minor diff / major version or API diff / missing entirely.
5. Add full `AccessManager.sol` + `AccessManaged.sol` (and any direct imports they need) to `external/openzeppelin-contracts/access/manager/`. Verify they compile in isolation and match Aave v4's expectations as closely as possible.
6. Add `EIP712.sol` and `LibBit.sol` to `external/solady/` (choose consistent layout).
7. First migration batch: all current consumers of `SafeCast.sol` from the bundles → external. (Some v3.6 may already be identical.)
8. Next: `Address.sol`, `SafeERC20.sol`, `Math.sol` (the generic one), `ECDSA.sol`.
9. Migrate `TransparentUpgradeableProxy` consumers (TreasuryProcedure, etc.).
10. After AccessManager is in external: migrate the role procedures and direct AccessManager usages in v4.

Each of 7-10 is its own small reviewable unit.

## 6. Tooling & Mechanics Recommendations

- **Discovery**: Use suffix greps + basename greps. Example:
  ```
  grep -r "dependencies/openzeppelin" --include="*.sol"
  grep -r "/SafeCast.sol" --include="*.sol"
  ```
  Relative imports (`../`, `./`) have burned previous work.
- **Rewrites**: Suffix-based `sed` on import paths works well once you have the exact old path fragment.
- **Cache**: After structural deletes, `rm -rf cache_forge out` before rebuild.
- **Branching**: Use git worktrees for long-running test verification on one side while editing on another.
- **Commit message convention**:
  `refactor(deps): migrate Aave v4 SafeCast consumers to external/openzeppelin`
  `chore(deps): prune certora/ and test/ from aave/v3.6 openzeppelin bundles`

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Version drift causes different revert strings or gas | Expand external with Aave-pinned exact content where possible; test after every change. |
| Missing transitive file inside a promoted module | When adding a file to external, also add its direct imports if they don't exist yet. |
| Internal references inside the bundle tree | Only delete a file after confirming no remaining importers inside the surviving bundle either. |
| Deployment procedure code has weaker test coverage | Run the specific deployment test files + any that exercise the procedure. |
| Upgradeable proxy initialization order or storage | Treat proxy-related migrations with extra test scrutiny. Consider keeping Aave's custom VersionedInitializable as-is. |
| Solady file layout differences | Document the final layout in external/solady/README. |

## 8. Success Criteria

- No imports under `contracts/protocols/` (or anywhere that isn't the external tree itself) point into any `.../dependencies/openzeppelin*` or `.../dependencies/solady` for generic framework code.
- `external/openzeppelin-contracts/access/manager/` contains a usable `AccessManager.sol` + `AccessManaged.sol`.
- `external/solady/` supplies EIP712 + LibBit.
- All Aave v3.6 and v4 "relevant tests" continue to pass.
- The on-disk size of `contracts/protocols/lending/aave/v3.6/dependencies/` has been dramatically reduced (non-.sol gone + migrated contracts removed).
- Clear documentation exists so future porters do not repeat the pattern.

## 9. Open / Follow-up Items (to resolve during execution)

- Exact baseline version(s) to pin external to for the AccessManager family.
- Whether Aave v4's `AccessManagerEnumerable` should live in external or stay local to Aave.
- Final home for BGD TransparentProxyFactory and related (keep in Aave tree under a non-`dependencies` path).
- Whether any of the Uniswap hook dependency files (Pancake interfaces, protocol-fees) should be promoted anywhere or just reorganized locally.
- How aggressively to update the vendored external trees to newer OZ patch releases after this work (separate maintenance question).

---

**This plan is designed to be executed incrementally.** Start with Phase 0 (policy + early bloat prune), move to Phase 1 expansion, then proceed with small migration batches in Phase 2. Revisit this document after each phase and update status.

Next action recommendation: Begin with the non-.sol prune + the AccessManager + Solady expansion work, as those are the highest blocking prerequisites.