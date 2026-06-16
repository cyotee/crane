# Gap Report for: contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol

**Status: LR-1 + LR-7 notes CLOSED**

**File Type:** Test (Behavior TestBase)

**Primary Affected Requirements (from PRD):**
- LR-7: full init, exact asserts, mandatory Behavior_*, decl tests, NatSpec on test
- LR-1: NatSpec + exact tags on TestBase

**Strict Process Followed (exact order before ANY edit):**
1. Read per-file: docs/reports/gap/contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol.md (and Behavior pair)
2. Read CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY listed; IFacet + IDiamond* ; no fab)
3. Read PRD.md LR-1 (NatSpec+tags), LR-7 (init/exact/Behavior/decl/NatSpec on tests)
4. Read AGENTS.md full (TestBase gold, Behavior usage, ONLY 5 files max for this batch, relative, targeted verif)
5. Read golds: TestBase_IERC165.sol + TestBase_IFacet.sol + Behavior_*.sol + closed ERC721 gap style + BehaviorUtils
6. Re-read source contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol immediately before edit. Pre tags=0

**ONLY edited 5 relative files total:** the 2 .sol + 2 .sol.md gaps + GAP_REPORT.md

**Pre state:** 0 tags, setUp lacked non0 assert, bare assert() in facets test, no rich NatSpec, partial Behavior use.

**Edits:** full rich NatSpec + EXACT // tag::TestBase_IDiamondLoupe[] / setUp[] / diamondLoupe_subject()[] / expected_IDiamondLoupe_facets()[] / test_IDiamondLoupe_*[] (4) / erc165Funcs()[] / diamondLoupeFuncs()[] + sub const. LR-7: non-zero assertTrue(msg), all tests use assertTrue(msg) + Behavior calls preserved, exact.

**Verif (targeted post only):** forge inspect on TestBase (shows added selectors like test_IDiamondLoupe_* 0x9023..), forge build --skip --quiet the 2sol (0), list match-path DiamondLoupe (ran).

**CLOSED:** LR-1 + LR-7 notes. Modeled gold TestBase_IERC165. See GAP_REPORT.md [x] + sibling Behavior gap. Pre 0 tags / added 11+.

**Priority:** High - CLOSED
