// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                               OpenZeppelin                                 */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";
import {IBatchRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBatchRouter.sol";
import {IBufferRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBufferRouter.sol";
import {ICompositeLiquidityRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ICompositeLiquidityRouter.sol";

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

import {Behavior_IRouter} from "./Behavior_IRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                 Mock Contracts                             */
/* -------------------------------------------------------------------------- */

/// @notice Mock Vault for testing Router Diamond
contract MockVaultForRouter {
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
contract MockWETHForRouter {
    function deposit() external payable {}
    function withdraw(uint256) external {}
    function transfer(address, uint256) external returns (bool) { return true; }
    function transferFrom(address, address, uint256) external returns (bool) { return true; }
    function approve(address, uint256) external returns (bool) { return true; }
    function balanceOf(address) external pure returns (uint256) { return 0; }
}

/// @notice Mock Permit2 for testing
contract MockPermit2ForRouter {
    function transferFrom(address, address, uint160, address) external {}
    function permit(address, address, uint160, uint48, uint48, bytes32, bytes32) external {}
}

/* -------------------------------------------------------------------------- */
/*                          TestBase_BalancerV3Router                         */
/* -------------------------------------------------------------------------- */

/**
 * @title TestBase_BalancerV3Router
 * @notice Abstract base contract for testing Balancer V3 Router Diamond implementations.
 * @dev Provides a standardized framework for testing routers by:
 *      1. Setting up the Diamond factory infrastructure
 *      2. Deploying all router facets
 *      3. Creating the Router DFPkg
 *      4. Providing helper functions for router deployment
 *      5. Integrating with Behavior_IRouter for validation
 *
 * @dev Usage:
 *      1. Inherit from this contract
 *      2. Call `setUp()` to initialize the infrastructure
 *      3. Use `_deployRouter()` to create router instances
 *      4. Use Behavior_IRouter for validation assertions
 */
abstract contract TestBase_BalancerV3Router is Test {
    /* ========================================================================== */
    /*                              FACTORY INFRASTRUCTURE                        */
    /* ========================================================================== */

    DiamondPackageCallBackFactory public factory;
    ERC165Facet public erc165Facet;
    DiamondLoupeFacet public diamondLoupeFacet;
    ERC8109IntrospectionFacet public erc8109Facet;
    PostDeployAccountHookFacet public postDeployHookFacet;

    /* ========================================================================== */
    /*                              ROUTER PACKAGE                                */
    /* ========================================================================== */

    BalancerV3RouterDFPkg public routerPkg;

    /* ========================================================================== */
    /*                              MOCK CONTRACTS                                */
    /* ========================================================================== */

    MockVaultForRouter public mockVault;
    MockWETHForRouter public mockWeth;
    MockPermit2ForRouter public mockPermit2;

    /* ========================================================================== */
    /*                              ROUTER FACETS                                 */
    /* ========================================================================== */

    RouterSwapFacet public swapFacet;
    RouterAddLiquidityFacet public addLiquidityFacet;
    RouterRemoveLiquidityFacet public removeLiquidityFacet;
    RouterInitializeFacet public initializeFacet;
    RouterCommonFacet public commonFacet;
    BatchSwapFacet public batchSwapFacet;
    BufferRouterFacet public bufferRouterFacet;
    CompositeLiquidityERC4626Facet public compositeLiquidityERC4626Facet;
    CompositeLiquidityNestedFacet public compositeLiquidityNestedFacet;

    /* ========================================================================== */
    /*                              TEST ADDRESSES                                */
    /* ========================================================================== */

    address public admin;
    address public user;

    /* ========================================================================== */
    /*                              CONSTANTS                                     */
    /* ========================================================================== */

    string public constant DEFAULT_ROUTER_VERSION = "Router Diamond v1.0";

    /* ========================================================================== */
    /*                              SETUP                                         */
    /* ========================================================================== */

    function setUp() public virtual {
        _setupTestAddresses();
        _deployMockContracts();
        _deployFactoryInfrastructure();
        _deployRouterFacets();
        _deployRouterPackage();
        _labelContracts();
    }

    /* ========================================================================== */
    /*                              SETUP HELPERS                                 */
    /* ========================================================================== */

    function _setupTestAddresses() internal {
        admin = makeAddr("admin");
        user = makeAddr("user");
    }

    function _deployMockContracts() internal virtual {
        mockVault = new MockVaultForRouter();
        mockWeth = new MockWETHForRouter();
        mockPermit2 = new MockPermit2ForRouter();
    }

    function _deployFactoryInfrastructure() internal virtual {
        erc165Facet = new ERC165Facet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        erc8109Facet = new ERC8109IntrospectionFacet();
        postDeployHookFacet = new PostDeployAccountHookFacet();

        factory = new DiamondPackageCallBackFactory(
            IDiamondPackageCallBackFactoryInit.InitArgs({
                erc165Facet: IFacet(address(erc165Facet)),
                diamondLoupeFacet: IFacet(address(diamondLoupeFacet)),
                erc8109IntrospectionFacet: IFacet(address(erc8109Facet)),
                postDeployHookFacet: IFacet(address(postDeployHookFacet))
            })
        );
    }

    function _deployRouterFacets() internal virtual {
        swapFacet = new RouterSwapFacet();
        addLiquidityFacet = new RouterAddLiquidityFacet();
        removeLiquidityFacet = new RouterRemoveLiquidityFacet();
        initializeFacet = new RouterInitializeFacet();
        commonFacet = new RouterCommonFacet();
        batchSwapFacet = new BatchSwapFacet();
        bufferRouterFacet = new BufferRouterFacet();
        compositeLiquidityERC4626Facet = new CompositeLiquidityERC4626Facet();
        compositeLiquidityNestedFacet = new CompositeLiquidityNestedFacet();
    }

    function _deployRouterPackage() internal virtual {
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
    }

    function _labelContracts() internal virtual {
        vm.label(address(factory), "DiamondPackageCallBackFactory");
        vm.label(address(routerPkg), "BalancerV3RouterDFPkg");
        vm.label(address(mockVault), "MockVault");
        vm.label(address(mockWeth), "MockWETH");
        vm.label(address(mockPermit2), "MockPermit2");
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
    /*                          ROUTER DEPLOYMENT HELPERS                         */
    /* ========================================================================== */

    /**
     * @notice Deploy a router with default parameters.
     * @return router The deployed router address
     */
    function _deployRouter() internal returns (address router) {
        return _deployRouter(
            IVault(address(mockVault)),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            DEFAULT_ROUTER_VERSION
        );
    }

    /**
     * @notice Deploy a router with custom parameters.
     * @param vault_ The vault to use
     * @param weth_ The WETH token to use
     * @param permit2_ The Permit2 contract to use
     * @param version_ The version string
     * @return router The deployed router address
     */
    function _deployRouter(
        IVault vault_,
        IWETH weth_,
        IPermit2 permit2_,
        string memory version_
    ) internal returns (address router) {
        router = routerPkg.deployRouter(vault_, weth_, permit2_, version_);
        vm.label(router, "RouterDiamond");
    }

    /**
     * @notice Calculate the expected deterministic address for a router deployment.
     * @param vault_ The vault to use
     * @param weth_ The WETH token to use
     * @param permit2_ The Permit2 contract to use
     * @param version_ The version string
     * @return expectedAddress The expected router address
     */
    function _calcRouterAddress(
        IVault vault_,
        IWETH weth_,
        IPermit2 permit2_,
        string memory version_
    ) internal view returns (address expectedAddress) {
        bytes memory pkgArgs = abi.encode(
            IBalancerV3RouterDFPkg.PkgArgs({
                vault: vault_,
                weth: weth_,
                permit2: permit2_,
                routerVersion: version_
            })
        );
        return factory.calcAddress(routerPkg, pkgArgs);
    }

    /* ========================================================================== */
    /*                          EXPECTED VALUES (VIRTUAL)                         */
    /* ========================================================================== */

    /**
     * @notice Returns the expected router interfaces.
     * @dev Override this function to provide expected interfaces for validation.
     * @return interfaces The expected interface IDs
     */
    function expected_RouterInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](5);
        interfaces[0] = type(IRouter).interfaceId;
        interfaces[1] = type(IRouterCommon).interfaceId;
        interfaces[2] = type(IBatchRouter).interfaceId;
        interfaces[3] = type(ICompositeLiquidityRouter).interfaceId;
        interfaces[4] = type(IBufferRouter).interfaceId;
    }

    /**
     * @notice Returns the expected number of facets.
     * @return count The expected facet count
     */
    function expected_FacetCount() public pure virtual returns (uint256 count) {
        return 9;
    }

    /**
     * @notice Returns the expected package name.
     * @return name_ The expected package name
     */
    function expected_PackageName() public pure virtual returns (string memory name_) {
        return "BalancerV3RouterDFPkg";
    }

    /* ========================================================================== */
    /*                          FACET SIZE VALIDATION                            */
    /* ========================================================================== */

    /// @notice Maximum contract size in bytes (24KB limit)
    uint256 internal constant MAX_CONTRACT_SIZE = 24576;

    /**
     * @notice Validates that all facets are under the 24KB deployment limit.
     * @return valid True if all facets are within size limits
     */
    function _validateFacetSizes() internal view returns (bool valid) {
        valid = true;
        valid = valid && address(swapFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(addLiquidityFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(removeLiquidityFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(initializeFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(commonFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(batchSwapFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(bufferRouterFacet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(compositeLiquidityERC4626Facet).code.length < MAX_CONTRACT_SIZE;
        valid = valid && address(compositeLiquidityNestedFacet).code.length < MAX_CONTRACT_SIZE;
    }

    /* ========================================================================== */
    /*                          COMMON TEST FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Test that the package deploys successfully.
     */
    function test_package_deploysSuccessfully() public view virtual {
        assertTrue(address(routerPkg) != address(0), "Package should deploy");
        assertTrue(address(routerPkg).code.length > 0, "Package should have code");
    }

    /**
     * @notice Test that the package returns the correct name.
     */
    function test_package_returnsCorrectName() public view virtual {
        assertEq(routerPkg.packageName(), expected_PackageName(), "Package name mismatch");
    }

    /**
     * @notice Test that the package returns the correct interfaces.
     */
    function test_package_returnsCorrectInterfaces() public virtual {
        bytes4[] memory expected = expected_RouterInterfaces();
        bytes4[] memory actual = routerPkg.facetInterfaces();

        assertEq(actual.length, expected.length, "Interface count mismatch");

        assertTrue(
            Behavior_IRouter.areValid_IRouter_interfaces(
                "BalancerV3RouterDFPkg",
                expected,
                actual
            ),
            "Router interfaces validation failed"
        );
    }

    /**
     * @notice Test that the package returns all facet addresses.
     */
    function test_package_returnsAllFacetAddresses() public view virtual {
        address[] memory facets = routerPkg.facetAddresses();
        assertEq(facets.length, expected_FacetCount(), "Facet count mismatch");
    }

    /**
     * @notice Test that a router can be deployed.
     */
    function test_deployRouter_createsRouterDiamond() public virtual {
        address router = _deployRouter();
        assertTrue(router != address(0), "Router should be deployed");
        assertTrue(router.code.length > 0, "Router should have code");
    }

    /**
     * @notice Test that router deployment is deterministic.
     */
    function test_deployRouter_isDeterministic() public virtual {
        address expectedRouter = _calcRouterAddress(
            IVault(address(mockVault)),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            DEFAULT_ROUTER_VERSION
        );

        address router = _deployRouter();
        assertEq(router, expectedRouter, "Router address should be deterministic");
    }

    /**
     * @notice Test that router storage is initialized correctly.
     */
    function test_deployRouter_initializesStorage() public virtual {
        address router = _deployRouter();
        IRouterCommon routerCommon = IRouterCommon(router);
        assertEq(address(routerCommon.getVault()), address(mockVault), "Vault not set correctly");
    }

    /**
     * @notice Test that all facets are under the 24KB limit.
     */
    function test_facetSizes_allUnder24KB() public view virtual {
        assertTrue(_validateFacetSizes(), "All facets should be under 24KB");
    }
}
