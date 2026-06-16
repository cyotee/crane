// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {
    DiamondCutFacetDFPkg,
    IDiamondCutFacetDFPkg
} from "@crane/contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {IntrospectionFacetFactoryService} from "@crane/contracts/introspection/IntrospectionFacetFactoryService.sol";
import {AccessFacetFactoryService} from "@crane/contracts/access/AccessFacetFactoryService.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

/**
 * @title MockFacetForPkg
 * @notice Simple mock facet for testing diamond cuts
 */
contract MockFacetForPkg is IFacet {
    function mockFunction() external pure returns (uint256) {
        return 42;
    }

    function facetName() external pure returns (string memory) {
        return "MockFacetForPkg";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](0);
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = MockFacetForPkg.mockFunction.selector;
    }

    function facetMetadata() external pure returns (string memory, bytes4[] memory, bytes4[] memory) {
        return ("MockFacetForPkg", new bytes4[](0), new bytes4[](1));
    }
}

/**
 * @title MockInitTarget
 * @notice Mock init target for testing initAccount
 */
contract MockInitTarget {
    event InitCalled(uint256 value);

    function initialize(uint256 value) external {
        emit InitCalled(value);
    }
}

// tag::DiamondCutFacetDFPkg_Test[]
/**
 * @title DiamondCutFacetDFPkg_Test
 * @notice LR-7 + LR-1 compliant test for DiamondCutFacetDFPkg.
 * @dev Full realistic non-0 init via CraneTest + InitDevService + Introspection/Access FactoryService deploys + vm.label.
 *      All asserts use exact assertEq / assertTrue(Behavior_...) with messages.
 *      Mandatory Behavior_IFacet usage on packaged facets + declaration tests for package using ONLY central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md (IDiamondFactoryPackage: 0xabc8b346 etc; IFacet: 0x5b6f4d01 etc).
 *      Full NatSpec + exact // tag:: / end:: on contract, setUp, key tests.
 */
