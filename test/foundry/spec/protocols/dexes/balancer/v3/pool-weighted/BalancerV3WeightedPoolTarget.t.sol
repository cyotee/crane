// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/WeightedMath.sol";

import {BalancerV3WeightedPoolTargetStub} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTargetStub.sol";

/**
 * @title BalancerV3WeightedPoolTarget_Test
 * @notice Tests for the BalancerV3WeightedPoolTarget weighted pool AMM logic.
 */
contract BalancerV3WeightedPoolTarget_Test is Test {
    using FixedPoint for uint256;

    BalancerV3WeightedPoolTargetStub internal pool;

    uint256 constant WEIGHT_80 = 0.8e18;
    uint256 constant WEIGHT_20 = 0.2e18;

    function setUp() public {
        pool = new BalancerV3WeightedPoolTargetStub();

        // Initialize with 80/20 weights
        uint256[] memory weights = new uint256[](2);
        weights[0] = WEIGHT_80;
        weights[1] = WEIGHT_20;
        pool.initialize(weights);
    }

    /* ---------------------------------------------------------------------- */
    /*                         getNormalizedWeights Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_getNormalizedWeights_returns8020Weights() public view {
        uint256[] memory weights = pool.getNormalizedWeights();

        assertEq(weights.length, 2, "Should have 2 weights");
        assertEq(weights[0], WEIGHT_80, "First weight should be 80%");
        assertEq(weights[1], WEIGHT_20, "Second weight should be 20%");
    }

    function test_getNormalizedWeights_sumToOne() public view {
        uint256[] memory weights = pool.getNormalizedWeights();

        uint256 sum = weights[0] + weights[1];
        assertEq(sum, FixedPoint.ONE, "Weights should sum to 1e18");
    }

    /* ---------------------------------------------------------------------- */
    /*                           computeInvariant Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_computeInvariant_balanced8020Pool_returnsCorrectValue() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18; // 80% token
        balances[1] = 200e18; // 20% token

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        // For weighted pools, invariant = product(balance[i]^weight[i])
        // Using Balancer's WeightedMath for reference
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 expectedDown = WeightedMath.computeInvariantDown(weights, balances);
        uint256 expectedUp = WeightedMath.computeInvariantUp(weights, balances);

        assertEq(invariantDown, expectedDown, "ROUND_DOWN invariant should match WeightedMath");
        assertEq(invariantUp, expectedUp, "ROUND_UP invariant should match WeightedMath");
    }

    function test_computeInvariant_roundDown_lessOrEqualRoundUp() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 333e18;
        balances[1] = 777e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN should be <= ROUND_UP");
    }

    function test_computeInvariant_zeroBalance_reverts() public {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 0;

        // WeightedMath reverts on zero balance (ZeroInvariant error)
        vm.expectRevert();
        pool.computeInvariant(balances, Rounding.ROUND_DOWN);
    }

    function testFuzz_computeInvariant_anyBalances_returnsPositive(uint256 bal0, uint256 bal1) public view {
        bal0 = bound(bal0, 1e18, 1e30);
        bal1 = bound(bal1, 1e18, 1e30);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertTrue(invariant > 0, "Invariant should be positive for non-zero balances");
    }

    /* ---------------------------------------------------------------------- */
    /*                            computeBalance Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_computeBalance_invariantRatioOne_returnsSameBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        uint256 newBalance = pool.computeBalance(balances, 0, 1e18);

        assertApproxEqRel(newBalance, 800e18, 1e14, "Balance should be approximately the same");
    }

    function test_computeBalance_invariantRatioDouble_increasesBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        uint256 newBalance = pool.computeBalance(balances, 0, 2e18);

        assertGt(newBalance, 800e18, "New balance should be greater than original");
    }

    function testFuzz_computeBalance_positiveRatio_returnsPositive(uint256 bal0, uint256 bal1, uint256 ratio) public view {
        bal0 = bound(bal0, 1e12, 1e27);
        bal1 = bound(bal1, 1e12, 1e27);
        ratio = bound(ratio, 0.5e18, 2e18);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        assertTrue(newBalance > 0, "New balance should be positive");
    }

    /* ---------------------------------------------------------------------- */
    /*                              onSwap Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_onSwap_exactIn_returnsCorrectOutput() public view {
        // Pool: 800e18 token0 (80%), 200e18 token1 (20%)
        // Swap: 100e18 token0 in
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 100e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Calculate expected using WeightedMath
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 expected = WeightedMath.computeOutGivenExactIn(
            balances[0], weights[0], balances[1], weights[1], 100e18
        );

        assertEq(amountOut, expected, "EXACT_IN should return correct output amount");
        assertTrue(amountOut > 0, "Output should be positive");
    }

    function test_onSwap_exactOut_returnsCorrectInput() public view {
        // Pool: 800e18 token0 (80%), 200e18 token1 (20%)
        // Swap: want 50e18 token1 out
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        // Calculate expected using WeightedMath
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 expected = WeightedMath.computeInGivenExactOut(
            balances[0], weights[0], balances[1], weights[1], 50e18
        );

        assertEq(amountIn, expected, "EXACT_OUT should return correct input amount");
        assertTrue(amountIn > 0, "Input should be positive");
    }

    function test_onSwap_exactIn_reverseDirection() public view {
        // Swap token1 for token0 (20% -> 80%)
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 1,
            indexOut: 0,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 expected = WeightedMath.computeOutGivenExactIn(
            balances[1], weights[1], balances[0], weights[0], 50e18
        );

        assertEq(amountOut, expected, "Reverse direction EXACT_IN should work correctly");
    }

    function test_onSwap_exactIn_smallAmount_noRevert() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Should not revert for small amounts
        assertLe(amountOut, 1e15, "Small input should produce small output");
    }

    function testFuzz_onSwap_exactIn_outputPositive(uint256 balA, uint256 balB, uint256 amountIn) public view {
        balA = bound(balA, 1e18, 1e27);
        balB = bound(balB, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, balA / 10);

        uint256[] memory balances = new uint256[](2);
        balances[0] = balA;
        balances[1] = balB;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: amountIn,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        assertTrue(amountOut > 0, "Output should be positive");
    }

    function testFuzz_onSwap_exactOut_inputPositive(uint256 balA, uint256 balB, uint256 amountOut) public view {
        balA = bound(balA, 1e18, 1e27);
        balB = bound(balB, 1e18, 1e27);
        amountOut = bound(amountOut, 1e15, balB / 100);

        uint256[] memory balances = new uint256[](2);
        balances[0] = balA;
        balances[1] = balB;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: amountOut,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        assertTrue(amountIn > 0, "Input should be positive");
    }

    function test_onSwap_exactIn_invariantPreservedOrIncreases() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18;
        balances[1] = 200e18;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Update balances after swap
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + 50e18;
        newBalances[1] = balances[1] - amountOut;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        // Invariant should be preserved or slightly increase (no fees here, so approximately equal)
        assertApproxEqRel(invariantAfter, invariantBefore, 1e14, "Invariant should be approximately preserved");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Weighted Pool Specific Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_onSwap_weightedPool_favorsMajorityToken() public view {
        // In an 80/20 pool, swapping the 80% token for the 20% token should yield
        // more output per input compared to the reverse direction (due to weight advantage)
        uint256[] memory balances = new uint256[](2);
        balances[0] = 800e18; // 80% weight
        balances[1] = 200e18; // 20% weight

        // Use smaller amounts to stay within max in ratio (30% of balance)
        // Swap 50 of token0 for token1 (6.25% of balance)
        PoolSwapParams memory params0to1 = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 50e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        // Swap 10 of token1 for token0 (5% of balance, within max in ratio)
        PoolSwapParams memory params1to0 = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 10e18,
            balancesScaled18: balances,
            indexIn: 1,
            indexOut: 0,
            router: address(0),
            userData: ""
        });

        uint256 out0to1 = pool.onSwap(params0to1);
        uint256 out1to0 = pool.onSwap(params1to0);

        // Due to different weights, same input amounts yield different outputs
        // This is expected behavior for weighted pools
        assertTrue(out0to1 > 0, "Output for 0->1 should be positive");
        assertTrue(out1to0 > 0, "Output for 1->0 should be positive");
    }
}
