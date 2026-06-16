# Resumption Prompt for Crane LR Gap Closure Work

**Date:** 2026-07-03  
**Status:** Paused after successful completion of a wave of LR-1 closures. Legacy items and recent batches are stable.

## Goal
Continue closing Launch Readiness (LR) gaps per PRD.md and GAP_REPORT.md:
- **LR-1**: Rich NatSpec + exact `// tag::Symbol(params)[]` / `// end::` (hyphenated overloads) + `@custom:*` values **only from** `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (or verified `cast` in targeted verif). Applies to code, tests, Behaviors, TestBases, etc.
- **LR-6**: All Repos must use exact ERC1967 form `bytes32 internal constant XXX_STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("hier.name"))) - 1);` + dual `_layoutStruct(bytes32)` / `_layoutStruct()` + update all internal calls.
- **LR-7**: Tests must use full non-0 init (via CraneTest + InitDevService), exact `assertEq`/`assertTrue` (no side-effect-only or "changed" checks), mandatory `Behavior_*` + declaration tests, proper handlers.

**Strict process (AGENTS.md + history):**
1. Read (in order, before any edit):
   - The specific per-file gap report (`docs/reports/gap/.../TheFile.sol.md`)
   - `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (use **only** values present)
   - `PRD.md` (relevant LR sections)
   - `AGENTS.md` (full relevant sections: NatSpec, Repo pattern, tags, "ONLY 3 files", relative paths, targeted verif only)
   - Golds (recently closed similar files + classic ones like OperableRepo, IMultiStepOwnable, Behavior_IFacet, TestBase_IFacet, etc.)
   - The target source file (re-read immediately before editing)
2. Edit **only** the .sol + its per-file gap .md + `GAP_REPORT.md` (max ~3-5 files total per scoped task). Use relative paths.
3. After edits: **only** targeted verification (`forge inspect <path>:Contract (abi|methodIdentifiers|storageLayout)`, `forge build <path> --skip test --quiet`, narrow `forge test --list --match-path '*Name*'`).
4. Update the per-file gap with full recap (reads performed, symbols, pre/post counts, centrals used, verif outputs) + mark **LR-X CLOSED**.
5. Add concise `[x]` entry to `GAP_REPORT.md` modeled on recent closures.
6. Never enable `viaIR`. Use structs for stack-too-deep. Preserve 100% logic.

**GAP_REPORT.md is the full archive.** Do **not** re-read the entire completed history. Focus only on the open items below + the per-file gap for the item you pick.

## Recently Completed (do not redo)
- IDiamondLoupe / IDiamondCut interfaces + CallTargetRegistry Query/Management Behaviors: LR-1 CLOSED (full tags, strict process).
- BalancerV3PoolRepo + Weighted/Stable variants: LR-6 + LR-1 CLOSED (correct slots + 14-16 tags each).
- TokenTransferRelayerRepo: LR-6 + LR-1 CLOSED.
- Many prior waves (ERC721*Repos/Facets/Behavior/TestBase, Operable, Reentrancy, ERC165, Create3, EIP712, sets, various AwareRepos, DFPkgs, etc.).
- Legacy items (BalancerV3VaultAwareRepo, Camelot Aware Repos, ERC721 repos, etc.) remain stable (reminder bgs pass with correct tags/slots and no regression).

## Incomplete Entries from GAP_REPORT.md (high-level open items)
**GAP_REPORT.md is the archive.** Do not re-read the entire completed history or all [x] closures. Use only this list + the tail of GAP_REPORT.md + the specific per-file `docs/reports/gap/...` for the item you select.

All remaining incomplete entries (verbatim from open `- [ ]` checkboxes in GAP_REPORT.md as of pause):

**NatSpec / LR-1 broad + LR-6 remaining**
- [ ] Add full NatSpec + tags to all core framework (factories, introspection, tokens, registries)
- [ ] Add full NatSpec + tags to protocol ports and utilities (progress: CamelotV2Service + AerodromeService + AerodromeServiceVolatile + AerodromeServiceStable closed as exemplars for protocol *Service utilities per LR-1; similar needed for other AwareRepos/Services, Aerodrome specialized variants etc)
- [ ] Audit and update all Repos to use `bytes32(uint256(keccak256(...)) - 1)` pattern
- [ ] Update all `_layoutStruct()` calls and references
- [ ] Add migration notes / upgrade safety handling
- [ ] (Deferred) Spike and finalize BANKR_LAUNCH.md after refactoring

