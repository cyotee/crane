// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {
    CowRouterDFPkg,
    ICowRouterDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg.sol";
import {CowRouterRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterRepo.sol";

// Mock Facet implementing IFacet for testing
contract MockFacet is IFacet {
    bytes4[] private _funcs;
    bytes4[] private _interfaces;
    string private _name;

    constructor(string memory name_, bytes4[] memory funcs_, bytes4[] memory interfaces_) {
        _name = name_;
        _funcs = funcs_;
        _interfaces = interfaces_;
    }

    function facetName() external view override returns (string memory) { return _name; }
    function facetInterfaces() external view override returns (bytes4[] memory) { return _interfaces; }
    function facetFuncs() external view override returns (bytes4[] memory) { return _funcs; }
    function facetMetadata() external view override returns (string memory, bytes4[] memory, bytes4[] memory) {
        return (_name, _interfaces, _funcs);
    }
}

/**
 * @title CowRouterDFPkg_Test
 * @notice Tests for CowRouterDFPkg Diamond Factory Package.
 * @dev Tests verify:
 *  - Package metadata correctness
 *  - Salt calculation determinism
 *  - Fee percentage validation
 *  - Fee sweeper validation
 */
contract CowRouterDFPkg_Test is Test {
    CowRouterDFPkg internal pkg;

    // Mock facets with unique selectors
    MockFacet internal vaultAwareFacet;
    MockFacet internal authFacet;
    MockFacet internal cowRouterFacet;

    address internal mockVault;
    address internal mockDiamondFactory;
    address internal feeSweeper;

    uint256 constant FEE_10_PERCENT = 10e16; // 10%
    uint256 constant FEE_20_PERCENT = 20e16; // 20%
    uint256 constant MAX_FEE = 50e16; // 50%

    function setUp() public {
        // Create mock addresses
        mockVault = makeAddr("vault");
        mockDiamondFactory = makeAddr("diamondFactory");
        feeSweeper = makeAddr("feeSweeper");

        // Create mock facets with distinct selectors
        bytes4[] memory vaultAwareFuncs = new bytes4[](1);
        vaultAwareFuncs[0] = IBalancerV3VaultAware.balV3Vault.selector;
        bytes4[] memory vaultAwareInterfaces = new bytes4[](1);
        vaultAwareInterfaces[0] = type(IBalancerV3VaultAware).interfaceId;
        vaultAwareFacet = new MockFacet("VaultAwareFacet", vaultAwareFuncs, vaultAwareInterfaces);

        bytes4[] memory authFuncs = new bytes4[](1);
        authFuncs[0] = bytes4(keccak256("authFunc()"));
        bytes4[] memory authInterfaces = new bytes4[](0);
        authFacet = new MockFacet("AuthFacet", authFuncs, authInterfaces);

        bytes4[] memory cowRouterFuncs = new bytes4[](6);
        cowRouterFuncs[0] = ICowRouter.getProtocolFeePercentage.selector;
        cowRouterFuncs[1] = ICowRouter.getMaxProtocolFeePercentage.selector;
        cowRouterFuncs[2] = ICowRouter.getCollectedProtocolFees.selector;
        cowRouterFuncs[3] = ICowRouter.getFeeSweeper.selector;
        cowRouterFuncs[4] = ICowRouter.setProtocolFeePercentage.selector;
        cowRouterFuncs[5] = ICowRouter.withdrawCollectedProtocolFees.selector;
        bytes4[] memory cowRouterInterfaces = new bytes4[](1);
        cowRouterInterfaces[0] = type(ICowRouter).interfaceId;
        cowRouterFacet = new MockFacet("CowRouterFacet", cowRouterFuncs, cowRouterInterfaces);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_packageName_returnsCorrectName() public {
        pkg = _deployPkg();

        string memory name = pkg.packageName();
        assertEq(name, "CowRouterDFPkg", "Package name should match");
    }

    function test_packageMetadata_returnsAllData() public {
        pkg = _deployPkg();

        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "CowRouterDFPkg", "Name should match");
        assertEq(interfaces.length, 2, "Should have 2 interfaces");
        assertEq(facets.length, 3, "Should have 3 facets");
    }

    function test_facetAddresses_returnsAllFacets() public {
        pkg = _deployPkg();

        address[] memory facets = pkg.facetAddresses();

        assertEq(facets.length, 3, "Should return 3 facet addresses");
        assertEq(facets[0], address(vaultAwareFacet), "First facet should be vault aware");
        assertEq(facets[1], address(authFacet), "Second facet should be auth");
        assertEq(facets[2], address(cowRouterFacet), "Third facet should be cow router");
    }

    function test_facetInterfaces_includesCowRouterInterface() public {
        pkg = _deployPkg();

        bytes4[] memory interfaces = pkg.facetInterfaces();

        bool hasCowRouter = false;
        bool hasVaultAware = false;

        for (uint256 i = 0; i < interfaces.length; i++) {
            if (interfaces[i] == type(ICowRouter).interfaceId) hasCowRouter = true;
            if (interfaces[i] == type(IBalancerV3VaultAware).interfaceId) hasVaultAware = true;
        }

        assertTrue(hasCowRouter, "Should include ICowRouter interface");
        assertTrue(hasVaultAware, "Should include IBalancerV3VaultAware interface");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_facetCuts_returnsThreeCuts() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 3, "Should return 3 facet cuts");
    }

    function test_facetCuts_noSelectorCollisions() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        // Collect all selectors
        uint256 totalSelectors = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            totalSelectors += cuts[i].functionSelectors.length;
        }

        bytes4[] memory allSelectors = new bytes4[](totalSelectors);
        uint256 index = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                allSelectors[index++] = cuts[i].functionSelectors[j];
            }
        }

        // Check for duplicates
        for (uint256 i = 0; i < allSelectors.length; i++) {
            for (uint256 j = i + 1; j < allSelectors.length; j++) {
                assertTrue(
                    allSelectors[i] != allSelectors[j],
                    string.concat(
                        "Selector collision detected: ",
                        vm.toString(bytes32(allSelectors[i]))
                    )
                );
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Salt Validation Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_revertsForZeroFeeSweeper() public {
        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: address(0) // Invalid!
            })
        );

        vm.expectRevert(CowRouterDFPkg.InvalidFeeSweeper.selector);
        pkg.calcSalt(args);
    }

    function test_calcSalt_revertsForFeeAboveMax() public {
        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: 51e16, // 51% - above max of 50%
                feeSweeper: feeSweeper
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                CowRouterDFPkg.ProtocolFeePercentageAboveLimit.selector,
                51e16, // provided
                MAX_FEE // max
            )
        );
        pkg.calcSalt(args);
    }

    function test_calcSalt_acceptsMaxFee() public {
        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: MAX_FEE, // 50% - exactly at max
                feeSweeper: feeSweeper
            })
        );

        bytes32 salt = pkg.calcSalt(args);
        assertTrue(salt != bytes32(0), "Salt should not be zero for valid max fee config");
    }

    function test_calcSalt_acceptsZeroFee() public {
        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: 0, // 0% - valid
                feeSweeper: feeSweeper
            })
        );

        bytes32 salt = pkg.calcSalt(args);
        assertTrue(salt != bytes32(0), "Salt should not be zero for valid zero fee config");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Salt Calculation Tests                             */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_deterministicForSameInputs() public {
        pkg = _deployPkg();

        bytes memory args1 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes memory args2 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertEq(salt1, salt2, "Same inputs should produce same salt");
    }

    function test_calcSalt_differentForDifferentFees() public {
        pkg = _deployPkg();

        bytes memory args1 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes memory args2 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_20_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertTrue(salt1 != salt2, "Different fees should produce different salt");
    }

    function test_calcSalt_differentForDifferentSweepers() public {
        pkg = _deployPkg();

        address otherSweeper = makeAddr("otherSweeper");

        bytes memory args1 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes memory args2 = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: otherSweeper
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertTrue(salt1 != salt2, "Different sweepers should produce different salt");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Process Args Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_processArgs_returnsUnchanged() public {
        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: FEE_10_PERCENT,
                feeSweeper: feeSweeper
            })
        );

        bytes memory processed = pkg.processArgs(args);

        // Should return unchanged since no processing needed
        assertEq(keccak256(args), keccak256(processed), "Args should be unchanged");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_calcSalt_validFeeRange(uint256 fee, address sweeper) public {
        vm.assume(sweeper != address(0));
        vm.assume(fee <= MAX_FEE);

        pkg = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: fee,
                feeSweeper: sweeper
            })
        );

        // Should not revert for valid inputs
        bytes32 salt = pkg.calcSalt(args);
        assertTrue(salt != bytes32(0), "Salt should not be zero for valid config");
    }

    function testFuzz_calcSalt_deterministicAcrossInstances(
        uint256 fee,
        address sweeper
    ) public {
        vm.assume(sweeper != address(0));
        vm.assume(fee <= MAX_FEE);

        // Deploy two separate instances
        CowRouterDFPkg pkg1 = _deployPkg();
        CowRouterDFPkg pkg2 = _deployPkg();

        bytes memory args = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: fee,
                feeSweeper: sweeper
            })
        );

        bytes32 salt1 = pkg1.calcSalt(args);
        bytes32 salt2 = pkg2.calcSalt(args);

        // Salt calculation is pure, so should be identical across instances
        assertEq(salt1, salt2, "Salt should be deterministic across package instances");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Helper Functions                                  */
    /* -------------------------------------------------------------------------- */

    function _deployPkg() internal returns (CowRouterDFPkg) {
        return new CowRouterDFPkg(
            ICowRouterDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                cowRouterFacet: IFacet(address(cowRouterFacet)),
                balancerV3Vault: IVault(mockVault),
                diamondFactory: IDiamondPackageCallBackFactory(mockDiamondFactory)
            })
        );
    }
}
