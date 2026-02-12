// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {CowRouterFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterFacet.sol";
import {CowRouterTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterTarget.sol";

/**
 * @title CowRouterFacet Tests
 * @notice Tests for CowRouterFacet deployment and IFacet compliance.
 */
contract CowRouterFacetTest is Test {
    CowRouterFacet internal facet;

    function setUp() public {
        facet = new CowRouterFacet();
    }

    function test_CowRouterFacet_Deployable() public view {
        assertTrue(address(facet) != address(0), "Facet should deploy");
    }

    function test_CowRouterFacet_BytecodeSize() public {
        uint256 size = address(facet).code.length;
        assertTrue(size > 0, "Should have bytecode");
        assertTrue(size < 24576, "Should be under 24KB");
        emit log_named_uint("CowRouterFacet bytecode size", size);
    }

    function test_CowRouterFacet_FacetName() public view {
        string memory name = facet.facetName();
        assertEq(name, "CowRouterFacet", "Name should match");
    }

    function test_CowRouterFacet_FacetInterfaces() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces.length, 1, "Should have 1 interface");
        assertEq(interfaces[0], type(ICowRouter).interfaceId, "Should include ICowRouter");
    }

    function test_CowRouterFacet_FacetFuncs() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs.length, 12, "Should have 12 functions");

        // Verify ICowRouter getter functions
        assertEq(funcs[0], ICowRouter.getProtocolFeePercentage.selector, "getProtocolFeePercentage selector");
        assertEq(funcs[1], ICowRouter.getMaxProtocolFeePercentage.selector, "getMaxProtocolFeePercentage selector");
        assertEq(funcs[2], ICowRouter.getCollectedProtocolFees.selector, "getCollectedProtocolFees selector");
        assertEq(funcs[3], ICowRouter.getFeeSweeper.selector, "getFeeSweeper selector");

        // Verify ICowRouter setter functions
        assertEq(funcs[4], ICowRouter.setProtocolFeePercentage.selector, "setProtocolFeePercentage selector");
        assertEq(funcs[5], ICowRouter.setFeeSweeper.selector, "setFeeSweeper selector");

        // Verify ICowRouter operation functions
        assertEq(funcs[6], ICowRouter.swapExactInAndDonateSurplus.selector, "swapExactInAndDonateSurplus selector");
        assertEq(funcs[7], ICowRouter.swapExactOutAndDonateSurplus.selector, "swapExactOutAndDonateSurplus selector");
        assertEq(funcs[8], ICowRouter.donate.selector, "donate selector");
        assertEq(funcs[9], ICowRouter.withdrawCollectedProtocolFees.selector, "withdrawCollectedProtocolFees selector");

        // Verify hook functions
        assertEq(funcs[10], CowRouterTarget.swapAndDonateSurplusHook.selector, "swapAndDonateSurplusHook selector");
        assertEq(funcs[11], CowRouterTarget.donateHook.selector, "donateHook selector");
    }

    function test_CowRouterFacet_FacetMetadata() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();

        assertEq(name, "CowRouterFacet", "Name should match");
        assertEq(interfaces.length, 1, "Should have 1 interface");
        assertEq(functions.length, 12, "Should have 12 functions");
    }
}
