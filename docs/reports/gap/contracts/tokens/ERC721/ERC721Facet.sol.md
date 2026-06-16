# Gap Report for: contracts/tokens/ERC721/ERC721Facet.sol

**File Type:** Facet

**Status: LR-1 CLOSED**

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + tags + @custom from centrals)

**Current State Summary:**
LR-1 addressed for this Facet: was partial tags (~4), now full gold LR-1 with rich NatSpec.

**Detailed Gaps Closed:**
- LR-1: Added complete NatSpec with // tag:: and @custom: tags (modeled on ERC165Facet/WETHAwareFacet gold).
- LR-1: Documented facetName, facetInterfaces, facetFuncs, facetMetadata + all ERC721 specific public methods.

**Exact Symbols/Tags Added (14 tags total):**
- ERC721Facet[]
- facetName()[]
- facetInterfaces()[]
- facetFuncs()[]
- facetMetadata()[]
- balanceOf(address)[]
- ownerOf(uint256)[]
- safeTransferFrom(address-address-uint256-bytes)[]
- safeTransferFrom(address-address-uint256)[]
- transferFrom(address-address-uint256)[]
- approve(address,uint256)[]
- setApprovalForAll(address,bool)[]
- getApproved(uint256)[]
- isApprovedForAll(address,address)[]

**Recap of Strict Process Followed (before ANY search_replace/edit):**
Read in EXACT order:
1. The three per-file gaps (ERC721Facet.sol.md, ERC721MetadataFacet.sol.md, ERC721EnumeratedFacet.sol.md)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY used the listed IFacet values: facetName 0x5b6f4d01, facetInterfaces 0x2ea80826, facetFuncs 0x574a4cff, facetMetadata 0xf10d7a75 for @custom: ; + referenced; NO fabrication of any @custom for ERC721 surface)
3. PRD.md LR-1 section
4. AGENTS.md (NatSpec rules + exact // tag::Name(params)[] / end:: , hyphenated for overloads, rich @notice/@dev/@param/@return/@inheritdoc IFacet, @custom ONLY from centrals, ONLY 3 .sol work + gaps + GAP, targeted verif only, model on gold facets)
5. Gold examples: contracts/introspection/ERC165/ERC165Facet.sol (has @custom + tags), WETHAwareFacet.sol, ERC20Facet.sol, FacetRegistryFacet.sol, other closed IFacet impls (ERC4626 inspected for patterns but not edited)
6. Then the 3 source files.
- ONLY edited: the 3 .sol + 3 per-file gaps + GAP_REPORT.md (relative paths; 7 files total for batch; no other files touched)
- Used rich NatSpec on contract + IFacet methods + ERC721 publics; @custom ONLY centrals for IFacet 4; Crane section headers; @title/@author/@dev; @inheritdoc IFacet ; exact matching tags (hyphenated overloads for the two safeTransferFrom + transferFrom).
- Preserved 100% logic.

**Targeted Verification ONLY (post all edits):**
- forge inspect contracts/tokens/ERC721/ERC721Facet.sol:ERC721Facet (abi|methodIdentifiers)
- forge build contracts/tokens/ERC721/ERC721Facet.sol contracts/tokens/ERC721/ERC721MetadataFacet.sol contracts/tokens/ERC721/ERC721EnumeratedFacet.sol --skip test --quiet
- narrow forge test --list --match-path '*ERC721*Facet*'
(Selectors for IFacet matched centrals 0x5b6f4d01 etc; build exit 0 clean for the three.)

**Notes:** LR-7 declaration test gaps noted but out of this scoped LR-1 batch (no test files touched). 

**Priority:** High (core framework files)
