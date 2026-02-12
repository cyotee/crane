// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {BalancerV3WeightedPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol";
import {BalancerV3WeightedPoolTargetStub} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTargetStub.sol";

/**
 * @title BalancerV3WeightedPoolRepo_Test
 * @notice Negative tests for weight validation in BalancerV3WeightedPoolRepo._initialize().
 * @dev Covers ZeroWeight(), WeightsMustSumToOne(), and InvalidWeightsLength() revert paths.
 */
contract BalancerV3WeightedPoolRepo_Test is Test {

    BalancerV3WeightedPoolTargetStub internal pool;

    function setUp() public {
        pool = new BalancerV3WeightedPoolTargetStub();
    }

    /* ---------------------------------------------------------------------- */
    /*                         ZeroWeight Revert Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_initialize_zeroWeightFirst_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0;
        weights[1] = FixedPoint.ONE;

        vm.expectRevert(BalancerV3WeightedPoolRepo.ZeroWeight.selector);
        pool.initialize(weights);
    }

    function test_initialize_zeroWeightLast_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = FixedPoint.ONE;
        weights[1] = 0;

        vm.expectRevert(BalancerV3WeightedPoolRepo.ZeroWeight.selector);
        pool.initialize(weights);
    }

    function test_initialize_zeroWeightMiddle_reverts() public {
        uint256[] memory weights = new uint256[](3);
        weights[0] = 0.5e18;
        weights[1] = 0;
        weights[2] = 0.5e18;

        vm.expectRevert(BalancerV3WeightedPoolRepo.ZeroWeight.selector);
        pool.initialize(weights);
    }

    function test_initialize_allZeroWeights_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0;
        weights[1] = 0;

        vm.expectRevert(BalancerV3WeightedPoolRepo.ZeroWeight.selector);
        pool.initialize(weights);
    }

    /* ---------------------------------------------------------------------- */
    /*                    WeightsMustSumToOne Revert Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_initialize_weightsUnderSum_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.4e18;
        weights[1] = 0.4e18; // sum = 0.8e18, under 1e18

        vm.expectRevert(BalancerV3WeightedPoolRepo.WeightsMustSumToOne.selector);
        pool.initialize(weights);
    }

    function test_initialize_weightsOverSum_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.6e18;
        weights[1] = 0.6e18; // sum = 1.2e18, over 1e18

        vm.expectRevert(BalancerV3WeightedPoolRepo.WeightsMustSumToOne.selector);
        pool.initialize(weights);
    }

    function test_initialize_weightsOffByOne_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.8e18;
        weights[1] = 0.2e18 - 1; // sum = 1e18 - 1, off by one wei

        vm.expectRevert(BalancerV3WeightedPoolRepo.WeightsMustSumToOne.selector);
        pool.initialize(weights);
    }

    function test_initialize_weightsOverByOne_reverts() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.8e18;
        weights[1] = 0.2e18 + 1; // sum = 1e18 + 1, off by one wei

        vm.expectRevert(BalancerV3WeightedPoolRepo.WeightsMustSumToOne.selector);
        pool.initialize(weights);
    }

    function test_initialize_threeTokensUnderSum_reverts() public {
        uint256[] memory weights = new uint256[](3);
        weights[0] = 0.3e18;
        weights[1] = 0.3e18;
        weights[2] = 0.3e18; // sum = 0.9e18

        vm.expectRevert(BalancerV3WeightedPoolRepo.WeightsMustSumToOne.selector);
        pool.initialize(weights);
    }

    /* ---------------------------------------------------------------------- */
    /*                    InvalidWeightsLength Revert Tests                     */
    /* ---------------------------------------------------------------------- */

    function test_initialize_emptyWeights_reverts() public {
        uint256[] memory weights = new uint256[](0);

        vm.expectRevert(BalancerV3WeightedPoolRepo.InvalidWeightsLength.selector);
        pool.initialize(weights);
    }

    function test_initialize_singleWeight_reverts() public {
        uint256[] memory weights = new uint256[](1);
        weights[0] = FixedPoint.ONE;

        vm.expectRevert(BalancerV3WeightedPoolRepo.InvalidWeightsLength.selector);
        pool.initialize(weights);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Valid Initialization Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_initialize_validTwoTokenPool_succeeds() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.8e18;
        weights[1] = 0.2e18;

        pool.initialize(weights);

        uint256[] memory stored = pool.getNormalizedWeights();
        assertEq(stored.length, 2);
        assertEq(stored[0], 0.8e18);
        assertEq(stored[1], 0.2e18);
    }

    function test_initialize_validThreeTokenPool_succeeds() public {
        uint256[] memory weights = new uint256[](3);
        weights[0] = 0.5e18;
        weights[1] = 0.3e18;
        weights[2] = 0.2e18;

        pool.initialize(weights);

        uint256[] memory stored = pool.getNormalizedWeights();
        assertEq(stored.length, 3);
        assertEq(stored[0], 0.5e18);
        assertEq(stored[1], 0.3e18);
        assertEq(stored[2], 0.2e18);
    }

    function test_initialize_validEqualWeights_succeeds() public {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.5e18;
        weights[1] = 0.5e18;

        pool.initialize(weights);

        uint256[] memory stored = pool.getNormalizedWeights();
        assertEq(stored[0], 0.5e18);
        assertEq(stored[1], 0.5e18);
    }
}
