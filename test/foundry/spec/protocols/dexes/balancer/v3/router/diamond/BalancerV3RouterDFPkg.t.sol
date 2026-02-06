// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";
import {IBatchRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBatchRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {
    BalancerV3RouterDFPkg,
    IBalancerV3RouterDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.sol";

/* -------------------------------------------------------------------------- */
/*                              TestBase & Behavior                           */
/* -------------------------------------------------------------------------- */

import {TestBase_BalancerV3Router} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol";
import {Behavior_IRouter} from
    "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol";

/**
 * @title BalancerV3RouterDFPkgTest
 * @notice Tests for the Balancer V3 Router Diamond Factory Package.
 * @dev Extends TestBase_BalancerV3Router for standardized test infrastructure.
 *      Uses Behavior_IRouter for validation assertions.
 */
contract BalancerV3RouterDFPkgTest is TestBase_BalancerV3Router {
    /* ========================================================================== */
    /*                          Package Deployment Tests                          */
    /* ========================================================================== */

    /// @notice Inherited from TestBase: test_package_deploysSuccessfully()
    /// @notice Inherited from TestBase: test_package_returnsCorrectName()
    /// @notice Inherited from TestBase: test_package_returnsCorrectInterfaces()
    /// @notice Inherited from TestBase: test_package_returnsAllFacetAddresses()

    function test_package_returnsFacetCuts() public view {
        IDiamond.FacetCut[] memory cuts = routerPkg.facetCuts();
        assertEq(cuts.length, expected_FacetCount(), "Should have correct facet cuts");

        for (uint256 i = 0; i < cuts.length; i++) {
            assertEq(uint256(cuts[i].action), uint256(IDiamond.FacetCutAction.Add), "All cuts should be Add");

            assertTrue(
                Behavior_IRouter.isValid_facetCut_hasSelectors(
                    vm.getLabel(cuts[i].facetAddress),
                    cuts[i].functionSelectors.length
                ),
                "Each facet should have selectors"
            );
        }
    }

    /* ========================================================================== */
    /*                          Router Deployment Tests                           */
    /* ========================================================================== */

    /// @notice Inherited from TestBase: test_deployRouter_createsRouterDiamond()
    /// @notice Inherited from TestBase: test_deployRouter_isDeterministic()
    /// @notice Inherited from TestBase: test_deployRouter_initializesStorage()

    function test_deployRouter_returnsExistingIfRedeployed() public {
        address router1 = _deployRouter();
        address router2 = _deployRouter();

        assertTrue(
            Behavior_IRouter.isValid_deployRouter_idempotent(router1, router2),
            "Should return same router on redeploy"
        );
    }

    function test_deployRouter_differentParamsGetDifferentAddresses() public {
        address router1 = _deployRouter(
            IVault(address(mockVault)),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            "Version 1"
        );

        address router2 = _deployRouter(
            IVault(address(mockVault)),
            IWETH(address(mockWeth)),
            IPermit2(address(mockPermit2)),
            "Version 2"
        );

        assertTrue(
            Behavior_IRouter.isValid_deployRouter_uniqueParams(router1, router2),
            "Different params should produce different addresses"
        );
    }

    /* ========================================================================== */
    /*                     Router Interface Compliance Tests                      */
    /* ========================================================================== */

    function test_router_supportsIRouterCommon() public {
        address router = _deployRouter();

        // Validate vault configuration using Behavior library
        assertTrue(
            Behavior_IRouter.isValid_IRouterCommon_getVault(
                IRouterCommon(router),
                address(mockVault)
            ),
            "getVault() should return correct vault"
        );
    }

    function test_router_vaultConfiguration_withExpectations() public {
        address router = _deployRouter();

        // Record expectations
        Behavior_IRouter.expect_IRouterCommon_getVault(router, address(mockVault));

        // Validate against recorded expectations
        assertTrue(
            Behavior_IRouter.hasValid_IRouterCommon_getVault(IRouterCommon(router)),
            "Vault configuration should match expectations"
        );
    }

    /* ========================================================================== */
    /*                          Facet Size Tests                                  */
    /* ========================================================================== */

    /// @notice Inherited from TestBase: test_facetSizes_allUnder24KB()

    function test_facetSizes_individualValidation() public view {
        assertTrue(
            Behavior_IRouter.isValid_facetSize("RouterSwapFacet", address(swapFacet)),
            "SwapFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("RouterAddLiquidityFacet", address(addLiquidityFacet)),
            "AddLiquidityFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("RouterRemoveLiquidityFacet", address(removeLiquidityFacet)),
            "RemoveLiquidityFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("RouterInitializeFacet", address(initializeFacet)),
            "InitializeFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("RouterCommonFacet", address(commonFacet)),
            "CommonFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("BatchSwapFacet", address(batchSwapFacet)),
            "BatchSwapFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("BufferRouterFacet", address(bufferRouterFacet)),
            "BufferRouterFacet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("CompositeLiquidityERC4626Facet", address(compositeLiquidityERC4626Facet)),
            "CompositeLiquidityERC4626Facet should be under 24KB"
        );
        assertTrue(
            Behavior_IRouter.isValid_facetSize("CompositeLiquidityNestedFacet", address(compositeLiquidityNestedFacet)),
            "CompositeLiquidityNestedFacet should be under 24KB"
        );
    }

    function test_facetSizes_allFacetsValidation() public view {
        address[] memory facets = routerPkg.facetAddresses();
        assertTrue(
            Behavior_IRouter.areValid_facetSizes(facets),
            "All facets should be under 24KB"
        );
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

    function _verifyFacetMetadata(IFacet facet, string memory expectedName) internal view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        assertEq(name, expectedName, string.concat("Facet name mismatch for ", expectedName));
        assertTrue(interfaces.length > 0, string.concat(expectedName, " should have interfaces"));
        assertTrue(functions.length > 0, string.concat(expectedName, " should have functions"));
    }
}
