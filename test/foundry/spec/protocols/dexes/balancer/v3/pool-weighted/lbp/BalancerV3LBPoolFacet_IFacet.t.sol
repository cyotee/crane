// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3LBPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3LBPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3LBPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolFacet.sol";

/**
 * @title BalancerV3LBPoolFacet_IFacet_Test
 * @notice Tests for the BalancerV3LBPoolFacet's IFacet implementation.
 */
contract BalancerV3LBPoolFacet_IFacet_Test is Test {
    BalancerV3LBPoolFacet internal facet;

    function setUp() public {
        facet = new BalancerV3LBPoolFacet();
    }

    /* ---------------------------------------------------------------------- */
    /*                              facetName Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_facetName_returnsCorrectName() public view {
        string memory name = facet.facetName();
        assertEq(name, "BalancerV3LBPoolFacet", "Facet name should be correct");
    }

    /* ---------------------------------------------------------------------- */
    /*                          facetInterfaces Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_facetInterfaces_returnsCorrectLength() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();
        assertEq(interfaces.length, 2, "Should have 2 interfaces");
    }

    function test_facetInterfaces_containsIBalancerV3Pool() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        bool found = false;
        for (uint256 i = 0; i < interfaces.length; i++) {
            if (interfaces[i] == type(IBalancerV3Pool).interfaceId) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain IBalancerV3Pool interface");
    }

    function test_facetInterfaces_containsIBalancerV3LBPool() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        bool found = false;
        for (uint256 i = 0; i < interfaces.length; i++) {
            if (interfaces[i] == type(IBalancerV3LBPool).interfaceId) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain IBalancerV3LBPool interface");
    }

    /* ---------------------------------------------------------------------- */
    /*                            facetFuncs Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_facetFuncs_returnsCorrectLength() public view {
        bytes4[] memory funcs = facet.facetFuncs();
        assertEq(funcs.length, 8, "Should have 8 functions");
    }

    function test_facetFuncs_containsComputeInvariant() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3Pool.computeInvariant.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain computeInvariant selector");
    }

    function test_facetFuncs_containsComputeBalance() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3Pool.computeBalance.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain computeBalance selector");
    }

    function test_facetFuncs_containsOnSwap() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3Pool.onSwap.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain onSwap selector");
    }

    function test_facetFuncs_containsGetNormalizedWeights() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3LBPool.getNormalizedWeights.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain getNormalizedWeights selector");
    }

    function test_facetFuncs_containsGetGradualWeightUpdateParams() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3LBPool.getGradualWeightUpdateParams.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain getGradualWeightUpdateParams selector");
    }

    function test_facetFuncs_containsIsSwapEnabled() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3LBPool.isSwapEnabled.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain isSwapEnabled selector");
    }

    function test_facetFuncs_containsGetTokenIndices() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3LBPool.getTokenIndices.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain getTokenIndices selector");
    }

    function test_facetFuncs_containsIsProjectTokenSwapInBlocked() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        bool found = false;
        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBalancerV3LBPool.isProjectTokenSwapInBlocked.selector) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Should contain isProjectTokenSwapInBlocked selector");
    }

    /* ---------------------------------------------------------------------- */
    /*                          facetMetadata Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_facetMetadata_returnsConsistentData() public view {
        (
            string memory name,
            bytes4[] memory interfaces,
            bytes4[] memory functions
        ) = facet.facetMetadata();

        assertEq(name, facet.facetName(), "Name should match facetName()");
        assertEq(interfaces.length, facet.facetInterfaces().length, "Interfaces length should match");
        assertEq(functions.length, facet.facetFuncs().length, "Functions length should match");
    }

    function test_facetMetadata_interfacesMatchFacetInterfaces() public view {
        (, bytes4[] memory metadataInterfaces,) = facet.facetMetadata();
        bytes4[] memory directInterfaces = facet.facetInterfaces();

        for (uint256 i = 0; i < metadataInterfaces.length; i++) {
            assertEq(metadataInterfaces[i], directInterfaces[i], "Interface mismatch");
        }
    }

    function test_facetMetadata_functionsMatchFacetFuncs() public view {
        (,, bytes4[] memory metadataFunctions) = facet.facetMetadata();
        bytes4[] memory directFunctions = facet.facetFuncs();

        for (uint256 i = 0; i < metadataFunctions.length; i++) {
            assertEq(metadataFunctions[i], directFunctions[i], "Function mismatch");
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                          IFacet Implementation                          */
    /* ---------------------------------------------------------------------- */

    function test_implementsIFacet() public view {
        // Verify the facet can be cast to IFacet
        IFacet ifacet = IFacet(address(facet));

        // Verify all IFacet functions are callable
        assertEq(ifacet.facetName(), "BalancerV3LBPoolFacet");
        assertTrue(ifacet.facetInterfaces().length > 0);
        assertTrue(ifacet.facetFuncs().length > 0);
    }

    function test_selectors_areCorrect() public pure {
        // Verify key selectors match expected values
        assertEq(IBalancerV3LBPool.getNormalizedWeights.selector, bytes4(keccak256("getNormalizedWeights()")));
        assertEq(IBalancerV3LBPool.isSwapEnabled.selector, bytes4(keccak256("isSwapEnabled()")));
    }
}
