# Gap Report for: contracts/test/IHandler.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (applies to **all** test files incl. handlers per explicit scope).
- LR-7: Testing Standards (NatSpec on test code / handlers per point 10; IHandler used by handlers for selector registration in invariant fuzzing with expectEmit/exact asserts).

**Current State Summary:**
Strict mandatory process followed EXACTLY in order before any edit. LR-1 gap closed with rich NatSpec + exact tags. (No Repos here, no LR-6 applies.) File is the canonical definition for IHandler (re-exported via contracts/interfaces/IHandler.sol for consumer imports).

**Detailed Gaps (now closed):**
- LR-1: missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard + AGENTS.md for handlers).

**Actions Taken to Close (targeted):**
1. Wrapped interface + method with exact // tag::IHandler[] / // end::IHandler[] and // tag::selectors()[] / // end::selectors()[] (no extra spaces).
2. Added rich @title/@author/@notice/@dev/@return + @custom:interfaceid / @custom:signature / @custom:selector . Values targeted-computed via `cast sig "selectors()"` (0x6e25b978) + interfaceId derivation (single-func interface => same value). Referenced CENTRALLY_COMPUTED prose style + cast usage in AGENTS/PRD.
3. N/A for slots (no Repo/Storage).
- Used only reads of assigned gap + central (prose) + PRD (LR-1 test scope + LR-7 handler notes) + AGENTS (test/handlers NatSpec req) + golds (Behavior_* + TestBase_* + IMultiStepOwnable handler usage of IHandler + selectors impl) + source parse.

**Symbols documented (full parse of source):**
- interface IHandler (with @custom:interfaceid 0x6e25b978)
- function selectors() external view returns (bytes4[] memory selectors_)

**LR-7 notes addressed:**
- This surface enables handlers (e.g. MultiStepOwnableHandler is IHandler) that support exact registration + vm.expectEmit / expectRevert inside handler actions (see usage in TestBase_IMultiStepOwnable).
- NatSpec added per "NatSpec on test code" + "handlers" requirement.

**Process recap (strict order, logged):**
1. read_file docs/reports/gap/contracts/test/IHandler.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; prose)
3. read_file PRD.md (LR-1 on test files + LR-7 handlers)
4. read_file AGENTS.md (test/handlers NatSpec + IHandler gold if any, tags)
5. Read golds: Behavior_IFacet.sol, Behavior_IERC165.sol, TestBase_IFacet.sol, IMultiStepOwnable.sol (gold interface), TestBase_IMultiStepOwnable.sol (IHandler impl+usage + tags), TestBase_ERC20.sol, Handler_ERC165.sol, CamelotV2Handler.sol, docs/development/testing.md, contracts/test/IHandler.sol cross-refs + ERC8023 handler pattern.
6. read_file contracts/test/IHandler.sol (parsed: interface + selectors() only)
- Additional targeted: cast sig, list_dir/grep for usages, re-reads of 3 files before each edit.

**Documentation/Skills Gaps (if applicable):**
- Already referenced in docs/development/testing.md and AGENTS.md (now has NatSpec to support).

**Notes for Subagents:**
- ONLY 3 relative files edited: contracts/test/IHandler.sol + docs/reports/gap/contracts/test/IHandler.sol.md + GAP_REPORT.md
- Updated per-file + main GAP [x].
- Targeted inspect + build specific performed.
- No other files touched.

**Pre-edit tags:** 0
**Post-edit tags:** 2 (IHandler + selectors())
**LR-1 + LR-7 notes: CLOSED**

**Priority:** High (core framework files) - CLOSED

**Verification (targeted, post-edit):**
- `forge build contracts/test/IHandler.sol --skip test --quiet` (and full narrow)
- `forge inspect contracts/test/IHandler.sol:IHandler (abi|methodIdentifiers)`
- `forge test --list --match-path '*MultiStepOwnable*|*IHandler*' --quiet` (ensures consuming handler still lists)
- Matches: selector 0x6e25b978 in abi.
