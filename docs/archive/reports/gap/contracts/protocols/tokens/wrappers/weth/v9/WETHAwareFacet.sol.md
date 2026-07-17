# Gap Report for: contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol

**File Type:** Facet

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full NatSpec + // tag:: / // end:: + @custom:selector/signature for IFacet methods + all public)
- (LR-7 notes only; no test edits per scope)

**Current State Summary:**
LR-1 CLOSED (scoped subagent LR-1 on WETHAwareFacet). Full rich NatSpec + EXACT gold // tag:: / end:: for contract + all public IFacet + weth surface. @custom:selector/signature used ONLY from CENTRALLY_COMPUTED_NATSPEC_VALUES (IFacet: 0x5b6f4d01 / 0x2ea80826 / 0x574a4cff / 0xf10d7a75). @inheritdoc IFacet. Modeled on ERC20Facet / ERC165Facet / FacetRegistryFacet golds. No storage (LR-6 n/a). ONLY 3 files edited (relative paths). Targeted verif executed.

**Detailed Gaps (Closed):**
- LR-1: Added // tag::WETHAwareFacet[] + rich header (@title/@author/@dev referencing Facet-Target-Repo + IWETHAware + Balancer IWETH reuse).
- All surface: facetName()[], facetInterfaces()[], facetFuncs()[], facetMetadata()[], weth()[] with exact hyphen-style tags, rich @notice/@return/@dev/@inheritdoc + @custom:selector + @custom:signature from centrals only.
- No @custom fabricated.

**Specific Actions Needed to Close Gaps:**
1. Wrapped documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Added rich @title/@author/@dev + @inheritdoc IFacet + @notice/@return/@dev + @custom:selector / @custom:signature using ONLY the centrals (no fabrication).
3. (No Repo slot; WETHAwareRepo handled separately.)
4. Updated this per-file gap + main GAP_REPORT.md .
5. Targeted verification only (no full test runs).

**NatSpec Symbols Tagged (exact, count: 6):**
- WETHAwareFacet[] (main contract wrapper + rich header)
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]
- weth()[] (WETH specific public)

Modeled exactly on golds (esp. ERC20Facet/ERC165Facet for structure/@title/@author/@dev/@inheritdoc + sections; + CallTarget style for duplicated rich @notice + centrals @custom on IFacet overrides per LR-1 full req).

**Post-fix NatSpec on IFacet methods (rich + centrals):**
Used @inheritdoc IFacet + copied @notice/@return/@dev from IFacet.sol + @custom:selector/@custom:signature ONLY from central values listed.

**Testing Gaps (LR-7 specific if applicable):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- No test/source edits here (ONLY 3 files rule strictly followed).
- LR-7 declaration support: pre-existing Behavior_IFacet / TestBase_IFacet paths in ecosystem cover facets; source now fully documented for it.
- Full init etc. are in test files (out of scope).

**Documentation/Skills Gaps (if applicable):**
- Source now extractable via tags. (LR-2/3 general.)

**Notes for Subagents (post-fix):**
- Implemented ONLY fixes for this file's LR-1 gaps.
- Used ONLY central values for IFacet @custom (never ad-hoc).
- Strict "ONLY 3 files" rule: edited contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol + this + GAP_REPORT.md (relative paths).
- Update main GAP_REPORT.md with [x].
- Targeted ONLY verif (per AGENTS/PRD): forge inspect ... (abi|methodIdentifiers), forge build ... --skip test --quiet , forge test --list --match-path '*WETH*'
- Do not edit other files.

**Priority:** High (core framework files)

**Status:** CLOSED (LR-1 NatSpec + tags for WETHAwareFacet; 6 symbols; ONLY centrals; strict order + ONLY 3 files followed)
