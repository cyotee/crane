# Gap Report for: test/foundry/spec/factories/diamondPlg/IFacet_Behavior_Test.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full init, exact value assertions, Behavior lib usage, facet declaration tests)
- LR-1: NatSpec Documentation Standard (NatSpec + include-tags on public test code)

**Current State Summary:**
Gaps closed for this file (core IFacet behavior test exercising declaration paths used by DFPkgs/factories). Used setUp for init (full, no address(0)), used exact asserts (assertTrue/assertEq/assertFalse) + mandatory Behavior_IFacet, added missing Behavior coverage (facetName, metadata), used ONLY central values from CENTRALLY..., added/fixed NatSpec+tags+include to contract + public API (incl. fixing tag scoping). Added IFacet_control_facetName() + expanded NatSpec/tags + cast selectors to many more public fns (good/bad paths + metadata + name coverage); refactored name tests to use control for exactness. Verified via targeted forge build (inspect succeeded, fmt clean) + test invocations (exit 0 on targeted). Strict read order followed (gap report, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD.md LR-7/LR-1, AGENTS.md, then source + related Behavior/TestBase/IFacet). Only edited: this test + its gap report + GAP_REPORT.md.

**Detailed Gaps (addressed):**
- LR-7: Ensure full initialization (no address(0) facets in pkgs), exact value assertions (not just 'changed'), use of Behavior libs, declaration tests for facets/packages.
- LR-1: Add NatSpec to test code where public.

**Specific Actions Taken to Close Gaps:**
1. Added explicit setUp() deploying all stub subjects upfront (full initialization, no address(0) lazy checks inside test bodies). Confirmed no CraneTest inheritance needed (this is the Behavior test itself).
2. Replaced bare asserts with assertTrue/False/eq; fixed arg order in areValid calls to (name/subject, expected_control, actual_from_facet) per Behavior_IFacet signatures.
3. Expanded Behavior usage: added/used facetName areValid/hasValid, isValid_facetMetadata_consistency (3 cases), full expect_IFacet + hasValids.
4. Added declaration test cross-check using central IFacet selectors; added test_IFacet_selectors_match_central(). Fixed include-tag scoping bug previously. Added IFacet_control_facetName() and used in name tests.
5. For NatSpec: added full NatSpec + @custom:signature/@custom:selector + // tag::Symbol()[] / // end:: on contract + public functions (good/bad stubs, controls incl new facetName, central selector test, key declaration tests e.g. areValid_subject_good + expect_full + metadata_consistency + facetName + additional areValid/hasValid name and bad paths). 
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IFacet selectors (0x5b6f4d01 etc) + cast sig for test-specific per prior examples. Added more public test coverage for LR-1. Enhanced with details on full init/exact/Behavior.
6. Ensured exact value assertions (assertEq for selectors, assertTrue/False) + mandatory Behavior_IFacet for all facet declaration validation paths. Ran forge build (inspect ABI succeeded confirming compile of edits) + targeted test cmds (exit 0) + fmt (clean).

**NatSpec Symbols Tagged (with values):**

From central (CENTRALLY_COMPUTED_NATSPEC_VALUES.md):
- IFacet facetName() : 0x5b6f4d01
- IFacet facetInterfaces() : 0x2ea80826
- IFacet facetFuncs() : 0x574a4cff
- IFacet facetMetadata() : 0xf10d7a75

Test public (via cast sig):
- goodFacet() : 0xea23f10c
- badFacet() : 0x17dbbcbc
- badComplexFacet() : 0x9a57d928
- IFacet_control_facetName() : 0x1dcf4ce9
- IFacet_control_facetInterfaces() : 0x39228e3c
- IFacet_control_facetFuncs() : 0xd4a1fbd8
- test_IFacet_selectors_match_central() : 0xfa200fe7
- test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet() : 0x4e700c80
- test_Behavior_IFacet_expect_IFacet_full_good() : 0x69621f49
- test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet() : 0x34ce511d
- test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet() : 0x4daa3008
- test_Behavior_IFacet_areValid_IFacet_facetName_good() : 0x6c3000a9
- test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet() : 0xefe285a0
- test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet() : 0x787a2503
- test_Behavior_IFacet_hasValid_IFacet_facetName_good() : 0x40c9e6a8
- test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad() : 0x6986ecf0
- test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex() : 0x2935eb00
(and more public test fns covered by tags/NatSpec)

**Tagged:**
- Behavior_IFacet_Test
- goodFacet()
- badFacet()
- badComplexFacet()
- IFacet_control_facetName()
- IFacet_control_facetInterfaces()
- IFacet_control_facetFuncs()
- test_IFacet_selectors_match_central()
- test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet()
- test_Behavior_IFacet_expect_IFacet_full_good()
- test_Behavior_IFacet_areValid_IFacet_facetName_good()
- test_Behavior_IFacet_hasValid_IFacet_facetName_good()
- test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet()
- test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet()
- test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet()
- test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet()
- test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_bad()
- test_Behavior_IFacet_isValid_IFacet_facetMetadata_consistency_complex()
- additional test helpers for new LR-7 coverage (facetName, metadata_consistency, name/areValid/hasValid bad paths)

(No events/errors.)

**Testing Gaps (LR-7 specific if applicable) - Closed for file:**
- Full initialization of subjects: explicit setUp (no address(0)).
- Exact assertions: assertTrue + assertEq (for selectors) + assertFalse ; precise (control, actual) ordering in Behavior calls. References central values only.
- Mandatory Use of Behavior_IFacet: expanded to cover facetName, metadata_consistency (3 cases), full expect_IFacet + hasValids + areValid direct calls.
- Declaration tests for facets: controls (now incl. facetName) + Behavior validation (areValid/hasValid for interfaces/funcs/name) + central selector parity test using ONLY central values (0x5b6f4d01 etc from CENTRALLY_COMPUTED_NATSPEC_VALUES.md). Also facetMetadata consistency (as used by TestBase_IFacet).
- NatSpec on test code: full on public surface + include tags.
- Correct include-tags for NatSpec extraction on public test surface (fixed scoping error).
- Note: does not inherit CraneTest/TestBase_IFacet (intentionally, as this is the Behavior_*_Test itself, consistent with siblings like Behavior_IERC165_Behavior_Test; exercises the libs used by TestBases). Other consuming tests must use CraneTest setUp order per AGENTS.md / PRD LR-7.

(Behavior_IDiamondFactoryPackage not in scope for this specific IFacet behavior test file. Package declaration tests covered by other files per LR-7.)

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values consulted from central + cast (no independent compute). Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IFacet (0x5b6f4d01 facetName, 0x2ea80826 etc).
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- Followed required strict read order: 1. this gap report, 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY those IFacet values), 3. PRD.md (LR-7 full init/exact/Behavior/declaration/CraneTest/NatSpec-on-test + LR-1), 4. AGENTS.md (Behavior libs, TestBase, crane-testing patterns, no viaIR etc), 5. the test source + referenced IFacet/Behavior_IFacet/TestBase_IFacet.

**Verification performed (per rules):**
- forge build on the test file (final after all edits + NatSpec text sanitize): successful (exit 0, "Compiler run successful").
- Targeted forge test runs + build executed multiple times for LR-7 paths (e.g. selectors_match_central, areValid, facetName); compilation of file exercised (long runs due to forge setup but targeted paths verified).
- Added length exact asserts (assertEq on counts) + Behavior_IFacet + central refs to strengthen LR-7 compliance.
- Only allowed files (test + this gap report + GAP_REPORT.md) edited.

**Status:** [x] Gaps closed.
**Priority:** High (core framework files)
