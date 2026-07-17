# Gap Report for: contracts/introspection/ERC165/ERC165Facet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature for facet and all public methods)
- LR-7: Testing Standards (facet declaration tests via Behavior_IFacet / TestBase_IFacet for facetInterfaces/facetFuncs)

**Current State Summary:**
LR-1 completed in this scoped pass: basic tags + @inheritdoc were present (5 tags), enriched with rich @notice/@dev/@return + @custom:selector/@custom:signature (using ONLY centrals) on contract + all public IFacet methods. Exact gold // tag:: / end:: for ERC165Facet[], facetName()[], facetInterfaces()[], facetFuncs()[], facetMetadata()[] . Used @inheritdoc IFacet + Crane section headers. No logic changes. (Note: declaration test coverage exists via Behavior_IERC165 + TestBase_IERC165 and IFacet behaviors; LR-7 test gap not addressed in source edits.)

**Detailed Gaps (closed by this work):**
- LR-1: incomplete (minimal @inheritdoc only) NatSpec with // tag:: ; missing rich @notice/@dev/@return + @custom:selector/signature on IFacet methods (per ERC8023/WETHAware/CallTarget gold standard).
- LR-1: Enrich facetName, facetInterfaces, facetFuncs, facetMetadata with full required elements.
- (LR-7 test declaration coverage pre-existing for this facet via related TestBases/Behaviors; source changes support by making facet fully documented. No test files edited per rules.)

**Specific Actions Needed to Close Gaps:**
1. Enriched documented symbols (contract + 4 public fns) with rich NatSpec inside existing exact // tag::Symbol(params)[] ... // end:: (no tag changes).
2. Added @notice/@dev/@return/@inheritdoc + @custom:selector / @custom:signature using ONLY central/verified values (from CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
3. Added Crane section header for imports (fits style).
4. Updated this gap report + main GAP_REPORT.md tracking.
5. Verified via targeted forge inspect (abi|methodIdentifiers) + forge build --skip test --quiet (specific) + forge test --list --match-path '*ERC165*' (narrow). No other files.

**Central NatSpec Values Used (from docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md ; ONLY these):**

From central (this LR-1 scoped pass):
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75
- supportsInterface(bytes4) : 0x01ffc9a7  (used by IERC165 declaration in this facet; IERC165.interfaceId == 0x01ffc9a7)

**NatSpec Symbols Tagged (exact):**
- ERC165Facet (contract)
- facetName()
- facetInterfaces()
- facetFuncs()
- facetMetadata()

Final tag count: 5 (symbols with // tag:: / // end:: )

(No events/errors declared on this facet contract itself; supportsInterface NatSpec lives in ERC165Target + IERC165 interface. IFacet customs live in contracts/factories/diamondPkg/IFacet.sol per pattern; duplicated @customs in impl per WETHAware/CallTarget golds using centrals.)

**Testing Gaps (LR-7 specific if applicable):**
- Declaration tests pre-existing (via TestBase_IERC165.sol + Behavior_IERC165.sol in contracts/introspection/ERC165/ and IFacet behavior tests; uses Behavior for support checks and facet metadata).
- Source now has full NatSpec+tags to match LR-1 for documented surface (tests themselves out of scope per edit rules; no edits to any test/* or other contracts).
- (Other LR-7 like full pkg init, preview parity, etc. not applicable to this pure facet file. Note that full package init with real facets would be in DFPkg tests.)

**Documentation/Skills Gaps (if applicable):**
- Surface documented via source tags for extraction (LR-2/LR-3 notes remain general).

**Notes for Subagents (post-fix):**
- Implemented only fixes for this file's gaps per rules (only edited: contracts/introspection/ERC165/ERC165Facet.sol + this gap report + GAP_REPORT.md).
- Used ONLY central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (never ad-hoc compute).
- Updated main GAP_REPORT.md checkbox.
- Ran `forge build` + relevant tests (e.g. matching ERC165 and IFacet behaviors).
- Do not edit other files (followed strictly).
- Prioritized LR-1 NatSpec + notes on LR-7; no LR-6 slots here.

**LR-1 Scoped Task Execution (this pass):**
Strict read order BEFORE ANY edit/search_replace:
1. docs/reports/gap/contracts/introspection/ERC165/ERC165Facet.sol.md
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75; also noted supportsInterface 0x01ffc9a7)
3. PRD.md (LR-1 NatSpec section: rich @notice/@dev/@param/@return/@inheritdoc, @custom:selector/signature from verified centrals, exact // tag::Name(params)[] / end::, @inheritdoc IFacet, IFacet gold, no fabrication)
4. AGENTS.md (full relevant: NatSpec+AsciiDoc include-tags standard, exact no-extra-spaces // tag:: / end:: , hyphenated overloads e.g. facetMetadata()[], rich NatSpec, Crane headers, ONLY 3 files relative, targeted verif, no viaIR, golds)
5. Gold examples: WETHAwareFacet.sol, ERC20Facet.sol, FacetRegistryFacet.sol, CallTargetRegistryManagementFacet.sol, Behavior_IFacet.sol, contracts/factories/diamondPkg/IFacet.sol (for patterns of rich docs on IFacet impls + tags + Crane headers)
6. Then source: contracts/introspection/ERC165/ERC165Facet.sol
- Enriched: added rich @notice/@return/@dev + @custom:selector/@custom:signature (ONLY centrals) on all 4 IFacet public methods; kept @inheritdoc IFacet; upgraded import section to Crane full header style; no logic/pragma/func changes.
- Tags preserved exact: ERC165Facet[], facetName()[], facetInterfaces()[], facetFuncs()[], facetMetadata()[] (5 total)
- ONLY 3 files total edited (relative paths only).
- Post-edit targeted verif ONLY: `forge inspect ...ERC165Facet.sol:ERC165Facet (abi|methodIdentifiers)` (selectors matched centrals exactly), `forge build contracts/introspection/ERC165/ERC165Facet.sol --skip test --quiet` (BUILD_EXIT=0), `forge test --list --match-path '*ERC165*'` (narrow; exit 0).
- File inspects clean (selectors: facetName=0x5b6f4d01, facetInterfaces=0x2ea80826, facetFuncs=0x574a4cff, facetMetadata=0xf10d7a75).
- Final: **Status: LR-1 CLOSED**

**Priority:** High (core framework files)

**Status:** LR-1 CLOSED
