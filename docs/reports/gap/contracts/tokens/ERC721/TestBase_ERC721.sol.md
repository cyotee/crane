# Gap Report for: contracts/tokens/ERC721/TestBase_ERC721.sol

**Status: LR-1 + LR-7 CLOSED**

**File Type:** Test (Behavior TestBase)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec + exact tags on test code (TestBases)
- LR-7: full init, exact asserts, Behavior_* mandatory, declaration tests, NatSpec on tests

**Current State Summary:**
(Review based on PRD checklist. Many core files have partial or no full NatSpec/tags, incorrect slots in Repos, insufficient test assertions/init, incomplete docs/skills coverage.)

**Detailed Gaps Closed:**
- LR-7: Added non-zero assert + CraneTest init notes, exact value (preserved assertEq), added Behavior_IERC721.* calls in invariants, declaration support.
- LR-1: full rich NatSpec + exact // tag::TestBase_ERC721[] + all symbols (setUp, virtuals, 4 invariants) .

**Actions Taken (strict):**
1. Fix init in setUp or before tests.
2. Change asserts to exact expected values.
3. Add Behavior_* calls.
4. Add facet/package metadata assertions.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols Tagged (from source read pre):**
- TestBase_ERC721[] + setUp()[] + _deploy*[] + _register*[] + 4 invariant_*()[] (hyphen modeled). Total ~10 tags.

**LR-7 closed (init/enforce, Behavior use, exact, decl support via isValid):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- Exact assertions vs side-effect checks.
- Preview vs execute parity.
- Use of Behavior_IFacet / Behavior_IDiamondFactoryPackage etc.
- Declaration tests for facets and packages.

**Documentation:** full tags enable.

**Notes for Subagents (followed):**
- Only fixes for this file's gaps (relative 5 files).
- @custom from CENTRALLY only (n/a).
- GAP_REPORT [x] done.
- Relative paths only.

**Priority:** High (core framework files) - CLOSED

**Recap:** read order exact, 0 pre tags to ~10 post (TestBase_ERC721[] + setUp + virtuals + invariants with hyphen modeled), Behavior calls + init + exact per LR, modeled golds (TestBase_ERC20 etc), targeted verif only, [x] GAP. Logic preserved.
