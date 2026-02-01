// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ICowPool} from "@balancer-labs/v3-interfaces/contracts/pool-cow/ICowPool.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {CowPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolFacet.sol";

/**
 * @title CowPoolFacet Tests
 * @notice Tests for CowPoolFacet deployment and IFacet compliance.
 */
contract CowPoolFacetTest is Test {
    CowPoolFacet internal facet;

    function setUp() public {
        facet = new CowPoolFacet();
    }

    function test_CowPoolFacet_Deployable() public view {
        assertTrue(address(facet) != address(0), "Facet should deploy");
    }

    function test_CowPoolFacet_BytecodeSize() public {
        uint256 size = address(facet).code.length;
        assertTrue(size > 0, "Should have bytecode");
        assertTrue(size < 24576, "Should be under 24KB");
        emit log_named_uint("CowPoolFacet bytecode size", size);
    }

    function test_CowPoolFacet_FacetName() public view {
        string memory name = facet.facetName();
        assertEq(name, "CowPoolFacet", "Name should match");
    }

    function test_CowPoolFacet_FacetInterfaces() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces.length, 4, "Should have 4 interfaces");
        assertEq(interfaces[0], type(ICowPool).interfaceId, "Should include ICowPool");
        assertEq(interfaces[1], type(IHooks).interfaceId, "Should include IHooks");
        assertEq(interfaces[2], type(IBalancerV3Pool).interfaceId, "Should include IBalancerV3Pool");
        assertEq(interfaces[3], type(IBalancerV3WeightedPool).interfaceId, "Should include IBalancerV3WeightedPool");
    }

    function test_CowPoolFacet_FacetFuncs() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        // Verify expected function count (19 actual + 3 reserved)
        assertEq(funcs.length, 22, "Should have 22 function slots");

        // Verify ICowPool functions
        assertEq(funcs[0], ICowPool.getTrustedCowRouter.selector, "getTrustedCowRouter selector");
        assertEq(funcs[1], ICowPool.refreshTrustedCowRouter.selector, "refreshTrustedCowRouter selector");
        assertEq(funcs[2], ICowPool.getCowPoolDynamicData.selector, "getCowPoolDynamicData selector");
        assertEq(funcs[3], ICowPool.getCowPoolImmutableData.selector, "getCowPoolImmutableData selector");

        // Verify IHooks functions
        assertEq(funcs[4], IHooks.onRegister.selector, "onRegister selector");
        assertEq(funcs[5], IHooks.getHookFlags.selector, "getHookFlags selector");
        assertEq(funcs[12], IHooks.onBeforeSwap.selector, "onBeforeSwap selector");

        // Verify IBalancerV3Pool functions
        assertEq(funcs[15], IBalancerV3Pool.computeInvariant.selector, "computeInvariant selector");
        assertEq(funcs[16], IBalancerV3Pool.computeBalance.selector, "computeBalance selector");
        assertEq(funcs[17], IBalancerV3Pool.onSwap.selector, "onSwap selector");

        // Verify IBalancerV3WeightedPool functions
        assertEq(funcs[18], IBalancerV3WeightedPool.getNormalizedWeights.selector, "getNormalizedWeights selector");
    }

    function test_CowPoolFacet_FacetMetadata() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();

        assertEq(name, "CowPoolFacet", "Name should match");
        assertEq(interfaces.length, 4, "Should have 4 interfaces");
        assertEq(functions.length, 22, "Should have 22 function slots");
    }
}
