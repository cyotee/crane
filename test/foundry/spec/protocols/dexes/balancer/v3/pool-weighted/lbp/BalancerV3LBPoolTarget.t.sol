// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@balancer-labs/v3-solidity-utils/contracts/math/WeightedMath.sol";

import {BalancerV3LBPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolTarget.sol";
import {BalancerV3LBPoolTargetStub} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolTargetStub.sol";
import {GradualValueChange} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/GradualValueChange.sol";

/**
 * @title BalancerV3LBPoolTarget_Test
 * @notice Tests for the BalancerV3LBPoolTarget LBP logic.
 */
contract BalancerV3LBPoolTarget_Test is Test {
    using FixedPoint for uint256;

    BalancerV3LBPoolTargetStub internal pool;

    // LBP parameters for a typical 99/1 -> 50/50 sale
    uint256 constant PROJECT_START_WEIGHT = 0.99e18; // 99%
    uint256 constant PROJECT_END_WEIGHT = 0.50e18;   // 50%
    uint256 constant PROJECT_TOKEN_INDEX = 0;
    uint256 constant RESERVE_TOKEN_INDEX = 1;

    uint256 startTime;
    uint256 endTime;

    function setUp() public {
        pool = new BalancerV3LBPoolTargetStub();

        // Set up a 1-day sale starting in 1 hour
        startTime = block.timestamp + 1 hours;
        endTime = startTime + 1 days;

        // Initialize with 99/1 -> 50/50 weights, no project token swap blocking
        pool.initialize(
            PROJECT_TOKEN_INDEX,
            RESERVE_TOKEN_INDEX,
            PROJECT_START_WEIGHT,
            PROJECT_END_WEIGHT,
            startTime,
            endTime,
            false // allow project token sell-back
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         getNormalizedWeights Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_getNormalizedWeights_beforeStart_returnsStartWeights() public {
        // Before sale starts, weights should be at start values
        uint256[] memory weights = pool.getNormalizedWeights();

        assertEq(weights.length, 2, "Should have 2 weights");
        assertEq(weights[PROJECT_TOKEN_INDEX], PROJECT_START_WEIGHT, "Project token should have start weight");
        assertEq(weights[RESERVE_TOKEN_INDEX], FixedPoint.ONE - PROJECT_START_WEIGHT, "Reserve token should have complement weight");
    }

    function test_getNormalizedWeights_afterEnd_returnsEndWeights() public {
        // Warp to after sale ends
        vm.warp(endTime + 1);

        uint256[] memory weights = pool.getNormalizedWeights();

        assertEq(weights[PROJECT_TOKEN_INDEX], PROJECT_END_WEIGHT, "Project token should have end weight");
        assertEq(weights[RESERVE_TOKEN_INDEX], FixedPoint.ONE - PROJECT_END_WEIGHT, "Reserve token should have complement weight");
    }

    function test_getNormalizedWeights_midway_returnsInterpolatedWeights() public {
        // Warp to midpoint of sale
        vm.warp(startTime + (endTime - startTime) / 2);

        uint256[] memory weights = pool.getNormalizedWeights();

        // At midpoint, weight should be approximately halfway between start and end
        uint256 expectedProjectWeight = (PROJECT_START_WEIGHT + PROJECT_END_WEIGHT) / 2;

        assertApproxEqRel(weights[PROJECT_TOKEN_INDEX], expectedProjectWeight, 1e14, "Project weight should be interpolated at midpoint");
    }

    function test_getNormalizedWeights_alwaysSumToOne() public {
        // Test at various time points
        uint256[] memory timePoints = new uint256[](5);
        timePoints[0] = startTime - 1;
        timePoints[1] = startTime;
        timePoints[2] = startTime + (endTime - startTime) / 2;
        timePoints[3] = endTime;
        timePoints[4] = endTime + 1;

        for (uint256 i = 0; i < timePoints.length; i++) {
            vm.warp(timePoints[i]);
            uint256[] memory weights = pool.getNormalizedWeights();

            assertEq(weights[0] + weights[1], FixedPoint.ONE, "Weights should always sum to 1e18");
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                        getGradualWeightUpdateParams                     */
    /* ---------------------------------------------------------------------- */

    function test_getGradualWeightUpdateParams_returnsCorrectValues() public view {
        (
            uint256 returnedStartTime,
            uint256 returnedEndTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        ) = pool.getGradualWeightUpdateParams();

        assertEq(returnedStartTime, startTime, "Start time should match");
        assertEq(returnedEndTime, endTime, "End time should match");
        assertEq(startWeights[PROJECT_TOKEN_INDEX], PROJECT_START_WEIGHT, "Start weight should match");
        assertEq(endWeights[PROJECT_TOKEN_INDEX], PROJECT_END_WEIGHT, "End weight should match");
    }

    /* ---------------------------------------------------------------------- */
    /*                            isSwapEnabled Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_isSwapEnabled_beforeStart_returnsFalse() public view {
        assertFalse(pool.isSwapEnabled(), "Swaps should be disabled before start");
    }

    function test_isSwapEnabled_duringeSale_returnsTrue() public {
        vm.warp(startTime);
        assertTrue(pool.isSwapEnabled(), "Swaps should be enabled at start");

        vm.warp(startTime + (endTime - startTime) / 2);
        assertTrue(pool.isSwapEnabled(), "Swaps should be enabled during sale");

        vm.warp(endTime);
        assertTrue(pool.isSwapEnabled(), "Swaps should be enabled at end");
    }

    function test_isSwapEnabled_afterEnd_returnsFalse() public {
        vm.warp(endTime + 1);
        assertFalse(pool.isSwapEnabled(), "Swaps should be disabled after end");
    }

    /* ---------------------------------------------------------------------- */
    /*                              onSwap Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_onSwap_beforeStart_reverts() public {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 10e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 10e18,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        vm.expectRevert(BalancerV3LBPoolTarget.SwapsDisabled.selector);
        pool.onSwap(params);
    }

    function test_onSwap_afterEnd_reverts() public {
        vm.warp(endTime + 1);

        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 10e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 10e18,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        vm.expectRevert(BalancerV3LBPoolTarget.SwapsDisabled.selector);
        pool.onSwap(params);
    }

    function test_onSwap_duringSale_succeeds() public {
        vm.warp(startTime);

        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 10e18;

        // Buy project token with reserve token
        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e18,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // At 99/1 weights with 1000:10 ratio, buying with reserve should get substantial project tokens
        assertTrue(amountOut > 0, "Should receive project tokens");
    }

    function test_onSwap_usesCurrentWeights() public {
        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 100e18,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        // Swap at start (99/1 weights - project token has 99% weight, reserve has 1%)
        // With high project weight and low reserve weight, reserve token is more valuable
        // So buying project tokens with reserve should give MORE project tokens early
        vm.warp(startTime);
        uint256 amountOutAtStart = pool.onSwap(params);

        // Swap at end (50/50 weights)
        vm.warp(endTime);
        uint256 amountOutAtEnd = pool.onSwap(params);

        // At 99/1 weights (project:reserve), project token has high weight (99%) making it
        // expensive relative to reserve token. As weights change to 50/50, project token
        // becomes cheaper relative to reserve token.
        // So amountOutAtEnd > amountOutAtStart (you get MORE project tokens later when it's cheaper)
        assertGt(amountOutAtEnd, amountOutAtStart, "Should get more tokens later in sale when project is cheaper");
    }

    /* ---------------------------------------------------------------------- */
    /*                     Project Token Swap Block Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_onSwap_withBlockedSellBack_buySucceeds() public {
        // Create new pool with project token swaps blocked
        BalancerV3LBPoolTargetStub blockedPool = new BalancerV3LBPoolTargetStub();
        blockedPool.initialize(
            PROJECT_TOKEN_INDEX,
            RESERVE_TOKEN_INDEX,
            PROJECT_START_WEIGHT,
            PROJECT_END_WEIGHT,
            startTime,
            endTime,
            true // block project token swaps in
        );

        vm.warp(startTime);

        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 10e18;

        // Buying project token (reserve in, project out) should work
        PoolSwapParams memory buyParams = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e18,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = blockedPool.onSwap(buyParams);
        assertTrue(amountOut > 0, "Buy should succeed");
    }

    function test_onSwap_withBlockedSellBack_sellReverts() public {
        // Create new pool with project token swaps blocked
        BalancerV3LBPoolTargetStub blockedPool = new BalancerV3LBPoolTargetStub();
        blockedPool.initialize(
            PROJECT_TOKEN_INDEX,
            RESERVE_TOKEN_INDEX,
            PROJECT_START_WEIGHT,
            PROJECT_END_WEIGHT,
            startTime,
            endTime,
            true // block project token swaps in
        );

        vm.warp(startTime);

        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 10e18;

        // Selling project token (project in, reserve out) should fail
        PoolSwapParams memory sellParams = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 10e18,
            balancesScaled18: balances,
            indexIn: PROJECT_TOKEN_INDEX,
            indexOut: RESERVE_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        vm.expectRevert(BalancerV3LBPoolTarget.SwapOfProjectTokenIn.selector);
        blockedPool.onSwap(sellParams);
    }

    /* ---------------------------------------------------------------------- */
    /*                           computeInvariant Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_computeInvariant_usesCurrentWeights() public {
        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 10e18;

        // At start
        vm.warp(startTime);
        uint256 invariantAtStart = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // At end
        vm.warp(endTime);
        uint256 invariantAtEnd = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // Invariant changes with weights (different exponents in weighted math)
        assertTrue(invariantAtStart != invariantAtEnd, "Invariant should change with weights");
    }

    function test_computeInvariant_roundingDirection() public {
        vm.warp(startTime);

        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 10e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN should be <= ROUND_UP");
    }

    /* ---------------------------------------------------------------------- */
    /*                              Fuzz Tests                                 */
    /* ---------------------------------------------------------------------- */

    function testFuzz_getNormalizedWeights_sumToOne(uint256 timeOffset) public {
        // Fuzz time between before start and after end
        timeOffset = bound(timeOffset, 0, endTime - startTime + 2 hours);
        vm.warp(startTime - 1 hours + timeOffset);

        uint256[] memory weights = pool.getNormalizedWeights();

        assertEq(weights[0] + weights[1], FixedPoint.ONE, "Weights should always sum to 1e18");
    }

    function testFuzz_onSwap_positiveOutput(uint256 amountIn) public {
        vm.warp(startTime);

        amountIn = bound(amountIn, 1e15, 1e18);

        uint256[] memory balances = new uint256[](2);
        balances[PROJECT_TOKEN_INDEX] = 1000e18;
        balances[RESERVE_TOKEN_INDEX] = 100e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: amountIn,
            balancesScaled18: balances,
            indexIn: RESERVE_TOKEN_INDEX,
            indexOut: PROJECT_TOKEN_INDEX,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        assertTrue(amountOut > 0, "Output should be positive");
    }
}
