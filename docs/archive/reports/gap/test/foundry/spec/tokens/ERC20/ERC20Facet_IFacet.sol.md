# Gap Report for: test/foundry/spec/tokens/ERC20/ERC20Facet_IFacet.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full init no address(0) state, exact value assertions, mandatory Behavior lib usage for IFacet surfaces, facet declaration tests, proper TestBase patterns, NatSpec on test code)
- LR-1: NatSpec Documentation Standard (on test code public surfaces)

**Current State Summary:**
Gaps closed for this file (core ERC20 facet declaration test using TestBase_IFacet + Behavior_IFacet). Added explicit setUp for LR-7 full init (real ERC20Facet, vm.label, no lazy/zeros), expanded explicit Behavior_IFacet usage (expect_IFacet_facet* + hasValid + areValid + isValid_metadata_consistency), added dedicated LR-7 declaration test exercising full Behavior surface + exact asserts. Added full NatSpec + // tag::[] / @custom:signature/@custom:selector on contract + public/override/test fns. Used ONLY central IFacet values (0x5b6f4d01 facetName etc from CENTRALLY_COMPUTED_NATSPEC_VALUES.md) + type().interfaceId (authoritative) for ERC20 ids. Targeted test + build verification done. (Only edited: the test .sol + this gap report + GAP_REPORT.md)

**Detailed Gaps (addressed):**
- LR-7: Ensure full initialization (no address(0) facets in pkgs), exact value assertions (not just 'changed'), use of Behavior libs, declaration tests for facets/packages.
- LR-1: Add NatSpec to test code where public (contract, helpers, LR7 test).

**Specific Actions Taken to Close Gaps:**
1. Added setUp() override with explicit LR-7 full init (call super; vm.label on the instantiated ERC20Facet from facetTestInstance(); comments cite no-lazy/no-0 per PRD/AGENTS). Upfront Behavior_IFacet.expect_* recorded in setUp for subject (matches diamondPlg/operable LR-7 patterns).
2. Enhanced to explicit Behavior_IFacet: expect calls (in setUp) + hasValid/areValid/isValid_..._consistency with exact expected/actual and assertTrue in dedicated test.
3. Added dedicated LR-7 facet declaration test (test_LR7_ERC20Facet_declaration_viaBehavior) covering name/interfaces/funcs + metadata consistency using Behavior.
4. Added NatSpec (title/notice/dev) + exact // tag::Name(params)[] / end:: + @custom:signature/@custom:selector (central IFacet + computed for test fns) on contract + all public overrides + new test. Imported Behavior_IFacet for direct calls.
5. Ensured exact asserts (lengths via base + direct areValid + hasValid). No previews here; used type().interfaceId for ERC20 controls (matches source facet impl).
6. Followed crane-testing patterns, TestBase_IFacet + Behavior (AGENTS), proper virtual overrides. Referenced central ONLY for IFacet. Ran forge test + build.
7. (No DFPkg package decls in this file as it is the pure IFacet facet decl test per existing structure; package decls covered in DFPkg tests + DiamondPackageCallBackFactory.t.sol LR-7 work.)

**NatSpec Symbols Tagged (with values from central):**

From CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY these for known symbols):
### IFacet (common, for Behavior declaration)
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75
- supportsInterface(bytes4) : 0x01ffc9a7

Test symbols (for central follow-up pass):
- ERC20Facet_IFacet_Test : 
- facetTestInstance() : 0xceb0cc95
- controlFacetName() : 0x4712e80f
- controlFacetInterfaces() : 0x890539e3
- controlFacetFuncs() : 0x5a5bc0c3
- setUp() : 0x0a9254e4
- test_LR7_ERC20Facet_declaration_viaBehavior() : 0x6ecb0193

(No events/errors on test surface beyond inherited.)

**Testing Gaps (LR-7 specific if applicable) - Closed for file:**
- Full initialization of subjects: setUp + facetTestInstance deploy real ERC20Facet (non-zero) + label; explicit comment on LR-7 full init no lazy.
- Exact assertions vs side-effect: base lengths + direct assertTrue on Behavior areValid/hasValid + exact consistency match (not loose "changed").
- Use of Behavior_IFacet: now explicit (expect + hasValid + areValid + metadata_consistency) in addition to base usage of areValid (mandatory per LR-7 for IFacet).
- Declaration tests for facets: pre-existing via TestBase + expanded with new dedicated LR7 test using full Behavior surface + central refs.
- Correct TestBase/CraneTest: uses TestBase_IFacet (behavior base, inherits Test directly as appropriate for pure facet decl per AGENTS.md / closed examples; no factory needed for this unit decl surface).
- NatSpec + tags on test public code (contract + fns).
- No package decl test edits here (this file targets facets via IFacet; see ERC20DFPkg_* and diamond pkg tests for package side).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implemented only fixes for this file's gaps (test .sol + its gap report + GAP_REPORT.md).
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IFacet values) + PRD.md (LR-1/LR-7) + AGENTS.md (NatSpec, testing, Behavior/TestBase, strict read order) + source (the .sol + TestBase_IFacet + Behavior_IFacet + ERC20Facet).
- Strict read order followed before edits: 1. target gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md, 3. PRD.md (LR sections), 4. AGENTS.md, 5. source files (test + bases/behaviors/facet).
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- forge build + targeted `forge test --match-path test/foundry/spec/tokens/ERC20/ERC20Facet_IFacet.sol -vvv` executed.

**Status:** [x] Gaps closed.
**Priority:** High (core framework files)
