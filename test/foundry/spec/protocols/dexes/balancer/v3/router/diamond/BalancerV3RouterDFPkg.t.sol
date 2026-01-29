// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                               OpenZeppelin                                 */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IRouterCommon} from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import {IBatchRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";
import {IBufferRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBufferRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/RouterTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {
    DiamondPackageCallBackFactory,
    IDiamondPackageCallBackFactoryInit
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";

/* -------------------------------------------------------------------------- */
/*                        Balancer V3 Router DFPkg                            */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3RouterDFPkg,
    IBalancerV3RouterDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.sol";
import {BalancerV3RouterStorageRepo} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterStorageRepo.sol";

// Facets
import {RouterSwapFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterSwapFacet.sol";
import {RouterAddLiquidityFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterAddLiquidityFacet.sol";
import {RouterRemoveLiquidityFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterRemoveLiquidityFacet.sol";
import {RouterInitializeFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterInitializeFacet.sol";
import {RouterCommonFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterCommonFacet.sol";
import {BatchSwapFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/BatchSwapFacet.sol";
import {BufferRouterFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/BufferRouterFacet.sol";
import {CompositeLiquidityERC4626Facet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityERC4626Facet.sol";
import {CompositeLiquidityNestedFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityNestedFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                 Mock Contracts                             */
/* -------------------------------------------------------------------------- */

/// @notice Mock Vault for testing Router Diamond
contract MockVault {
    bool public unlocked;

    function unlock(bytes calldata data) external returns (bytes memory) {
        unlocked = true;
        // Call back into the router with the encoded hook call
        (bool success, bytes memory result) = msg.sender.call(data);
        unlocked = false;
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return result;
    }

    function quote(bytes calldata data) external returns (bytes memory) {
        // Simulate quote (static call behavior)
        (bool success, bytes memory result) = msg.sender.staticcall(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return result;
    }

    function isPoolRegistered(address) external pure returns (bool) {
        return true;
    }

    function getPoolTokens(address) external pure returns (IERC20[] memory) {
        return new IERC20[](0);
    }
}

/// @notice Mock WETH for testing
contract MockWETH {
    function deposit() external payable {}
    function withdraw(uint256) external {}
    function transfer(address, uint256) external returns (bool) { return true; }
    function transferFrom(address, address, uint256) external returns (bool) { return true; }
    function approve(address, uint256) external returns (bool) { return true; }
    function balanceOf(address) external pure returns (uint256) { return 0; }
}

/// @notice Mock Permit2 for testing
contract MockPermit2 {
    function transferFrom(address, address, uint160, address) external {}
    function permit(address, address, uint160, uint48, uint48, bytes32, bytes32) external {}
}

/**
 * @title BalancerV3RouterDFPkgTest
 * @notice Tests for the Balancer V3 Router Diamond Factory Package.
 */
contract BalancerV3RouterDFPkgTest is Test {
    // Factory infrastructure
    DiamondPackageCallBackFactory public factory;
    ERC165Facet public erc165Facet;
    DiamondLoupeFacet public diamondLoupeFacet;
    ERC8109IntrospectionFacet public erc8109Facet;
    PostDeployAccountHookFacet public postDeployHookFacet;

    // Router package
    BalancerV3RouterDFPkg public routerPkg;

    // Mock contracts
    MockVault public vault;
    MockWETH public weth;
    MockPermit2 public permit2;

    // Router facet instances
    RouterSwapFacet public swapFacet;
    RouterAddLiquidityFacet public addLiquidityFacet;
    RouterRemoveLiquidityFacet public removeLiquidityFacet;
    RouterInitializeFacet public initializeFacet;
    RouterCommonFacet public commonFacet;
    BatchSwapFacet public batchSwapFacet;
    BufferRouterFacet public bufferRouterFacet;
    CompositeLiquidityERC4626Facet public compositeLiquidityERC4626Facet;
    CompositeLiquidityNestedFacet public compositeLiquidityNestedFacet;

    // Test addresses
    address public admin;
    address public user;

    // Router version
    string constant ROUTER_VERSION = "Router Diamond v1.0";

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");

        // Deploy mock contracts
        vault = new MockVault();
        weth = new MockWETH();
        permit2 = new MockPermit2();

        // Deploy factory infrastructure facets
        erc165Facet = new ERC165Facet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        erc8109Facet = new ERC8109IntrospectionFacet();
        postDeployHookFacet = new PostDeployAccountHookFacet();

        // Deploy the DiamondPackageCallBackFactory
        factory = new DiamondPackageCallBackFactory(
            IDiamondPackageCallBackFactoryInit.InitArgs({
                erc165Facet: IFacet(address(erc165Facet)),
                diamondLoupeFacet: IFacet(address(diamondLoupeFacet)),
                erc8109IntrospectionFacet: IFacet(address(erc8109Facet)),
                postDeployHookFacet: IFacet(address(postDeployHookFacet))
            })
        );

        // Deploy router facets
        swapFacet = new RouterSwapFacet();
        addLiquidityFacet = new RouterAddLiquidityFacet();
        removeLiquidityFacet = new RouterRemoveLiquidityFacet();
        initializeFacet = new RouterInitializeFacet();
        commonFacet = new RouterCommonFacet();
        batchSwapFacet = new BatchSwapFacet();
        bufferRouterFacet = new BufferRouterFacet();
        compositeLiquidityERC4626Facet = new CompositeLiquidityERC4626Facet();
        compositeLiquidityNestedFacet = new CompositeLiquidityNestedFacet();

        // Deploy the Router DFPkg
        routerPkg = new BalancerV3RouterDFPkg(
            IBalancerV3RouterDFPkg.PkgInit({
                routerSwapFacet: IFacet(address(swapFacet)),
                routerAddLiquidityFacet: IFacet(address(addLiquidityFacet)),
                routerRemoveLiquidityFacet: IFacet(address(removeLiquidityFacet)),
                routerInitializeFacet: IFacet(address(initializeFacet)),
                routerCommonFacet: IFacet(address(commonFacet)),
                batchSwapFacet: IFacet(address(batchSwapFacet)),
                bufferRouterFacet: IFacet(address(bufferRouterFacet)),
                compositeLiquidityERC4626Facet: IFacet(address(compositeLiquidityERC4626Facet)),
                compositeLiquidityNestedFacet: IFacet(address(compositeLiquidityNestedFacet)),
                diamondFactory: IDiamondPackageCallBackFactory(address(factory))
            })
        );

        // Label addresses for debugging
        vm.label(address(factory), "DiamondPackageCallBackFactory");
        vm.label(address(routerPkg), "BalancerV3RouterDFPkg");
        vm.label(address(vault), "MockVault");
        vm.label(address(weth), "MockWETH");
        vm.label(address(permit2), "MockPermit2");
        vm.label(address(swapFacet), "RouterSwapFacet");
        vm.label(address(addLiquidityFacet), "RouterAddLiquidityFacet");
        vm.label(address(removeLiquidityFacet), "RouterRemoveLiquidityFacet");
        vm.label(address(initializeFacet), "RouterInitializeFacet");
        vm.label(address(commonFacet), "RouterCommonFacet");
        vm.label(address(batchSwapFacet), "BatchSwapFacet");
        vm.label(address(bufferRouterFacet), "BufferRouterFacet");
        vm.label(address(compositeLiquidityERC4626Facet), "CompositeLiquidityERC4626Facet");
        vm.label(address(compositeLiquidityNestedFacet), "CompositeLiquidityNestedFacet");
    }

    /* ========================================================================== */
    /*                          Package Deployment Tests                          */
    /* ========================================================================== */

    function test_package_deploySuccessfully() public view {
        assertTrue(address(routerPkg) != address(0), "Package should deploy");
        assertTrue(address(routerPkg).code.length > 0, "Package should have code");
    }

    function test_package_returnsCorrectName() public view {
        assertEq(routerPkg.packageName(), "BalancerV3RouterDFPkg", "Package name mismatch");
    }

    function test_package_returnsCorrectInterfaces() public view {
        bytes4[] memory interfaces = routerPkg.facetInterfaces();
        assertEq(interfaces.length, 5, "Should have 5 interface IDs");
        assertEq(interfaces[0], type(IRouter).interfaceId, "IRouter interface mismatch");
        assertEq(interfaces[1], type(IRouterCommon).interfaceId, "IRouterCommon interface mismatch");
        assertEq(interfaces[2], type(IBatchRouter).interfaceId, "IBatchRouter interface mismatch");
    }

    function test_package_returnsAllFacetAddresses() public view {
        address[] memory facets = routerPkg.facetAddresses();
        assertEq(facets.length, 9, "Should have 9 facet addresses");
        assertEq(facets[0], address(swapFacet), "SwapFacet address mismatch");
        assertEq(facets[1], address(addLiquidityFacet), "AddLiquidityFacet address mismatch");
    }

    function test_package_returnsFacetCuts() public view {
        IDiamond.FacetCut[] memory cuts = routerPkg.facetCuts();
        assertEq(cuts.length, 9, "Should have 9 facet cuts");
        for (uint256 i = 0; i < cuts.length; i++) {
            assertEq(uint256(cuts[i].action), uint256(IDiamond.FacetCutAction.Add), "All cuts should be Add");
            assertTrue(cuts[i].functionSelectors.length > 0, "Each facet should have selectors");
        }
    }

    /* ========================================================================== */
    /*                          Router Deployment Tests                           */
    /* ========================================================================== */

    function test_deployRouter_createsRouterDiamond() public {
        address router = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );

        assertTrue(router != address(0), "Router should be deployed");
        assertTrue(router.code.length > 0, "Router should have code");
    }

    function test_deployRouter_isDeterministic() public {
        // Calculate expected address before deployment
        bytes memory pkgArgs = abi.encode(
            IBalancerV3RouterDFPkg.PkgArgs({
                vault: IVault(address(vault)),
                weth: IWETH(address(weth)),
                permit2: IPermit2(address(permit2)),
                routerVersion: ROUTER_VERSION
            })
        );
        address expectedRouter = factory.calcAddress(routerPkg, pkgArgs);

        // Deploy and verify address matches
        address router = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );

        assertEq(router, expectedRouter, "Router address should be deterministic");
    }

    function test_deployRouter_returnsExistingIfRedeployed() public {
        address router1 = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );

        address router2 = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );

        assertEq(router1, router2, "Should return same router on redeploy");
    }

    function test_deployRouter_differentParamsGetDifferentAddresses() public {
        address router1 = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            "Version 1"
        );

        address router2 = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            "Version 2"
        );

        assertTrue(router1 != router2, "Different params should produce different addresses");
    }

    /* ========================================================================== */
    /*                       Router Initialization Tests                          */
    /* ========================================================================== */

    function test_deployRouter_initializesStorage() public {
        address router = routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );

        // Verify vault is set correctly via IRouterCommon
        IRouterCommon routerCommon = IRouterCommon(router);
        assertEq(address(routerCommon.getVault()), address(vault), "Vault not set correctly");
    }

    /* ========================================================================== */
    /*                     Router Interface Compliance Tests                      */
    /* ========================================================================== */

    function test_router_supportsIRouterCommon() public {
        address router = _deployRouter();
        IRouterCommon routerCommon = IRouterCommon(router);

        // getVault should be callable
        assertEq(address(routerCommon.getVault()), address(vault), "getVault() should return vault");
    }

    /* ========================================================================== */
    /*                          Facet Size Tests                                  */
    /* ========================================================================== */

    function test_facetSizes_allUnder24KB() public view {
        // Verify each facet is under the 24KB deployment limit
        assertTrue(address(swapFacet).code.length < 24576, "SwapFacet too large");
        assertTrue(address(addLiquidityFacet).code.length < 24576, "AddLiquidityFacet too large");
        assertTrue(address(removeLiquidityFacet).code.length < 24576, "RemoveLiquidityFacet too large");
        assertTrue(address(initializeFacet).code.length < 24576, "InitializeFacet too large");
        assertTrue(address(commonFacet).code.length < 24576, "CommonFacet too large");
        assertTrue(address(batchSwapFacet).code.length < 24576, "BatchSwapFacet too large");
        assertTrue(address(bufferRouterFacet).code.length < 24576, "BufferRouterFacet too large");
        assertTrue(address(compositeLiquidityERC4626Facet).code.length < 24576, "CompositeLiquidityERC4626Facet too large");
        assertTrue(address(compositeLiquidityNestedFacet).code.length < 24576, "CompositeLiquidityNestedFacet too large");
    }

    /* ========================================================================== */
    /*                          IFacet Compliance Tests                           */
    /* ========================================================================== */

    function test_facets_implementIFacet() public view {
        // Test each facet implements IFacet interface correctly
        _verifyFacetMetadata(IFacet(address(swapFacet)), "RouterSwapFacet");
        _verifyFacetMetadata(IFacet(address(addLiquidityFacet)), "RouterAddLiquidityFacet");
        _verifyFacetMetadata(IFacet(address(removeLiquidityFacet)), "RouterRemoveLiquidityFacet");
        _verifyFacetMetadata(IFacet(address(initializeFacet)), "RouterInitializeFacet");
        _verifyFacetMetadata(IFacet(address(commonFacet)), "RouterCommonFacet");
        _verifyFacetMetadata(IFacet(address(batchSwapFacet)), "BatchSwapFacet");
        _verifyFacetMetadata(IFacet(address(bufferRouterFacet)), "BufferRouterFacet");
        _verifyFacetMetadata(IFacet(address(compositeLiquidityERC4626Facet)), "CompositeLiquidityERC4626Facet");
        _verifyFacetMetadata(IFacet(address(compositeLiquidityNestedFacet)), "CompositeLiquidityNestedFacet");
    }

    function test_facets_haveNonEmptySelectors() public view {
        assertTrue(swapFacet.facetFuncs().length > 0, "SwapFacet should have selectors");
        assertTrue(addLiquidityFacet.facetFuncs().length > 0, "AddLiquidityFacet should have selectors");
        assertTrue(removeLiquidityFacet.facetFuncs().length > 0, "RemoveLiquidityFacet should have selectors");
        assertTrue(initializeFacet.facetFuncs().length > 0, "InitializeFacet should have selectors");
        assertTrue(commonFacet.facetFuncs().length > 0, "CommonFacet should have selectors");
        assertTrue(batchSwapFacet.facetFuncs().length > 0, "BatchSwapFacet should have selectors");
        assertTrue(bufferRouterFacet.facetFuncs().length > 0, "BufferRouterFacet should have selectors");
        assertTrue(compositeLiquidityERC4626Facet.facetFuncs().length > 0, "CompositeLiquidityERC4626Facet should have selectors");
        assertTrue(compositeLiquidityNestedFacet.facetFuncs().length > 0, "CompositeLiquidityNestedFacet should have selectors");
    }

    /* ========================================================================== */
    /*                              Helper Functions                              */
    /* ========================================================================== */

    function _deployRouter() internal returns (address) {
        return routerPkg.deployRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            ROUTER_VERSION
        );
    }

    function _verifyFacetMetadata(IFacet facet, string memory expectedName) internal view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        assertEq(name, expectedName, string.concat("Facet name mismatch for ", expectedName));
        assertTrue(interfaces.length > 0, string.concat(expectedName, " should have interfaces"));
        assertTrue(functions.length > 0, string.concat(expectedName, " should have functions"));
    }
}
