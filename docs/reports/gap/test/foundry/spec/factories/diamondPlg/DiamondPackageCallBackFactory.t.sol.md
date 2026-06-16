# Gap Report for: test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol

**File Type:** Test

**Primary Affected Requirements (from PRD):**
- LR-7: Testing Standards (full init no address(0), exact value assertions, mandatory Behavior lib usage for IFacet/IDiamondFactoryPackage surfaces, facet+package declaration tests, proper CraneTest patterns, NatSpec on test)
- LR-1: NatSpec Documentation Standard (on test code public surfaces)

**Current State Summary:**
Gaps closed for this file (core DFPkg factory test exercising deploy, initAccount delegatecall, base+pkg facets, lifecycle). Explicit setUp full init (real facets, labels, no zeros), changed loose >= / side-effect checks to exact assertEq / precise values (incl. diamondCutCount==2 exact; enum action via uint8), added/expanded Behavior_IFacet calls (expect/hasValid/areValid for facetName/interfaces/funcs + metadata consistency on base facets; added loupe funcs expect+hasValid), added dedicated LR-7 declaration tests for facets (via Behavior) and packages (exact packageName/facet*/diamondConfig/calcSalt/processArgs), added package metadata assertions. Added NatSpec + // tag::[] / @custom:selector (using ONLY central values for IDiamondFactoryPackage fns like 0xabc8b346 packageName, 0x2ea80826 facetInterfaces etc + IFacet overlap; plus computed selectors for public test fns) on test contracts (MinimalTestPackage, StorageCheckPackage, main Test, LR7 + key init/decl tests). Used assertNotEq for diff addresses. No other files edited. Targeted forge test + build (via inspect) verification done.

**Detailed Gaps (addressed):**
- LR-7: Ensure full initialization (no address(0) facets in pkgs), exact value assertions (not just 'changed'), use of Behavior libs, declaration tests for facets/packages.
- LR-1: Add NatSpec to test code where public.

**Specific Actions Taken to Close Gaps:**
1. Enhanced setUp() with explicit full init comments, vm.label (AGENTS), real non-0 facets always, Behavior_IFacet.expect_* upfront for base facets before any assertions. Expanded with loupe funcs expect using 4 selectors.
2. Replaced loose assertGe / "changed" style with assertEq(exact counts e.g. 3 facets post removal, 1 iface, 4 loupe selectors; diamondCutCount exactly 2), assertEq(exact strings/bytes/keccak for pkg metadata, salts, storage deltas in existing). Fixed enum assertEq(cuts.action) -> uint8 cast for compile/exact.
3. Added/expanded Behavior_IFacet usage: expect/hasValid for facetName/interfaces/funcs + isValid_facetMetadata_consistency on ERC165Facet/DiamondLoupeFacet. Added hasValid calls for loupe interfaces/funcs in LR7 decl test.
4. Added facet declaration test (test_LR7_baseFacets_declaration_viaBehavior) + full package declaration test (test_LR7_packageDeclarations_exact) covering all required LR-7 package surfaces (packageName, facetAddresses/Interfaces/Cuts, diamondConfig, calcSalt determinism, processArgs).
5. For NatSpec: added/expanded on inner test pkgs (Minimal/StorageCheck) and main contract + new public test fns using // tag::Name(params)[] // end + @custom:signature/@custom:selector from CENTRALLY_COMPUTED_NATSPEC_VALUES.md ONLY for core (IDiamondFactoryPackage: 0xabc8b346,0x52ef6b2c,0x2ea80826,0xf45469e7,0xa4b3ad35,0x65d375b3,0xd82be56e,0x87c3adb3,0xa9089235,0x870d4838,0x70068fcf ; IFacet overlap). Also added for main Test contract + computed selectors for test fns (e.g. 0x691ab102, 0x62950383, 0x58c14f2b, 0x8fcd101a). (follow-up central pass for pure-tests.)
6. Added vm.labels + comments referencing CraneTest/Behavior/Crane patterns per AGENTS + crane-testing skill + PRD LR-7. Used assertNotEq for address diffs (exact). Exact asserts + preview not applicable (no previews here) but determinism and full delegatecall init covered. Ran targeted forge test + build (inspect) .
7. Ensured no address(0); full package inits upfront in setUp. Updated package decl test for exact action enum.

