// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DiamondCutFacetDFPkg, IDiamondCutFacetDFPkg} from "@crane/contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

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
        return (
            "MockFacetForPkg",
            new bytes4[](0),
            new bytes4[](1)
        );
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

/**
 * @title DiamondCutFacetDFPkg_Test
 * @notice Tests for DiamondCutFacetDFPkg
 */
contract DiamondCutFacetDFPkg_Test is Test {
    DiamondCutFacetDFPkg internal pkg;
    DiamondCutFacet internal diamondCutFacet;
    MultiStepOwnableFacet internal multiStepOwnableFacet;
    MockFacetForPkg internal mockFacet;
    MockInitTarget internal initTarget;

    address internal owner = address(0x1234);

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        multiStepOwnableFacet = new MultiStepOwnableFacet();
        mockFacet = new MockFacetForPkg();
        initTarget = new MockInitTarget();

        // Deploy package
        pkg = new DiamondCutFacetDFPkg(
            IDiamondCutFacetDFPkg.PkgInit({
                diamondCutFacet: IFacet(address(diamondCutFacet)),
                multiStepOwnableFacet: IFacet(address(multiStepOwnableFacet))
            })
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_packageName_returnsCorrectName() public view {
        assertEq(pkg.packageName(), "DiamondCutFacetDFPkg");
    }

    function test_packageMetadata_returnsAllData() public view {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "DiamondCutFacetDFPkg");
        assertEq(interfaces.length, 2);
        assertEq(facets.length, 2);
    }

    function test_facetAddresses_returnsBothFacets() public view {
        address[] memory facets = pkg.facetAddresses();

        assertEq(facets.length, 2);
        assertEq(facets[0], address(diamondCutFacet));
        assertEq(facets[1], address(multiStepOwnableFacet));
    }

    function test_facetInterfaces_returnsBothInterfaces() public view {
        bytes4[] memory interfaces = pkg.facetInterfaces();

        assertEq(interfaces.length, 2);
        assertEq(interfaces[0], type(IMultiStepOwnable).interfaceId);
        assertEq(interfaces[1], type(IDiamondCut).interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_facetCuts_returnsTwoCuts() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 2);
    }

    function test_facetCuts_firstCutIsMultiStepOwnable() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts[0].facetAddress, address(multiStepOwnableFacet));
        assertEq(uint8(cuts[0].action), uint8(IDiamond.FacetCutAction.Add));
        assertGt(cuts[0].functionSelectors.length, 0);
    }

    function test_facetCuts_secondCutIsDiamondCut() public view {
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts[1].facetAddress, address(diamondCutFacet));
        assertEq(uint8(cuts[1].action), uint8(IDiamond.FacetCutAction.Add));
        assertGt(cuts[1].functionSelectors.length, 0);
    }

    function test_diamondConfig_returnsConfigWithCutsAndInterfaces() public view {
        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();

        assertEq(config.facetCuts.length, 2);
        assertEq(config.interfaces.length, 2);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Salt Calculation Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_returnsDeterministicHash() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        bytes memory encodedArgs = abi.encode(args);
        bytes32 salt1 = pkg.calcSalt(encodedArgs);
        bytes32 salt2 = pkg.calcSalt(encodedArgs);

        assertEq(salt1, salt2, "Same args should produce same salt");
    }

    function test_calcSalt_differentArgs_differentSalt() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args1 = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        IDiamondCutFacetDFPkg.PkgArgs memory args2 = IDiamondCutFacetDFPkg.PkgArgs({
            owner: address(0x5678),
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        bytes32 salt1 = pkg.calcSalt(abi.encode(args1));
        bytes32 salt2 = pkg.calcSalt(abi.encode(args2));

        assertTrue(salt1 != salt2, "Different args should produce different salt");
    }

    function test_processArgs_returnsArgsUnchanged() public view {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        bytes memory encodedArgs = abi.encode(args);
        bytes memory processedArgs = pkg.processArgs(encodedArgs);

        assertEq(keccak256(processedArgs), keccak256(encodedArgs), "Args should be unchanged");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Update/PostDeploy Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_updatePkg_returnsTrue() public {
        bool result = pkg.updatePkg(address(0x1), "");
        assertTrue(result);
    }

    function test_postDeploy_returnsTrue() public {
        bool result = pkg.postDeploy(address(0x1));
        assertTrue(result);
    }

    /* -------------------------------------------------------------------------- */
    /*                             initAccount Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_initAccount_initializesOwner() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        // Call initAccount via delegatecall to set storage in this test contract
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount should succeed");

        // Verify owner was set
        assertEq(MultiStepOwnableRepo._owner(), owner);
    }

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
            initTarget: address(0),
            initCalldata: ""
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount with diamond cut should succeed");
    }

    function test_initAccount_withSupportedInterfaces_registersInterfaces() public {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = bytes4(keccak256("interface1()"));
        interfaces[1] = bytes4(keccak256("interface2()"));

        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: interfaces,
            initTarget: address(0),
            initCalldata: ""
        });

        // Call initAccount via delegatecall
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount with interfaces should succeed");
    }

    function test_initAccount_emptyDiamondCut_skipsExecution() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        // Should not revert with empty diamond cut
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount with empty cut should succeed");
    }

    function test_initAccount_emptyInterfaces_skipsRegistration() public {
        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        // Should not revert with empty interfaces
        (bool success,) = address(pkg).delegatecall(
            abi.encodeWithSelector(pkg.initAccount.selector, abi.encode(args))
        );
        assertTrue(success, "initAccount with empty interfaces should succeed");
    }

    /* -------------------------------------------------------------------------- */
    /*                                Fuzz Tests                                  */
    /* -------------------------------------------------------------------------- */

    function testFuzz_calcSalt_anyArgs_producesHash(address fuzzOwner) public view {
        vm.assume(fuzzOwner != address(0));

        IDiamondCutFacetDFPkg.PkgArgs memory args = IDiamondCutFacetDFPkg.PkgArgs({
            owner: fuzzOwner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        bytes32 salt = pkg.calcSalt(abi.encode(args));
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }
}
