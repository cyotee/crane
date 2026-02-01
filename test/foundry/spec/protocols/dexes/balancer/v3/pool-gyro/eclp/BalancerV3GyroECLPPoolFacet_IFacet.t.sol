// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3GyroECLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3GyroECLPPool.sol";
import {BalancerV3GyroECLPPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolFacet.sol";

/**
 * @title BalancerV3GyroECLPPoolFacet_IFacet_Test
 * @notice Tests the IFacet interface implementation of BalancerV3GyroECLPPoolFacet.
 * @dev Verifies that:
 * - facetName() returns correct name
 * - facetInterfaces() returns IBalancerV3Pool and IBalancerV3GyroECLPPool
 * - facetFuncs() returns the correct selectors
 * - facetMetadata() returns consistent data
 */
contract BalancerV3GyroECLPPoolFacet_IFacet_Test is Test {
    BalancerV3GyroECLPPoolFacet internal facet;

    function setUp() public {
        facet = new BalancerV3GyroECLPPoolFacet();
    }

    function test_facetName() public view {
        assertEq(facet.facetName(), "BalancerV3GyroECLPPoolFacet");
    }

    function test_facetInterfaces() public view {
        bytes4[] memory interfaces = facet.facetInterfaces();

        assertEq(interfaces.length, 2, "Should have 2 interfaces");
        assertEq(interfaces[0], type(IBalancerV3Pool).interfaceId, "First interface should be IBalancerV3Pool");
        assertEq(interfaces[1], type(IBalancerV3GyroECLPPool).interfaceId, "Second interface should be IBalancerV3GyroECLPPool");
    }

    function test_facetFuncs() public view {
        bytes4[] memory funcs = facet.facetFuncs();

        assertEq(funcs.length, 8, "Should have 8 function selectors");

        // IBalancerV3Pool functions
        assertEq(funcs[0], IBalancerV3Pool.computeInvariant.selector, "First func should be computeInvariant");
        assertEq(funcs[1], IBalancerV3Pool.computeBalance.selector, "Second func should be computeBalance");
        assertEq(funcs[2], IBalancerV3Pool.onSwap.selector, "Third func should be onSwap");

        // IBalancerV3GyroECLPPool functions
        assertEq(funcs[3], IBalancerV3GyroECLPPool.getECLPParams.selector, "Fourth func should be getECLPParams");
        assertEq(funcs[4], IBalancerV3GyroECLPPool.getMinimumSwapFeePercentage.selector, "Fifth func should be getMinimumSwapFeePercentage");
        assertEq(funcs[5], IBalancerV3GyroECLPPool.getMaximumSwapFeePercentage.selector, "Sixth func should be getMaximumSwapFeePercentage");
        assertEq(funcs[6], IBalancerV3GyroECLPPool.getMinimumInvariantRatio.selector, "Seventh func should be getMinimumInvariantRatio");
        assertEq(funcs[7], IBalancerV3GyroECLPPool.getMaximumInvariantRatio.selector, "Eighth func should be getMaximumInvariantRatio");
    }

    function test_facetMetadata() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory funcs) = facet.facetMetadata();

        assertEq(name, "BalancerV3GyroECLPPoolFacet", "Name should match facetName()");
        assertEq(interfaces.length, 2, "Should have 2 interfaces");
        assertEq(funcs.length, 8, "Should have 8 function selectors");
    }

    function test_facetMetadata_matchesSeparateCalls() public view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory funcs) = facet.facetMetadata();

        assertEq(name, facet.facetName(), "Name should match facetName()");
        assertEq(keccak256(abi.encode(interfaces)), keccak256(abi.encode(facet.facetInterfaces())), "Interfaces should match");
        assertEq(keccak256(abi.encode(funcs)), keccak256(abi.encode(facet.facetFuncs())), "Functions should match");
    }
}