**NatSpec Symbols Tagged (with values):**

From CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY these for known symbols):
- IDiamondFactoryPackage packageName() : 0xabc8b346
- facetAddresses() : 0x52ef6b2c
- facetInterfaces() : 0x2ea80826
- packageMetadata() : 0xf45469e7
- facetCuts() : 0xa4b3ad35
- diamondConfig() : 0x65d375b3
- calcSalt(bytes) : 0xd82be56e
- processArgs(bytes) : 0x87c3adb3
- updatePkg(address,bytes) : 0xa9089235
- initAccount(bytes) : 0x870d4838
- postDeploy(address) : 0x70068fcf
- IFacet selectors referenced via Behavior (0x5b6f4d01 etc)

Test-specific (per prior example pattern; for central follow-up):
- DiamondPackageCallBackFactory_Test
- MinimalTestPackage
- StorageCheckPackage
- test_LR7_baseFacets_declaration_viaBehavior() : 0x691ab102
- test_LR7_packageDeclarations_exact() : 0x62950383
- test_deploy_baseFacetsInstalled() : 0x58c14f2b
- test_deploy_initAccount_viaDelgatecall() : 0x8fcd101a
- (existing test fns enhanced with NatSpec where public; selectors from cast sig, not added to CENTRALLY)

(No events/errors declared in test surface.)

**Testing Gaps (LR-7 specific if applicable) - Closed for file:**
- Full initialization of subjects: setUp deploys real facets+pkgs upfront (no address(0), no lazy inside tests). Packages wired with non-0.
- Exact assertions vs side-effect: changed all loose (assertGe->assertEq(diamondCutCount,2), loose != ->assertNotEq) to assertEq for counts (incl 3 facets, 2 cuts), names, salts (exact keccak), lengths, config structs, enum actions (uint8).
- Use of Behavior_IFacet: added/expanded for base facet declaration (mandatory per PRD + crane-testing). Includes expect on setup for funcs, hasValid/isValid in decl tests for erc165+loupe.
- Declaration tests for facets and packages: new dedicated LR-7 tests using Behavior + direct exact metadata (packageName, facet*, diamondConfig, calcSalt, processArgs). (Note: Behavior_IDiamondFactoryPackage does not exist yet per CRANE-250; used direct exact + central refs for pkg surfaces.)
- Correct TestBase/CraneTest: documented + follows init patterns (full bootstrap before asserts; labels); direct Test inherit intentional for factory SUT itself (consistent with sibling factory tests and IFacet_Behavior_Test note). Per PRD/AGENTS patterns.
- Full DFPkg lifecycle + initAccount delegatecall + storage isolation + determinism assertions pre-existing + enhanced with exacts.
- NatSpec + tags on test public code (added to more fns).
- Ran targeted forge test cmds + forge build/inspect verification (no other files edited).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- Used ONLY CENTRALLY_COMPUTED_NATSPEC_VALUES.md + PRD LR sections + AGENTS.md + source + crane-testing skill for patterns/values. Central values ONLY for IDiamondFactoryPackage/IFacet symbols; test fn selectors computed via cast but documented only in this report.
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.
- Strict read order followed: 1.gap report, 2.central, 3.PRD (LR-7), 4.AGENTS.md, 5.source test + factory.

**Status:** [x] Gaps closed (refined in this pass: exact counts/assertNotEq/enum, expanded Behavior_IFacet, more NatSpec tags+selectors on public tests, build/test cmds executed).
**Priority:** High (core framework files)
