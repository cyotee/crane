// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IVaultMain} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultMain.sol";
import {IVaultExtension} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultExtension.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

/* -------------------------------------------------------------------------- */
/*                        Balancer V3 Vault DFPkg                             */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3VaultDFPkg,
    IBalancerV3VaultDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.sol";

// Vault Facets
import {VaultTransientFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultTransientFacet.sol";
import {VaultSwapFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultSwapFacet.sol";
import {VaultLiquidityFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLiquidityFacet.sol";
import {VaultBufferFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultBufferFacet.sol";
import {VaultPoolTokenFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol";
import {VaultQueryFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol";
import {VaultRegistrationFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRegistrationFacet.sol";
import {VaultAdminFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol";
import {VaultRecoveryFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRecoveryFacet.sol";

/* -------------------------------------------------------------------------- */
/*                              TestBase & Behavior                           */
/* -------------------------------------------------------------------------- */

import {
    TestBase_BalancerV3Router,
    MockWETHForRouter,
    MockPermit2ForRouter
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol";

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                 Mock Contracts                             */
/* -------------------------------------------------------------------------- */

/// @notice Mock Authorizer for integration testing
contract IntegrationMockAuthorizer is IAuthorizer {
    function canPerform(bytes32, address, address) external pure returns (bool) {
        return true;
    }
}

/// @notice Mock Protocol Fee Controller for integration testing
contract IntegrationMockProtocolFeeController {
    function getGlobalProtocolSwapFeePercentage() external pure returns (uint256) {
        return 0;
    }

    function getGlobalProtocolYieldFeePercentage() external pure returns (uint256) {
        return 0;
    }

    function getPoolProtocolSwapFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }

    function getPoolProtocolYieldFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }
}

/* -------------------------------------------------------------------------- */
/*                   BalancerV3RouterVaultIntegrationTest                      */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3RouterVaultIntegrationTest
 * @notice Integration tests verifying Router-Vault end-to-end wiring using
 * real BalancerV3VaultDFPkg instead of MockVault.
 * @dev This test deploys a real Vault Diamond via BalancerV3VaultDFPkg and
 * wires the Router to point to it. Validates:
 * - Router correctly references real Vault Diamond
 * - Vault Diamond has working DiamondLoupe (factory-provided)
 * - Vault Diamond supports expected interfaces (IVaultMain, IVaultExtension, IVaultAdmin)
 * - Router-Vault storage wiring is consistent
 */
contract BalancerV3RouterVaultIntegrationTest is TestBase_BalancerV3Router {
    /* ========================================================================== */
    /*                              VAULT INFRASTRUCTURE                          */
    /* ========================================================================== */

    BalancerV3VaultDFPkg public vaultPkg;
    address public realVault;

    // Vault facets
    VaultTransientFacet public vaultTransientFacet;
    VaultSwapFacet public vaultSwapFacet;
    VaultLiquidityFacet public vaultLiquidityFacet;
    VaultBufferFacet public vaultBufferFacet;
    VaultPoolTokenFacet public vaultPoolTokenFacet;
    VaultQueryFacet public vaultQueryFacet;
    VaultRegistrationFacet public vaultRegistrationFacet;
    VaultAdminFacet public vaultAdminFacet;
    VaultRecoveryFacet public vaultRecoveryFacet;

    // Vault mocks
    IntegrationMockAuthorizer public vaultAuthorizer;
    IntegrationMockProtocolFeeController public vaultProtocolFeeController;

    // Vault deployment constants
    uint256 constant MINIMUM_TRADE_AMOUNT = 1e6;
    uint256 constant MINIMUM_WRAP_AMOUNT = 1e6;
    uint32 constant PAUSE_WINDOW_DURATION = 365 days;
    uint32 constant BUFFER_PERIOD_DURATION = 90 days;

    /* ========================================================================== */
    /*                              SETUP OVERRIDES                               */
    /* ========================================================================== */

    /**
     * @notice Override mock deployment to deploy real vault infrastructure.
     * @dev Deploys vault facets, VaultDFPkg, and a real Vault Diamond.
     * MockWETH and MockPermit2 are still used since they are Router-specific concerns.
     */
    function _deployMockContracts() internal virtual override {
        // Router still needs mock WETH and Permit2 (these are Router-specific)
        mockWeth = new MockWETHForRouter();
        mockPermit2 = new MockPermit2ForRouter();

        // Deploy real Vault infrastructure
        _deployVaultInfrastructure();
    }

    /**
     * @notice Deploy the full vault infrastructure: facets, package, and vault instance.
     */
    function _deployVaultInfrastructure() internal {
        // Deploy vault mocks (authorizer and fee controller)
        vaultAuthorizer = new IntegrationMockAuthorizer();
        vaultProtocolFeeController = new IntegrationMockProtocolFeeController();

        // Deploy vault facets
        vaultTransientFacet = new VaultTransientFacet();
        vaultSwapFacet = new VaultSwapFacet();
        vaultLiquidityFacet = new VaultLiquidityFacet();
        vaultBufferFacet = new VaultBufferFacet();
        vaultPoolTokenFacet = new VaultPoolTokenFacet();
        vaultQueryFacet = new VaultQueryFacet();
        vaultRegistrationFacet = new VaultRegistrationFacet();
        vaultAdminFacet = new VaultAdminFacet();
        vaultRecoveryFacet = new VaultRecoveryFacet();
    }

    /**
     * @notice Deploy VaultDFPkg after the factory is available.
     * @dev Called in setUp after factory infrastructure is deployed.
     */
    function _deployVaultPackageAndInstance() internal {
        // Deploy the Vault DFPkg (uses same factory as Router)
        vaultPkg = new BalancerV3VaultDFPkg(
            IBalancerV3VaultDFPkg.PkgInit({
                vaultTransientFacet: IFacet(address(vaultTransientFacet)),
                vaultSwapFacet: IFacet(address(vaultSwapFacet)),
                vaultLiquidityFacet: IFacet(address(vaultLiquidityFacet)),
                vaultBufferFacet: IFacet(address(vaultBufferFacet)),
                vaultPoolTokenFacet: IFacet(address(vaultPoolTokenFacet)),
                vaultQueryFacet: IFacet(address(vaultQueryFacet)),
                vaultRegistrationFacet: IFacet(address(vaultRegistrationFacet)),
                vaultAdminFacet: IFacet(address(vaultAdminFacet)),
                vaultRecoveryFacet: IFacet(address(vaultRecoveryFacet)),
                diamondFactory: IDiamondPackageCallBackFactory(address(factory))
            })
        );

        // Deploy real vault instance
        realVault = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(vaultAuthorizer)),
            IProtocolFeeController(address(vaultProtocolFeeController))
        );

    }

    function setUp() public override {
        // Call parent setUp which deploys factory, facets, and package
        super.setUp();

        // Now that factory exists, deploy vault package and instance
        _deployVaultPackageAndInstance();

        // Label vault contracts
        vm.label(address(vaultPkg), "BalancerV3VaultDFPkg");
        vm.label(realVault, "RealVaultDiamond");
        vm.label(address(vaultAuthorizer), "IntegrationMockAuthorizer");
        vm.label(address(vaultProtocolFeeController), "IntegrationMockProtocolFeeController");
    }

    /* ========================================================================== */
    /*                     Router Deployment with Real Vault                      */
    /* ========================================================================== */

    /**
     * @notice Deploy a router pointing to the real Vault Diamond.
     * @return router The deployed router address
     */
    function _deployIntegrationRouter() internal returns (address router) {
        router = _deployRouter(
            IVault(realVault),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            DEFAULT_ROUTER_VERSION
        );
    }

    /* ========================================================================== */
    /*                     Router-Vault Integration Tests                         */
    /* ========================================================================== */

    /**
     * @notice Verify router's getVault() returns the real Vault Diamond address.
     */
    function test_integration_routerPointsToRealVault() public {
        address router = _deployIntegrationRouter();
        IRouterCommon routerCommon = IRouterCommon(router);

        assertEq(
            address(routerCommon.getVault()),
            realVault,
            "Router should point to real Vault Diamond"
        );
    }

    /**
     * @notice Verify router's vault reference is a working Diamond with loupe.
     * @dev Tests the factory-provided DiamondLoupe facet on the real vault.
     */
    function test_integration_vaultHasDiamondLoupe() public {
        address router = _deployIntegrationRouter();
        IRouterCommon routerCommon = IRouterCommon(router);

        // Get vault address from router
        address vaultAddr = address(routerCommon.getVault());

        // Cast to IDiamondLoupe and query facets
        IDiamondLoupe loupe = IDiamondLoupe(vaultAddr);
        IDiamondLoupe.Facet[] memory facets = loupe.facets();

        assertTrue(facets.length > 0, "Vault should have facets via DiamondLoupe");

        // Factory provides 3 facets (ERC165, DiamondLoupe, ERC8109) + 9 vault facets = 12
        // (PostDeployHook is removed after deployment)
        assertEq(facets.length, 12, "Vault should have 12 facets (9 vault + 3 factory-provided)");
    }

    /**
     * @notice Verify vault supports expected interfaces via ERC165.
     */
    function test_integration_vaultSupportsExpectedInterfaces() public {
        address router = _deployIntegrationRouter();
        address vaultAddr = address(IRouterCommon(router).getVault());

        IERC165 vaultErc165 = IERC165(vaultAddr);

        assertTrue(
            vaultErc165.supportsInterface(type(IERC165).interfaceId),
            "Vault should support IERC165"
        );
        assertTrue(
            vaultErc165.supportsInterface(type(IDiamondLoupe).interfaceId),
            "Vault should support IDiamondLoupe"
        );
        assertTrue(
            vaultErc165.supportsInterface(type(IVaultMain).interfaceId),
            "Vault should support IVaultMain"
        );
        assertTrue(
            vaultErc165.supportsInterface(type(IVaultExtension).interfaceId),
            "Vault should support IVaultExtension"
        );
        assertTrue(
            vaultErc165.supportsInterface(type(IVaultAdmin).interfaceId),
            "Vault should support IVaultAdmin"
        );
    }

    /**
     * @notice Verify vault selectors resolve to facet addresses via the router's vault reference.
     * @dev End-to-end test: Router -> getVault() -> IDiamondLoupe -> facetAddress()
     */
    function test_integration_vaultSelectorsResolve() public {
        address router = _deployIntegrationRouter();
        address vaultAddr = address(IRouterCommon(router).getVault());
        IDiamondLoupe loupe = IDiamondLoupe(vaultAddr);

        // Verify key selectors from each Vault interface resolve to facets
        assertTrue(
            loupe.facetAddress(IVaultMain.swap.selector) != address(0),
            "swap selector should resolve"
        );
        assertTrue(
            loupe.facetAddress(IVaultMain.addLiquidity.selector) != address(0),
            "addLiquidity selector should resolve"
        );
        assertTrue(
            loupe.facetAddress(IVaultMain.removeLiquidity.selector) != address(0),
            "removeLiquidity selector should resolve"
        );
        assertTrue(
            loupe.facetAddress(IVaultExtension.getPoolTokens.selector) != address(0),
            "getPoolTokens selector should resolve"
        );
        assertTrue(
            loupe.facetAddress(IVaultAdmin.isVaultPaused.selector) != address(0),
            "isVaultPaused selector should resolve"
        );
    }

    /**
     * @notice Verify vault admin functions are accessible through the real vault.
     * @dev Tests that vault storage was initialized correctly.
     */
    function test_integration_vaultStorageInitialized() public {
        address router = _deployIntegrationRouter();
        address vaultAddr = address(IRouterCommon(router).getVault());

        IVaultAdmin vaultAdmin_ = IVaultAdmin(vaultAddr);

        // Verify vault configuration was initialized
        assertEq(
            vaultAdmin_.getMinimumTradeAmount(),
            MINIMUM_TRADE_AMOUNT,
            "Minimum trade amount should match"
        );
        assertEq(
            vaultAdmin_.getMinimumWrapAmount(),
            MINIMUM_WRAP_AMOUNT,
            "Minimum wrap amount should match"
        );

        // Verify vault is not paused
        assertFalse(vaultAdmin_.isVaultPaused(), "Vault should not be paused initially");
    }

    /**
     * @notice Verify the router deployment is deterministic with real vault.
     */
    function test_integration_routerDeploymentIsDeterministic() public {
        address expectedRouter = _calcRouterAddress(
            IVault(realVault),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            DEFAULT_ROUTER_VERSION
        );

        address router = _deployIntegrationRouter();
        assertEq(router, expectedRouter, "Router address should be deterministic with real vault");
    }

    /**
     * @notice Verify both router and vault share the same factory.
     * @dev Both DFPkgs use the same DiamondPackageCallBackFactory.
     */
    function test_integration_sharedFactoryInfrastructure() public view {
        assertEq(
            address(vaultPkg.DIAMOND_PACKAGE_FACTORY()),
            address(routerPkg.DIAMOND_PACKAGE_FACTORY()),
            "Router and Vault should use the same DiamondPackageCallBackFactory"
        );
    }
}