**LR-7 test quality (verbatim open list)**
- [ ] Enforce full initialization (no address(0) for facets in DFPkg tests; realistic state)
- [ ] Replace weak "changed" assertions with exact expected values
- [ ] Add exhaustive preview parity tests for vaults
- [ ] Add tests for deployed Facets declaring expected interfaces/functions
- [ ] Migrate tests to use appropriate Behavior_* libraries (IFacet, IDiamondFactoryPackage, protocols)
- [ ] Add full DFPkg lifecycle tests
- [ ] Add registry population assertions
- [ ] Add CREATE3/salt determinism tests
- [ ] Add storage isolation tests
- [ ] Add reentrancy/access-control matrix tests
- [ ] Add fork parity tests for ports
- [ ] Ensure proper TestBase/CraneTest usage everywhere

**Other open**
- Continue per-file gap + LR-1/LR-6/LR-7 work for any remaining 0-5 tag core files (bounties/*, create3 factories, remaining introspection/interfaces/registries/tokens, handlers, test files).
- Any LR-3 (skills) drift discovered during new work.
- Specific sub-task reminders from prior (e.g. erc20/721/2612 repos LR-6 if not fully closed in last wave; DevEnv LR-7 full coverage; next low-tag interfaces/facets after IDiamond*).

Focus only on the above. Pick ONE small scoped item (single file or 2-3 tightly related) per wave.

## Still-Low-Tag Files (core / non-constants, priority candidates for LR-1)
(From low-tag scan at pause; re-scan if needed before starting new batch. Prefer 0-tag core over already-high ones.)

Bounty modules (many 0-tag):
- contracts/bounties/common/BountyCommonFacet.sol (0)
- contracts/bounties/common/BountyCommonTarget.sol (0)
- contracts/bounties/common/IBountyCommon.sol (0)
- contracts/bounties/contest/ContestBountyFacet.sol (0)
- contracts/bounties/continuous/ContinuousBountyFacet.sol (0)
- contracts/bounties/milestone/IMilestoneBounty.sol (0)
- contracts/bounties/milestone/MilestoneBountyFacet.sol (0)
- contracts/bounties/single/ISingleFinalBounty.sol (0)
- contracts/bounties/single/SingleFinalBountyFacet.sol (0)
- contracts/bounties/single/SingleFinalBountyTarget.sol (0)

Create3 factory surface (0-tag noted):
- contracts/factories/create3/Create3FactoryAwareFacet.sol (0)
- contracts/factories/create3/Create3FactoryBootstrapTarget.sol (0)
- contracts/factories/create3/Create3FactoryService.sol (0)
- contracts/factories/create3/Create3FactoryTarget.sol (0)

Partial / recent targets to verify or finish:
- InitDevService.sol (~4 tags)
- Remaining core interfaces/facets/targets/repos in introspection, factories, tokens, registries (use `scripts/populate_gap_reports.sh` or manual grep for tag counts if needed).
- Any 0-2 tag files in protocols that are not the closed exemplars.

Skip pure constants unless they contain documented logic. 

**How to pick:** Start with a 0-tag bounty trio (Facet/Target/Interface) or a single remaining core interface. Or pick one LR-7 item and a specific test file (e.g., one DFPkg test or protocol test lacking Behavior).

## How to Resume
1. Read this file + the **end** of `GAP_REPORT.md` (open items section) + `AGENTS.md` (process rules) + `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md`.
2. Pick one small scoped item from the incomplete list or low-tag scan.
3. Follow the strict read-order + 3-files-only rule exactly.
4. After the sub/task, run a reminder-style check (legacy + current targets + GAP counts) to confirm no drift.
5. Update only the necessary per-file gap + GAP_REPORT.md.
6. When a sub finishes, get its full output and incorporate the closure into GAP_REPORT.md if the sub didn't already.

**Do not re-read the entire completed history in GAP_REPORT.md** — it is the archive. Use the open list above + per-file gaps for the files you touch.

## Recent Completed Waves (for reference, already in GAP)
- IDiamondLoupe + IDiamondCut interfaces + CallTarget Query/Management Behaviors (LR-1).
- BalancerV3PoolRepo + Weighted + Stable variants (LR-6 + LR-1).
- TokenTransferRelayerRepo (LR-6 + LR-1).
- Many earlier waves (ERC721 full suite, Operable/Reentrancy, ERC165, Create3, EIP712, sets, DFPkgs, services, etc.).
- Significant LR-7 test improvements on multiple spec tests (full init, exact asserts, Behaviors, declaration tests, central values, NatSpec on tests).

Legacy reminder checks (BalancerV3VaultAware, Camelot Aware, ERC721/l2s repos, etc.) continue to pass with correct tags/slots and stable GAP markers.

## When Done with a Wave
- Run a full reminder-style legacy + current-targets check.
- Clean duplicate/long verification bgs.
- Consider a broader low-tag scan for the next scoped batch.
- Update this resumption prompt or create a new one if pausing again.

Good luck — the process is working. Pick small, follow the rules strictly, and keep legacy stable.
