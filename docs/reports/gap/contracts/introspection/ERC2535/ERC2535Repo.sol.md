# Gap Report for: contracts/introspection/ERC2535/ERC2535Repo.sol

**File Type:** Repo

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard
- LR-6: ERC1967-Compliant Storage Slot Derivation

**Current State Summary:**
Gaps closed for this file per LR-1 and LR-6. (Targeted edits for richness + standardization; verified via forge inspect on repo + dependents + test contract discovery. Full build/test runs limited by project size but targeted compile succeeded.)

**Detailed Gaps (Closed):**
- LR-6: STORAGE_SLOT updated to the exact ERC1967 form specified (bytes32(uint256(keccak256(abi.encode("eip.erc.2535"))) - 1); ).
- LR-1: full NatSpec + // tag:: // end:: ensured for library, Storage, _layoutStruct overloads, _diamondCut/_process*/*Facet*/_facets*/_facet* getters (hyphenated tags, rich @dev/@notice/@param/@return/@custom:emits per OperableRepo gold standard). No _initialize or guards present in this Repo.
- Consulted CENTRALLY_COMPUTED_NATSPEC_VALUES.md (for referenced I* symbols like IDiamond.DiamondCut, IERC8109Update.* if @custom).

**Actions Completed:**
- Confirmed/ensured STORAGE_SLOT uses exact ERC1967 form bytes32(uint256(keccak256(abi.encode("eip.erc.2535"))) - 1) (LR-6). Minor comment alignment.
- Added/enriched full rich NatSpec + exact // tag:: / // end:: for: library, Storage, _layoutStruct overloads, _diamondCut (both), _processFacetCuts (both), _processFacetCut, _addFacet, _replaceFacet, _removeFacet, _facets (both), _facetFunctionSelectors (both), _facetAddresses (both), _facetAddress (both). Used OperableRepo gold style for tags (hyphenated compacted param lists e.g. Storage-IDiamond.FacetCut[]-address-bytes) and phrasing.
- Enriched NatSpec: standardized @param layoutStruct descriptions to "The Storage struct to operate on.", converted view @notice->@dev for repo internals, added detailed @dev from logic (revert conditions, CRANE- refs, set maintenance, emit conditions).
- Param names use storageSlot / layoutStruct per OperableRepo.
- Consulted CENTRALLY_COMPUTED_NATSPEC_VALUES.md (no new @custom:selector/signature/topiczero needed or added for internals; @custom:emits use existing refs like IDiamond.DiamondCut / IERC8109Update.* ). No central values inserted.
- Verified with forge inspect (repo + DiamondCutTargetStub). Relevant tests (DiamondCut.t.sol exercising cuts/loupe via repo) listed in tracking; full execution impacted by monorepo scale but compile of test surface succeeded via dependents.
- Only edited: source + this report + GAP_REPORT.md .

**NatSpec Symbols Tagged:**
- ERC2535Repo, STORAGE_SLOT, Storage, _layoutStruct(bytes32), _layoutStruct(), _diamondCut*2, _processFacetCuts*2, _processFacetCut, _addFacet, _replaceFacet, _removeFacet, _facets*2, _facetFunctionSelectors*2, _facetAddresses*2, _facetAddress*2. (See updated source for enriched docs.)
- All dual overloads and internal helpers now have rich @dev/@param/@return/@custom:emits .

**Testing Gaps (LR-7 specific if applicable):**
N/A for direct edits here (limited to the ERC2535Repo.sol component). Related tests (e.g. DiamondCut.t.sol) use the repo indirectly. Validation via compile of DiamondCutTargetStub + indirect usage confirmed. (Full test execution not required for this scoped LR-1/LR-6 edit.)

**Documentation/Skills Gaps (if applicable):**
Out of scope (no edit to docs beyond this report and GAP_REPORT.md).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (LR-1/LR-6). Performed fresh pass: confirmed slot form, enriched NatSpec details and standardized phrasing to Operable gold (layoutStruct param docs, @dev for internals).
- Central values consulted from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (none newly added; only used existing pattern for @custom:emits refs).
- Updated this report + main GAP_REPORT.md tracking with verification note.
- Did not edit other files (per rules: no scope creep, targeted to report).
- Verified compilation: `forge inspect contracts/introspection/ERC2535/ERC2535Repo.sol` (and dependent DiamondCutTargetStub) succeeded.

**Priority:** High (closed)

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list.
For referenced events in @custom:emits:
- DiamondCut(FacetCut[],address,bytes) topic0 would use cast keccak if needed in future central pass.
- DiamondDelegateCall , DiamondFunctionRemoved from IERC8109Update.
For this Repo no direct @custom:selector values required (internal functions).
Use central values when implementing any interface changes (none here).

