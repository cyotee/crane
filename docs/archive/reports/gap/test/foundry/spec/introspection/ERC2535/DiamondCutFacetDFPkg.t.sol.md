# Gap Report for: test/foundry/spec/introspection/ERC2535/DiamondCutFacetDFPkg.t.sol

**File Type:** DFPkg Test (core diamond cut package)

**Primary Affected Requirements (from PRD):**
LR-7 + LR-1

**Current State Summary:**
LR-7/LR-1 CLOSED for this DFPkg test file. Strict process followed: read its gap, CENTRALLY_COMPUTED_NATSPEC_VALUES.md, PRD LR-1+LR-7, AGENTS.md (crane-testing + NatSpec/tests), then source. ONLY edited: this .t.sol + its gap + GAP_REPORT.md. Used ONLY centrals for @custom on IFacet/IDiamondFactoryPackage.

**Actions Performed (LR-7 + LR-1):**
- Switched to full realistic non-0 init: inherits CraneTest (super.setUp via InitDevService), used IntrospectionFacetFactoryService.deployDiamondCutDFPkg + AccessFacetFactoryService.deployMultiStepOwnableFacet + deployDiamondCutFacet (create3Factory) + vm.label on all (pkg/facets/mocks never address(0)).
- All asserts converted to exact: assertEq(actual, expected, "must be exact ... msg"), assertTrue( cond , "msg" ); no loose != / no-msg.
- Mandatory Behavior_IFacet: added on packaged facets (DiamondCut + MultiStepOwnable) with expect_IFacet_* + hasValid_* + isValid_facetMetadata_consistency.
- Added full LR-7 DFPkg declaration tests exercising packageName/facetInterfaces/facetAddresses/facetCuts/diamondConfig/calcSalt+determinism/initAccount/postDeploy using ONLY central values (0xabc8b346 packageName, 0x2ea80826 facetInterfaces, 0x52ef6b2c facetAddresses, 0xa4b3ad35 facetCuts, 0x65d375b3 diamondConfig, 0xd82be56e calcSalt, 0x870d4838 initAccount, 0x70068fcf postDeploy, 0x87c3adb3 processArgs, 0xa9089235 updatePkg from CENTRALLY... + IFacet 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75).
- Full NatSpec + exact // tag::Name[] / // end:: (hyphen overloads where appl) on contract, setUp, all key tests (incl dedicated LR7 decl + Behavior tests).
- Used ONLY centrals for @custom:selector/signature on IDiamondFactoryPackage and IFacet surfaces in test NatSpec.
- Fixed initTarget to non-0 labeled; initAccount tests use delegate on real pkg; salt tests exact determinism.

**NatSpec Symbols Tagged (with centrals):**
- DiamondCutFacetDFPkg_Test, setUp(), test_packageName_..., test_...facetAddresses, test_facetInterfaces, test_facetCuts_..., test_diamondConfig_..., test_calcSalt_..., test_processArgs..., test_postDeploy..., test_initAccount_..., testFuzz..., + LR7 decl tests (test_LR7_*_viaBehavior, test_LR7_*_IDiamondFactoryPackage_*)
- @custom:selector ONLY from centrals for packageName(0xabc8b346), facet*(0x2ea80826/0x52ef6b2c/0xa4b3ad35), diamondConfig(0x65d375b3), calcSalt(0xd82be56e), initAccount(0x870d4838), postDeploy(0x70068fcf) etc. + IFacet on Behavior paths.

**Targeted Verification Performed (only allowed cmds):**
- forge test --list --match-path 'test/foundry/spec/introspection/ERC2535/DiamondCutFacetDFPkg.t.sol' (and --match-contract filter)
- forge build --skip test --quiet
- forge inspect contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol:DiamondCutFacetDFPkg (abi|methodIdentifiers) -- matched centrals exactly: packageName abc8b346, facetAddresses 52ef6b2c, facetCuts a4b3ad35, diamondConfig 65d375b3, calcSalt d82be56e, facetInterfaces 2ea80826, initAccount 870d4838, postDeploy 70068fcf, process 87c3adb3, update a9089235
- forge inspect .../DiamondCutFacet.sol:DiamondCutFacet methodIdentifiers (facetName 5b6f4d01 etc match centrals)

See updated source for exact tags + Behavior + CraneTest init. Only 3 files edited.

**Status:** CLOSED (LR-7/LR-1 for DFPkg test; advances core introspection DFPkg coverage).
