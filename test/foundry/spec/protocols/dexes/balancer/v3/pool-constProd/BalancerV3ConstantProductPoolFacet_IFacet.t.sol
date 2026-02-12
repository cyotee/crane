// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {BalancerV3ConstantProductPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol";

/**
 * @title BalancerV3ConstantProductPoolFacet_IFacet_Test
 * @notice Tests IFacet compliance for BalancerV3ConstantProductPoolFacet.
 */
contract BalancerV3ConstantProductPoolFacet_IFacet_Test is Test {
    BalancerV3ConstantProductPoolFacet internal facet;

    function setUp() public {
        facet = new BalancerV3ConstantProductPoolFacet();
    }

    /* ---------------------------------------------------------------------- */
    /*                            facetName Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_facetName_returnsCorrectName() public view {
        string memory name = facet.facetName();
        assertEq(name, "BalancerV3ConstantProductPoolFacet", "Facet name should match");
    }

    /* ---------------------------------------------------------------------- */
    /*                         facetInterfaces Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_facetInterfaces_containsIBalancerV3Pool() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        // The facet allocates 3 interfaces but only sets index 0
        // Check that IBalancerV3Pool is at index 0
        assertEq(interfaces[0], type(IBalancerV3Pool).interfaceId, "Should include IBalancerV3Pool interface");
    }

    function test_facetInterfaces_returnsNonEmptyArray() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertGt(interfaces.length, 0, "Should return at least one interface");
    }

    /* ---------------------------------------------------------------------- */
    /*                           facetFuncs Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_facetFuncs_containsComputeInvariant() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs[0], IBalancerV3Pool.computeInvariant.selector, "Should include computeInvariant selector");
    }

    function test_facetFuncs_containsComputeBalance() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs[1], IBalancerV3Pool.computeBalance.selector, "Should include computeBalance selector");
    }

    function test_facetFuncs_containsOnSwap() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs[2], IBalancerV3Pool.onSwap.selector, "Should include onSwap selector");
    }

    function test_facetFuncs_returnsNonEmptyArray() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertGt(funcs.length, 0, "Should return at least one function");
    }

    /* ---------------------------------------------------------------------- */
    /*                          facetMetadata Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_facetMetadata_returnsConsistentData() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();

        assertEq(name, facet.facetName(), "Metadata name should match facetName()");
        assertEq(interfaces.length, facet.facetInterfaces().length, "Metadata interfaces length should match");
        assertEq(functions.length, facet.facetFuncs().length, "Metadata functions length should match");
    }

    function test_facetMetadata_interfacesMatchFacetInterfaces() public view {
        (, bytes4[] memory metadataInterfaces,) = facet.facetMetadata();
        bytes4[] memory directInterfaces = facet.facetInterfaces();

        for (uint256 i = 0; i < metadataInterfaces.length; i++) {
            assertEq(metadataInterfaces[i], directInterfaces[i], "Interface at index should match");
        }
    }

    function test_facetMetadata_functionsMatchFacetFuncs() public view {
        (,, bytes4[] memory metadataFuncs) = facet.facetMetadata();
        bytes4[] memory directFuncs = facet.facetFuncs();

        for (uint256 i = 0; i < metadataFuncs.length; i++) {
            assertEq(metadataFuncs[i], directFuncs[i], "Function at index should match");
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                      IFacet Interface Compliance                        */
    /* ---------------------------------------------------------------------- */

    function test_implementsIFacet() public view {
        // Verify the facet can be cast to IFacet
        IFacet iFacet = IFacet(address(facet));

        // All IFacet functions should be callable
        iFacet.facetName();
        iFacet.facetInterfaces();
        iFacet.facetFuncs();
        iFacet.facetMetadata();
    }
}
