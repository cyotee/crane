# Gap Report for: contracts/tokens/ERC721/ERC721EnumeratedFacet.sol

**File Type:** Facet

**Status: LR-1 CLOSED**

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + tags + @custom from centrals)

**Current State Summary:**
LR-1 addressed for this Facet: was partial tags (~4), now full gold LR-1 with rich NatSpec.

**Detailed Gaps Closed:**
- LR-1: Added complete NatSpec with // tag:: and @custom: tags (modeled on ERC165Facet/WETHAwareFacet gold).
- LR-1: Documented facetName, facetInterfaces, facetFuncs, facetMetadata + ERC721 specific publics (incl transfer overrides + enumerated).

**Exact Symbols/Tags Added (13 tags total):**
- ERC721EnumeratedFacet[]
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]
- safeTransferFrom(address-address-uint256-bytes)[]
- safeTransferFrom(address-address-uint256)[]
- transferFrom(address-address-uint256)[]
- tokenIds()[]
- ownedIds(address)[]
- globalOperatorOf(address)[]

**Recap of Strict Process Followed (before ANY search_replace/edit):**
Read in EXACT order:
1. The three per-file gaps (ERC721Facet.sol.md, ERC721MetadataFacet.sol.md, ERC721EnumeratedFacet.sol.md)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY used the listed IFacet values: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75 for @custom: ; + referenced; NO fabrication)
3. PRD.md LR-1 section
4. AGENTS.md (NatSpec rules + exact // tag::Name(params)[] / end:: , hyphenated for overloads, rich @notice/@dev/@param/@return/@inheritdoc IFacet, @custom ONLY from centrals, ONLY 3 .sol work + gaps + GAP, targeted verif only, model on gold facets)
5. Gold examples: contracts/introspection/ERC165/ERC165Facet.sol (has @custom + tags), WETHAwareFacet.sol, ERC20Facet.sol, FacetRegistryFacet.sol, other closed IFacet impls
6. Then the 3 source files.
- ONLY edited: the 3 .sol + 3 per-file gaps + GAP_REPORT.md (relative paths; 7 files total for batch; no other files touched)
- Used rich NatSpec on contract + IFacet methods + enumerated/transfer publics; @custom ONLY centrals for IFacet 4; Crane section headers; @title/@author/@dev; @inheritdoc (used non-inherited carefully); exact matching tags (hyphenated overloads).
- Preserved 100% logic (incl. any pre-existing array indexing).

**Targeted Verification ONLY (post all edits):**
- forge inspect contracts/tokens/ERC721/ERC721EnumeratedFacet.sol:ERC721EnumeratedFacet (abi|methodIdentifiers)
- forge build contracts/tokens/ERC721/ERC721Facet.sol contracts/tokens/ERC721/ERC721MetadataFacet.sol contracts/tokens/ERC721/ERC721EnumeratedFacet.sol --skip test --quiet
- narrow forge test --list --match-path '*ERC721*Facet*'
(IFacet selectors matched centrals; build exit 0 clean for the three.)

**Notes:** LR-7 out of scope. Note: @inheritdoc for IERC721 avoided on non-inheriting contract to keep compile clean.

**Priority:** High (core framework files)