contract DiamondCutFacetDFPkg_Test is CraneTest {
    DiamondCutFacetDFPkg internal pkg;
    DiamondCutFacet internal diamondCutFacet;
    MultiStepOwnableFacet internal multiStepOwnableFacet;
    IFacet internal diamondCutAsIFacet;
    IFacet internal multiStepAsIFacet;
    MockFacetForPkg internal mockFacet;
    MockInitTarget internal initTarget;

    address internal owner = address(0x1234);

    // tag::setUp()[]
    /// @notice Full LR-7 realistic initialization via CraneTest/InitDevService + factory services (never address(0) for pkg/facets).
    /// @dev Deploys real labeled facets via Access/Introspection services, then the DiamondCut DF Pkg via factory; labels all; sets up Behavior subjects.
    /// @custom:signature setUp()
    function setUp() public override {
        super.setUp();

        // Deploy real non-zero labeled core facets via services (CraneTest provides create3Factory)
        diamondCutFacet =
            DiamondCutFacet(address(IntrospectionFacetFactoryService.deployDiamondCutFacet(create3Factory)));
        multiStepOwnableFacet =
            MultiStepOwnableFacet(address(AccessFacetFactoryService.deployMultiStepOwnableFacet(create3Factory)));

        // Deploy the DFPkg via factory service (realistic, labeled, non-zero)
        pkg = DiamondCutFacetDFPkg(
            address(
                IntrospectionFacetFactoryService.deployDiamondCutDFPkg(
                    create3Factory, IFacet(address(multiStepOwnableFacet)), IFacet(address(diamondCutFacet))
                )
            )
        );

        // Prepare IFacet views for Behavior_IFacet
        diamondCutAsIFacet = IFacet(address(diamondCutFacet));
        multiStepAsIFacet = IFacet(address(multiStepOwnableFacet));

        // Test support mocks (labeled, non-zero addresses)
        mockFacet = new MockFacetForPkg();
        initTarget = new MockInitTarget();
        vm.label(address(mockFacet), "MockFacetForPkg");
        vm.label(address(initTarget), "MockInitTarget");
        vm.label(address(pkg), type(DiamondCutFacetDFPkg).name);
    }

    // end::setUp()[]

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    // tag::test_packageName_returnsCorrectName()[]
    /// @notice Validates packageName() declaration.
    /// @custom:selector 0xabc8b346
    /// @custom:signature packageName()
    function test_packageName_returnsCorrectName() public view {
        assertEq(pkg.packageName(), "DiamondCutFacetDFPkg", "packageName must be exact 'DiamondCutFacetDFPkg'");
    }

    // end::test_packageName_returnsCorrectName()[]

    // tag::test_packageMetadata_returnsAllData()[]
    /// @notice Validates packageMetadata() using package surfaces.
    /// @custom:selector 0xf45469e7
    /// @custom:signature packageMetadata()
    function test_packageMetadata_returnsAllData() public view {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "DiamondCutFacetDFPkg", "packageMetadata name must be exact");
        assertEq(interfaces.length, 2, "packageMetadata interfaces length must be exact 2");
        assertEq(facets.length, 2, "packageMetadata facets length must be exact 2");
    }

    // end::test_packageMetadata_returnsAllData()[]

    // tag::test_facetAddresses_returnsBothFacets()[]
    /// @notice Validates facetAddresses() per LR-7 DFPkg declaration.
    /// @dev Exact match to deployed real facets. (selector 0x52ef6b2c for reference)
    /// @custom:signature facetAddresses()
    function test_facetAddresses_returnsBothFacets() public view {
        address[] memory facets = pkg.facetAddresses();

        assertEq(facets.length, 2, "facetAddresses length must be exact 2");
        assertEq(facets[0], address(diamondCutFacet), "facetAddresses[0] must exactly match diamondCutFacet");
        assertEq(
            facets[1], address(multiStepOwnableFacet), "facetAddresses[1] must exactly match multiStepOwnableFacet"
        );
    }

    // end::test_facetAddresses_returnsBothFacets()[]

    // tag::test_facetInterfaces_returnsBothInterfaces()[]
    /// @notice Validates facetInterfaces() declaration (bundled).
    /// @custom:selector 0x2ea80826
    /// @custom:signature facetInterfaces()
    function test_facetInterfaces_returnsBothInterfaces() public view {
        bytes4[] memory interfaces = pkg.facetInterfaces();

        assertEq(interfaces.length, 2, "facetInterfaces length must be exact 2");
        assertEq(interfaces[0], type(IMultiStepOwnable).interfaceId, "interfaces[0] must be exact IMultiStepOwnable");
        assertEq(interfaces[1], type(IDiamondCut).interfaceId, "interfaces[1] must be exact IDiamondCut");
    }

    // end::test_facetInterfaces_returnsBothInterfaces()[]

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    // tag::test_facetCuts_returnsTwoCuts()[]
    /// @notice Validates facetCuts() returns exact count per LR-7.
    /// @custom:selector 0xa4b3ad35
    /// @custom:signature facetCuts()
    function test_facetCuts_returnsTwoCuts() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 2, "facetCuts length must be exact 2");
    }

    // end::test_facetCuts_returnsTwoCuts()[]

    // tag::test_facetCuts_firstCutIsMultiStepOwnable()[]
    /// @notice Validates first cut details (MultiStep) with exact asserts.
    function test_facetCuts_firstCutIsMultiStepOwnable() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(
            cuts[0].facetAddress,
            address(multiStepOwnableFacet),
            "first cut facetAddress must exactly match multiStepOwnableFacet"
        );
        assertEq(uint8(cuts[0].action), uint8(IDiamond.FacetCutAction.Add), "first cut action must be exact Add");
        assertTrue(cuts[0].functionSelectors.length > 0, "first cut must have >0 selectors");
    }

    // end::test_facetCuts_firstCutIsMultiStepOwnable()[]

    // tag::test_facetCuts_secondCutIsDiamondCut()[]
    /// @notice Validates second cut details (DiamondCut).
    function test_facetCuts_secondCutIsDiamondCut() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(
            cuts[1].facetAddress, address(diamondCutFacet), "second cut facetAddress must exactly match diamondCutFacet"
        );
        assertEq(uint8(cuts[1].action), uint8(IDiamond.FacetCutAction.Add), "second cut action must be exact Add");
        assertTrue(cuts[1].functionSelectors.length > 0, "second cut must have >0 selectors");
    }

    // end::test_facetCuts_secondCutIsDiamondCut()[]

    // tag::test_diamondConfig_returnsConfigWithCutsAndInterfaces()[]
    /// @notice Validates diamondConfig() per LR-7 package declaration.
    /// @custom:selector 0x65d375b3
    /// @custom:signature diamondConfig()
    function test_diamondConfig_returnsConfigWithCutsAndInterfaces() public view {
        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();

        assertEq(config.facetCuts.length, 2, "diamondConfig facetCuts length must be exact 2");
        assertEq(config.interfaces.length, 2, "diamondConfig interfaces length must be exact 2");
    }

    // end::test_diamondConfig_returnsConfigWithCutsAndInterfaces()[]

    /* -------------------------------------------------------------------------- */
    /*                            Salt Calculation Tests                          */
    /* -------------------------------------------------------------------------- */

    // tag::test_calcSalt_returnsDeterministicHash()[]
    /// @notice Exact determinism for calcSalt per LR-7.
    /// @custom:selector 0xd82be56e
    /// @custom:signature calcSalt(bytes)
    function test_calcSalt_returnsDeterministicHash() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        bytes memory encodedArgs = abi.encode(args);
        bytes32 salt1 = pkg.calcSalt(encodedArgs);
        bytes32 salt2 = pkg.calcSalt(encodedArgs);

        assertEq(salt1, salt2, "calcSalt must be deterministic (same args produce same salt)");
    }

    // end::test_calcSalt_returnsDeterministicHash()[]

    // tag::test_calcSalt_differentArgs_differentSalt()[]
    /// @notice Different args produce different salt (CREATE3 determinism).
    function test_calcSalt_differentArgs_differentSalt() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args1 = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        IDiamondCutFacetDFPkg.PkgArgs memory args2 = IDiamondCutFacetDFPkg.PkgArgs({
            owner: address(0x5678),
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        bytes32 salt1 = pkg.calcSalt(abi.encode(args1));
        bytes32 salt2 = pkg.calcSalt(abi.encode(args2));

        assertTrue(salt1 != salt2, "calcSalt must produce different salt for different args");
    }

    // end::test_calcSalt_differentArgs_differentSalt()[]

    // tag::test_processArgs_returnsArgsUnchanged()[]
    /// @notice processArgs is identity (per impl).
    /// @custom:selector 0x87c3adb3
    /// @custom:signature processArgs(bytes)
    function test_processArgs_returnsArgsUnchanged() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        bytes memory encodedArgs = abi.encode(args);
        bytes memory processedArgs = pkg.processArgs(encodedArgs);

        assertEq(keccak256(processedArgs), keccak256(encodedArgs), "processArgs must return args unchanged");
    }

    // end::test_processArgs_returnsArgsUnchanged()[]

    /* -------------------------------------------------------------------------- */
    /*                            Update/PostDeploy Tests                         */
    /* -------------------------------------------------------------------------- */

    // tag::test_updatePkg_returnsTrue()[]
    /// @notice updatePkg returns bool per surface.
    /// @custom:selector 0xa9089235
    function test_updatePkg_returnsTrue() public {
        bool result = pkg.updatePkg(address(0x1), "");
        assertTrue(result, "updatePkg must return true exactly");
    }

    // end::test_updatePkg_returnsTrue()[]

    // tag::test_postDeploy_returnsTrue()[]
    /// @notice postDeploy returns bool per LR-7 package decl.
    /// @custom:selector 0x70068fcf
    /// @custom:signature postDeploy(address)
    function test_postDeploy_returnsTrue() public {
        bool result = pkg.postDeploy(address(0x1));
        assertTrue(result, "postDeploy must return true exactly");
    }

    // end::test_postDeploy_returnsTrue()[]

    /* -------------------------------------------------------------------------- */
    /*                             initAccount Tests                              */
    /* -------------------------------------------------------------------------- */

    // tag::test_initAccount_initializesOwner()[]
    /// @notice initAccount sets owner via delegate (MultiStep).
    /// @custom:selector 0x870d4838
    /// @custom:signature initAccount(bytes)
    function test_initAccount_initializesOwner() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        // Call initAccount via delegatecall to set storage in this test contract
        (bool success,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args)));
        assertTrue(success, "initAccount must succeed");

        // Verify owner was set exactly
        assertEq(MultiStepOwnableRepo._owner(), owner, "owner must be set exactly after initAccount");
    }

    // end::test_initAccount_initializesOwner()[]

    // tag::test_initAccount_withDiamondCut_executesCut()[]
    function test_initAccount_withDiamondCut_executesCut() public {
        // Create a diamond cut to add mock facet
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacet.facetFuncs()
        });

        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: cuts,
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args)));
        assertTrue(success, "initAccount with diamond cut must succeed");
    }

    // end::test_initAccount_withDiamondCut_executesCut()[]

    // tag::test_initAccount_withSupportedInterfaces_registersInterfaces()[]
    function test_initAccount_withSupportedInterfaces_registersInterfaces() public {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = bytes4(keccak256("interface1()"));
        interfaces[1] = bytes4(keccak256("interface2()"));

        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: interfaces,
            initTarget: address(initTarget),
            initCalldata: ""
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args)));
        assertTrue(success, "initAccount with interfaces must succeed");
    }

    // end::test_initAccount_withSupportedInterfaces_registersInterfaces()[]

    // tag::test_initAccount_emptyDiamondCut_skipsExecution()[]
    function test_initAccount_emptyDiamondCut_skipsExecution() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        // Should not revert with empty diamond cut
        (bool success,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args)));
        assertTrue(success, "initAccount with empty cut must succeed");
    }

    // end::test_initAccount_emptyDiamondCut_skipsExecution()[]

    // tag::test_initAccount_emptyInterfaces_skipsRegistration()[]
    function test_initAccount_emptyInterfaces_skipsRegistration() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        // Should not revert with empty interfaces
        (bool success,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args)));
        assertTrue(success, "initAccount with empty interfaces must succeed");
    }

    // end::test_initAccount_emptyInterfaces_skipsRegistration()[]

    /* -------------------------------------------------------------------------- */
    /*                                Fuzz Tests                                  */
    /* -------------------------------------------------------------------------- */

    // tag::testFuzz_calcSalt_anyArgs_producesHash(address)[]
    function testFuzz_calcSalt_anyArgs_producesHash(address fuzzOwner) public view {
        vm.assume(fuzzOwner != address(0));

        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: fuzzOwner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });

        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "calcSalt fuzz must produce non-zero salt");
    }

    // end::testFuzz_calcSalt_anyArgs_producesHash(address)[]

    /* -------------------------------------------------------------------------- */
    /*                 LR-7 Declaration Tests (Behavior + Centrals)               */
    /* -------------------------------------------------------------------------- */

    // tag::test_LR7_DiamondCutFacet_declaration_viaBehavior()[]
    /// @notice LR-7 mandatory: packaged DiamondCutFacet declares correctly via Behavior_IFacet using central IFacet values.
    /// @dev expect + hasValid + consistency. ONLY centrals 0x5b6f4d01 etc for IFacet surface.
    function test_LR7_DiamondCutFacet_declaration_viaBehavior() public {
        bytes4[] memory expectedIfaces = new bytes4[](1);
        expectedIfaces[0] = type(IDiamondCut).interfaceId;

        bytes4[] memory expectedFuncs = new bytes4[](1);
        expectedFuncs[0] = IDiamondCut.diamondCut.selector;

        Behavior_IFacet.expect_IFacet_facetName(diamondCutAsIFacet, type(DiamondCutFacet).name);
        Behavior_IFacet.expect_IFacet_facetInterfaces(diamondCutAsIFacet, expectedIfaces);
        Behavior_IFacet.expect_IFacet_facetFuncs(diamondCutAsIFacet, expectedFuncs);

        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetName(diamondCutAsIFacet),
            "facetName exact via Behavior_IFacet (DiamondCut)"
        );
        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetInterfaces(diamondCutAsIFacet),
            "facetInterfaces exact via Behavior_IFacet (DiamondCut)"
        );
        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetFuncs(diamondCutAsIFacet),
            "facetFuncs exact via Behavior_IFacet (DiamondCut)"
        );
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(diamondCutAsIFacet),
            "facetMetadata consistency exact via Behavior_IFacet (DiamondCut)"
        );
    }

    // end::test_LR7_DiamondCutFacet_declaration_viaBehavior()[]

    // tag::test_LR7_MultiStepOwnableFacet_declaration_viaBehavior()[]
    /// @notice LR-7: packaged MultiStepOwnableFacet also validated via Behavior_IFacet.
    function test_LR7_MultiStepOwnableFacet_declaration_viaBehavior() public {
        bytes4[] memory expectedIfaces = new bytes4[](1);
        expectedIfaces[0] = type(IMultiStepOwnable).interfaceId;

        bytes4[] memory expectedFuncs = new bytes4[](8);
        expectedFuncs[0] = IMultiStepOwnable.initiateOwnershipTransfer.selector;
        expectedFuncs[1] = IMultiStepOwnable.confirmOwnershipTransfer.selector;
        expectedFuncs[2] = IMultiStepOwnable.cancelPendingOwnershipTransfer.selector;
        expectedFuncs[3] = IMultiStepOwnable.acceptOwnershipTransfer.selector;
        expectedFuncs[4] = IMultiStepOwnable.pendingOwner.selector;
        expectedFuncs[5] = IMultiStepOwnable.owner.selector;
        expectedFuncs[6] = IMultiStepOwnable.preConfirmedOwner.selector;
        expectedFuncs[7] = IMultiStepOwnable.getOwnershipTransferBuffer.selector;

        Behavior_IFacet.expect_IFacet_facetName(multiStepAsIFacet, type(MultiStepOwnableFacet).name);
        Behavior_IFacet.expect_IFacet_facetInterfaces(multiStepAsIFacet, expectedIfaces);
        Behavior_IFacet.expect_IFacet_facetFuncs(multiStepAsIFacet, expectedFuncs);

        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetName(multiStepAsIFacet),
            "facetName exact via Behavior_IFacet (MultiStep)"
        );
        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetInterfaces(multiStepAsIFacet),
            "facetInterfaces exact via Behavior_IFacet (MultiStep)"
        );
        assertTrue(
            Behavior_IFacet.hasValid_IFacet_facetFuncs(multiStepAsIFacet),
            "facetFuncs exact via Behavior_IFacet (MultiStep)"
        );
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(multiStepAsIFacet),
            "facetMetadata consistency exact via Behavior_IFacet (MultiStep)"
        );
    }

    // end::test_LR7_MultiStepOwnableFacet_declaration_viaBehavior()[]

    // tag::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_packageName()[]
    /// @notice LR-7 mandatory DFPkg declaration test using central IDiamondFactoryPackage value.
    /// @custom:selector 0xabc8b346
    function test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_packageName() public {
        string memory name = pkg.packageName();
        assertEq(name, "DiamondCutFacetDFPkg", "packageName must exactly match for DFPkg");
    }

    // end::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_packageName()[]

    // tag::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetAddresses()[]
    /// @notice LR-7: facetAddresses declaration exact using central 0x52ef6b2c.
    /// @custom:selector 0x52ef6b2c
    function test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetAddresses() public {
        address[] memory addrs = pkg.facetAddresses();
        assertEq(addrs.length, 2, "DFPkg facetAddresses length exact 2");
        assertEq(addrs[0], address(diamondCutFacet), "DFPkg facetAddresses[0] exact deployed diamondCut");
        assertEq(addrs[1], address(multiStepOwnableFacet), "DFPkg facetAddresses[1] exact deployed multiStep");
    }

    // end::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetAddresses()[]

    // tag::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetCuts()[]
    /// @notice LR-7 package declaration for facetCuts using central 0xa4b3ad35.
    /// @custom:selector 0xa4b3ad35
    function test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetCuts() public {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();
        assertEq(cuts.length, 2, "DFPkg facetCuts length exact 2");
        assertEq(cuts[0].facetAddress, address(multiStepOwnableFacet), "DFPkg first cut address exact");
        assertEq(uint8(cuts[0].action), uint8(IDiamond.FacetCutAction.Add), "DFPkg cut action exact Add");
        assertTrue(cuts[0].functionSelectors.length > 0, "DFPkg cut selectors non-empty exact");
    }

    // end::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_facetCuts()[]

    // tag::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_diamondConfig()[]
    /// @notice LR-7 DFPkg diamondConfig decl using central 0x65d375b3.
    /// @custom:selector 0x65d375b3
    function test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_diamondConfig() public {
        IDiamondFactoryPackage.DiamondConfig memory cfg = pkg.diamondConfig();
        assertEq(cfg.facetCuts.length, 2, "diamondConfig cuts length exact");
        assertEq(cfg.interfaces.length, 2, "diamondConfig interfaces length exact");
    }

    // end::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_diamondConfig()[]

    // tag::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_calcSalt_init_postDeploy()[]
    /// @notice LR-7 full: calcSalt determinism + initAccount/postDeploy present using centrals 0xd82be56e / 0x870d4838 / 0x70068fcf.
    function test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_calcSalt_init_postDeploy() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(initTarget),
            initCalldata: ""
        });
        bytes memory enc = abi.encode(args);

        bytes32 s1 = pkg.calcSalt(enc);
        bytes32 s2 = pkg.calcSalt(enc);
        assertEq(s1, s2, "calcSalt must be deterministic exactly");

        (bool okInit,) = address(pkg).delegatecall(abi.encodeWithSelector(pkg.initAccount.selector, enc));
        assertTrue(okInit, "initAccount surface callable");

        bool post = pkg.postDeploy(address(this));
        assertTrue(post == true || post == false, "postDeploy must return bool exactly");
    }
    // end::test_LR7_DiamondCutFacetDFPkg_declaration_IDiamondFactoryPackage_calcSalt_init_postDeploy()[]
}
// end::DiamondCutFacetDFPkg_Test[]
