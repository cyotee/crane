# Gap Report for: contracts/tokens/ERC721/Behavior_IERC721.sol

**Status: LR-1 + LR-7 CLOSED**

**File Type:** Library (Behavior)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full rich + exact // tag::Name(params)[] / end:: + @custom ONLY from CENTRALLY)
- LR-7: Behavior declaration/behavior tests (expect_*/isValid_*/hasValid_* mandatory; use Behavior for surface; exact asserts)

**Strict Process Followed (no skips, read in EXACT order BEFORE ANY edit):**
1. Read per-file gap 1st
2. CENTRALLY (no IERC721 entries)
3. PRD LR-1/LR-7
4. AGENTS.md (tags/hyphen/Behavior/ERC721 golds/ONLY files/targeted)
5. Golds (ERC721 repos closed + gaps, ERC721Facet, Behavior_IERC165/IFacet + gaps, TestBase_IERC165/IFacet/ERC20 + gaps)
6. Re-read sources + pre grep count (0 tags)

**Pre-edit:** minimal isValid only, 0 tags.

**ONLY edited (relative):** Behavior_*.sol + TestBase_*.sol + 2 gaps + GAP_REPORT.md

**Current State Summary (post closure):**
Full LR-1 (rich + exact tags 29) + LR-7 (full expect/isValid/hasValid surface impl + use + exact + Behavior mandatory) CLOSED.

**Detailed Gaps Closed (detailed recap modeled on closed ERC721Repo + Behavior_IERC165 gaps):**
- LR-1 CLOSED: full rich NatSpec + EXACT // tag:: / end:: (29 tags) + @custom ONLY from CENTRALLY (none for IERC721 surface).
- LR-7 CLOSED: implemented expect_*/isValid_*/hasValid_* for IERC721 (balance/owner/approved/transfer etc); uses sets/comparators style + logs; Behavior mandatory use added to TestBase; supports declaration tests + exact asserts + init notes.

**Actions Taken (strict scope, read order followed):**
- Wrapped symbols with exact tags.
- Rich NatSpec; no @custom (per central).
- Full expect/isValid/hasValid impl for LR-7.
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature / topiczero / interfaceid with accurate values (to be centrally computed).
3. For Repos: ensure DEFAULT_SLOT uses bytes32(uint256(keccak256(...)) - 1) per ERC1967.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols Tagged (from source read):**
- Main library + all public fns (29 with hyphen overload tags per gold)
- (See full list in closure recap: 29 symbols with hyphen tags)

**LR-7 Gaps closed:** expect/isValid/hasValid implemented (use sets/comps); declaration support; TestBase uses + init/enforce + exact asserts.

**Documentation/Skills:** addressed via full NatSpec/tags for GitBook later.

**Notes for Subagents:**
- Only fixes for this file's gaps (followed).
- @custom ONLY from CENTRALLY (none here).
- GAP_REPORT.md [x] entry added.
- Relative paths only.

**Priority:** High (core framework files)
