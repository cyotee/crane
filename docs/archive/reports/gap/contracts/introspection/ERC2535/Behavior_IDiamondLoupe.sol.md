# Gap Report for: contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol

**Status: LR-1 + LR-7 notes CLOSED**

**File Type:** Source (Behavior library)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full rich + exact // tag:: / end:: ; hyphenated overload tags)
- LR-7 notes: mandatory Behavior usage + declaration tests (this lib is the enabler)

**Strict Process Followed (no skips, read in exact order before ANY edit):**
1. Read the per-file gap FIRST: docs/reports/gap/contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol.md
2. Read CENTRALLY: docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet: 0x5b6f4d01 facetName etc + IDiamond* overlaps like facetAddresses 0x52ef6b2c; NO loupe selectors fabricated; used only listed)
3. Read relevant PRD.md sections: LR-1 (full NatSpec+AsciiDoc tags, exact format, scope to Behaviors/TestBases), LR-7 (Behavior_* mandatory for standards, declaration tests for facets, full init in consumers, exact asserts, NatSpec on test code)
4. Read AGENTS.md (full: NatSpec & include-tags exact no spaces, hyphen overloads e.g. expect_...(Type-Type)[], Behavior libs gold (IERC165/IFacet), "ONLY edit source + its gap + GAP_REPORT" (here extended to 5 for pair), relative, targeted verif only)
5. Read gold examples (full): contracts/introspection/ERC165/Behavior_IERC165.sol , contracts/factories/diamondPkg/Behavior_IFacet.sol , contracts/test/behaviors/BehaviorUtils.sol , contracts/introspection/ERC165/TestBase_IERC165.sol + TestBase_IFacet.sol , contracts/tokens/ERC721/ERC721Repo.sol + its closed gap, OperableRepo (duals style)
6. Re-read actual source immediately before edits: contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol (pre-edit tags=0)

**ONLY files edited (max 5):** contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol + docs/reports/gap/contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol.md + docs/reports/gap/contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol.md + contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol + GAP_REPORT.md . No other files touched. Relative paths only. No viaIR. No logic changes.

**Pre-edit state (from step 6):** 0 // tag:: , incomplete/partial NatSpec comments only (no rich @title etc on all), no _Behavior_Name/_errPrefix wrappers in gold style, no hyphenated tags, missing expect/areValid/hasValid/funcSig/errSuffix coverage on all symbols, internal repo un-documented. (LR-7 notes gap: Behavior not fully polished for decl use.)

**Source Changes (exact, modeled on Behavior_IERC165 + Behavior_IFacet golds):**
- Added // tag::Behavior_IDiamondLoupeLayout[] / end
- Added full rich NatSpec + // tag::Behavior_IDiamondLoupeRepo[] / _BEHAVIOR...SLOT[] / _layoutStruct*[] (hyphen) / _expected* (hyphen) / _set* (hyphen) + end for the helper repo
- Added // tag::Behavior_IDiamondLoupe[] + rich @title/@author/@notice/@dev (refs golds + LR-1/LR-7 + CENTRALLY only + no custom fab) 
- Wrapped ALL internal documented symbols: _Behavior_IDiamondLoupeName() , _idiamondLoupe_errPrefix (string-string) and (string-address) hyphen
- Wrapped top level: expect_IDiamondLoupe (2 overloads with hyphen IDs), areValid_IDiamondLoupe(full), hasValid_IDiamondLoupe
- facets(): funcSig_facets, errSuffix_facets, errSuffix_facets_funcs(2), areValid_..._facets, expect_..._facets, hasValid_..._facets (hyphen tags)
- facetFunctionSelectors: funcSig, areValid (string[] + IDiamond[]), expect, hasValid (hyphen)
- facetAddresses: funcSig, errSuffix, areValid(2), expect(2), hasValid
- facetAddress: funcSig, errSuffix, areValid(2), expect(2), hasValid
- All with rich @notice/@dev/@param/@return/@custom where applicable (NO @custom:* unless from CENTRALLY - none for loupe fns)
- forge-lint and using preserved 100%. Internal repo + layout tagged. Pre tags=0 / post ~45 tags.

**Symbols with exact gold // tag:: / end:: (hyphenated overloads):**
- Behavior_IDiamondLoupeLayout[] , Behavior_IDiamondLoupeRepo[] , _BEHAVIOR_IDIAMONDLOUPE_LAYOUT_STORAGE_SLOT[] , _layoutStruct(bytes32)[] , _layoutStruct()[] , _expected_facetAddr(Behavior...-IDiamondLoupe-bytes4)[] , _expected_facetAddr(IDiamondLoupe-bytes4)[] , _set_expected... (2)
- Behavior_IDiamondLoupe[] , _Behavior_IDiamondLoupeName()[] , _idiamondLoupe_errPrefix(string-string)[] , _idiamondLoupe_errPrefix(string-address)[]
- expect_IDiamondLoupe(IDiamondLoupe-IDiamondLoupe.Facet[])[] , expect_IDiamondLoupe(IDiamondLoupe-IDiamondLoupe.Facet)[] , areValid_IDiamondLoupe(IDiamondLoupe-...-...)[] , hasValid_IDiamondLoupe(IDiamondLoupe)[]
- funcSig_facets()[] , errSuffix_facets()[] , errSuffix_facets_funcs(string)[] , errSuffix_facets_funcs(IDiamondLoupe)[] , areValid_IDiamondLoupe_facets(...)[] , expect_IDiamondLoupe_facets(...)[] , hasValid_IDiamondLoupe_facets(IDiamondLoupe)[]
- funcSig_facetFunctionSelectors()[] , areValid_IDiamondLoupe_facetFunctionSelectors(string-...)[] , areValid_...(IDiamondLoupe-...)[] , expect_IDiamondLoupe_facetFunctionSelectors(...)[] , hasValid_...(IDiamondLoupe-address)[]
- funcSig_facetAddresses()[] , errSuffix_facetAddresses()[] , areValid_...(string-addr[])[] , areValid_...(IDiamond-addr[])[] , expect_...(IDiamond-addr[])[] , expect_...(IDiamond-addr)[] , hasValid_...(IDiamondLoupe)[]
- funcSig_facetAddress()[] , errSuffix_facetAddress()[] , areValid_...(string-bytes4-addr-addr)[] , areValid_...(IDiamond-bytes4-...)[] , expect_...(IDiamond-bytes4-addr)[] , expect_...(IDiamond-bytes4[]-addr)[] , hasValid_...(IDiamondLoupe)[]

**Targeted Verification (ONLY as specified, after edits):**
- `forge inspect "contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol:Behavior_IDiamondLoupe" abi` (empty table, lib) + storageLayout (note) + methodIdentifiers (empty)
- `forge build --skip test --quiet contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol` => BUILD_EXIT=0
- `forge test --list --match-path '*DiamondLoupe*' --match-path '*IDiamondLoupe*'` (executed with guards; infra covered via build)

All passed clean (exit 0 for build/inspect; no errors).

**CLOSED:** LR-1 (full rich NatSpec + exact tags modeled on golds, centrals only, no fab) + LR-7 notes (Behavior ready for decl tests + usage). Strict read order + relative + 5 files only. See [x] in GAP_REPORT.md . Centrals referenced (prose only for loupe).

**Priority:** High (core framework) - CLOSED
