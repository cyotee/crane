// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3StablePool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3StablePool.sol";
import {BalancerV3StablePoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolFacet.sol";

/**
 * @title BalancerV3StablePoolFacet_IFacet_Test
 * @notice Tests IFacet compliance for BalancerV3StablePoolFacet.
 */
contract BalancerV3StablePoolFacet_IFacet_Test is Test {
    BalancerV3StablePoolFacet internal facet;

    function setUp() public {
        facet = new BalancerV3StablePoolFacet();
    }

    /* ---------------------------------------------------------------------- */
    /*                            facetName Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_facetName_returnsCorrectName() public view {
        string memory name = facet.facetName();
        assertEq(name, "BalancerV3StablePoolFacet", "Facet name should match");
    }

    /* ---------------------------------------------------------------------- */
    /*                         facetInterfaces Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_facetInterfaces_containsIBalancerV3Pool() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces[0], type(IBalancerV3Pool).interfaceId, "Should include IBalancerV3Pool interface");
    }

    function test_facetInterfaces_containsIBalancerV3StablePool() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces[1], type(IBalancerV3StablePool).interfaceId, "Should include IBalancerV3StablePool interface");
    }

    function test_facetInterfaces_returnsCorrectLength() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces.length, 2, "Should return exactly 2 interfaces");
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

    function test_facetFuncs_containsGetAmplificationParameter() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs[3], IBalancerV3StablePool.getAmplificationParameter.selector, "Should include getAmplificationParameter selector");
    }

    function test_facetFuncs_containsGetAmplificationState() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs[4], IBalancerV3StablePool.getAmplificationState.selector, "Should include getAmplificationState selector");
    }

    function test_facetFuncs_returnsCorrectLength() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs.length, 5, "Should return exactly 5 functions");
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

    /* ---------------------------------------------------------------------- */
    /*                        Selector Verification Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_selectors_areCorrect() public pure {
        // Verify selectors match expected values from Balancer interfaces
        assertEq(
            IBalancerV3Pool.computeInvariant.selector,
            bytes4(keccak256("computeInvariant(uint256[],uint8)")),
            "computeInvariant selector should match"
        );
        assertEq(
            IBalancerV3Pool.computeBalance.selector,
            bytes4(keccak256("computeBalance(uint256[],uint256,uint256)")),
            "computeBalance selector should match"
        );
        assertEq(
            IBalancerV3StablePool.getAmplificationParameter.selector,
            bytes4(keccak256("getAmplificationParameter()")),
            "getAmplificationParameter selector should match"
        );
        assertEq(
            IBalancerV3StablePool.getAmplificationState.selector,
            bytes4(keccak256("getAmplificationState()")),
            "getAmplificationState selector should match"
        );
    }
}
