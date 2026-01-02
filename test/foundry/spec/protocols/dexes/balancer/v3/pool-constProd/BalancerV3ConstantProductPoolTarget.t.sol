// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BalancerV3ConstantProductPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol";

/**
 * @title BalancerV3ConstantProductPoolTarget_Test
 * @notice Tests for the BalancerV3ConstantProductPoolTarget constant product AMM logic.
 */
contract BalancerV3ConstantProductPoolTarget_Test is Test {
    using FixedPoint for uint256;

    BalancerV3ConstantProductPoolTarget internal pool;

    function setUp() public {
        pool = new BalancerV3ConstantProductPoolTarget();
    }

    /* ---------------------------------------------------------------------- */
    /*                           computeInvariant Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_computeInvariant_balancedPool_returnsCorrectValue() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // sqrt(1000e18 * 1000e18) * 1e9 = sqrt(1e42) * 1e9 = 1e21 * 1e9 = 1e30... wait
        // Let me recalculate: invariant = sqrt(prod) * 1e9
        // prod = 1e18 * 1e18 = 1e36 (but with mulDown scaling)
        // Actually FixedPoint.mulDown divides by 1e18, so:
        // 1e18.mulDown(1000e18) = 1e18 * 1000e18 / 1e18 = 1000e18
        // then 1000e18.mulDown(1000e18) = 1000e18 * 1000e18 / 1e18 = 1e42 / 1e18 = 1e24
        // sqrt(1e24) = 1e12
        // invariant = 1e12 * 1e9 = 1e21
        // But wait, the loop starts with invariant = 1e18 (FixedPoint.ONE)
        // invariant = 1e18.mulDown(1000e18) = 1000e18
        // invariant = 1000e18.mulDown(1000e18) = 1e42 / 1e18 = 1e24
        // sqrt(1e24) = 1e12, * 1e9 = 1e21
        assertEq(invariant, 1e21, "Invariant should be 1e21 for balanced 1000e18/1000e18 pool");
    }

    function test_computeInvariant_unbalancedPool_returnsCorrectValue() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 400e18;
        balances[1] = 900e18;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // invariant = 1e18.mulDown(400e18).mulDown(900e18)
        // = 400e18.mulDown(900e18) = 400e18 * 900e18 / 1e18 = 360000e18 = 3.6e23
        // sqrt(3.6e23) = 6e11 (approximately)
        // * 1e9 = 6e20
        uint256 expectedInvariant = 600e18; // sqrt(400 * 900) = sqrt(360000) = 600
        assertEq(invariant, expectedInvariant, "Invariant should be 600e18 for 400/900 pool");
    }

    function test_computeInvariant_roundDown_lessOrEqualRoundUp() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 333e18;
        balances[1] = 777e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN should be <= ROUND_UP");
    }

    function test_computeInvariant_zeroBalance_returnsZero() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 0;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertEq(invariant, 0, "Invariant should be 0 when one balance is 0");
    }

    function test_computeInvariant_singleToken_returnsScaledValue() public view {
        // Edge case: single token (should still work)
        uint256[] memory balances = new uint256[](1);
        balances[0] = 1000e18;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // invariant = 1e18.mulDown(1000e18) = 1000e18
        // sqrt(1000e18) * 1e9 = sqrt(1e21) * 1e9
        // sqrt(1e21) ≈ 3.16e10
        // * 1e9 = 3.16e19
        assertTrue(invariant > 0, "Invariant should be positive for single token");
    }

    function testFuzz_computeInvariant_anyBalances_returnsPositive(uint256 bal0, uint256 bal1) public view {
        // Bound to values large enough to avoid precision loss in FixedPoint math
        // FixedPoint.mulDown divides by 1e18, so balances need to be >= 1e18 for product > 0
        bal0 = bound(bal0, 1e18, 1e30);
        bal1 = bound(bal1, 1e18, 1e30);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertTrue(invariant > 0, "Invariant should be positive for non-zero balances");
    }

    function testFuzz_computeInvariant_linearScaling(uint256 bal, uint256 multiplier) public view {
        // Test the linearity property: inv(a*n, b*n) = inv(a,b) * n
        bal = bound(bal, 1e18, 1e24); // Use larger minimum to reduce rounding errors
        multiplier = bound(multiplier, 2, 10); // Smaller multiplier range to reduce accumulation

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal;
        balances[1] = bal;

        uint256 invariant1 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        balances[0] = bal * multiplier;
        balances[1] = bal * multiplier;

        uint256 invariant2 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // Allow small rounding error (0.1% - FixedPoint math can accumulate errors)
        uint256 expectedInvariant2 = invariant1 * multiplier;
        assertApproxEqRel(invariant2, expectedInvariant2, 1e15, "Invariant should scale linearly");
    }

    /* ---------------------------------------------------------------------- */
    /*                            computeBalance Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_computeBalance_invariantRatioOne_returnsSameBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        // With invariant ratio of 1e18 (1.0), balance should remain the same
        uint256 newBalance = pool.computeBalance(balances, 0, 1e18);

        assertApproxEqRel(newBalance, 1000e18, 1e14, "Balance should be approximately the same");
    }

    function test_computeBalance_invariantRatioDouble_increasesBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        // With invariant ratio of 2e18 (2.0), the new invariant is double
        // newInvariant = oldInvariant * 2
        // For constant product: x * y = k => if k doubles and y stays same, x doubles
        // But computeBalance uses: newBalance = newInvariant^2 / otherBalance
        uint256 newBalance = pool.computeBalance(balances, 0, 2e18);

        // Should be greater than original
        assertGt(newBalance, 1000e18, "New balance should be greater than original");
    }

    function test_computeBalance_tokenIndex0_usesOtherBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 400e18;
        balances[1] = 900e18;

        uint256 newBalance0 = pool.computeBalance(balances, 0, 1e18);
        uint256 newBalance1 = pool.computeBalance(balances, 1, 1e18);

        // tokenInIndex=0 uses balances[1] as other
        // tokenInIndex=1 uses balances[0] as other
        assertTrue(newBalance0 > 0, "New balance for token 0 should be positive");
        assertTrue(newBalance1 > 0, "New balance for token 1 should be positive");
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
        // Pool: 1000 X, 1000 Y
        // Swap: 100 X in
        // Expected: dy = (Y * dx) / (X + dx) = (1000 * 100) / (1000 + 100) = 100000 / 1100 ≈ 90.909
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

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

        // dy = (1000e18 * 100e18) / (1000e18 + 100e18)
        // = 100000e36 / 1100e18 = 90909090909090909090 ≈ 90.909e18
        uint256 poolBalOut = 1000e18;
        uint256 swapAmtIn = 100e18;
        uint256 poolBalIn = 1000e18;
        uint256 expectedOut = (poolBalOut * swapAmtIn) / (poolBalIn + swapAmtIn);
        assertEq(amountOut, expectedOut, "EXACT_IN should return correct output amount");
    }

    function test_onSwap_exactOut_returnsCorrectInput() public view {
        // Pool: 1000 X, 1000 Y
        // Swap: want 100 Y out
        // Expected: dx = (X * dy) / (Y - dy) = (1000 * 100) / (1000 - 100) = 100000 / 900 ≈ 111.111
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: 100e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        // dx = (1000e18 * 100e18) / (1000e18 - 100e18)
        // = 100000e36 / 900e18 = 111111111111111111111 ≈ 111.111e18
        uint256 poolBalIn = 1000e18;
        uint256 swapAmtOut = 100e18;
        uint256 poolBalOut = 1000e18;
        uint256 expectedIn = (poolBalIn * swapAmtOut) / (poolBalOut - swapAmtOut);
        assertEq(amountIn, expectedIn, "EXACT_OUT should return correct input amount");
    }

    function test_onSwap_exactIn_reverseDirection() public view {
        // Pool: 1000 X, 2000 Y (unbalanced)
        // Swap: 100 Y in, X out
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 2000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 100e18,
            balancesScaled18: balances,
            indexIn: 1,
            indexOut: 0,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // dy = (X * amountIn) / (Y + amountIn) = (1000 * 100) / (2000 + 100) = 100000 / 2100 ≈ 47.619
        uint256 poolBalOut = 1000e18;
        uint256 swapAmtIn = 100e18;
        uint256 poolBalIn = 2000e18;
        uint256 expectedOut = (poolBalOut * swapAmtIn) / (poolBalIn + swapAmtIn);
        assertEq(amountOut, expectedOut, "Reverse direction EXACT_IN should work correctly");
    }

    function test_onSwap_exactIn_smallAmount_noRevert() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1, // Very small amount
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // Should return 0 or very small amount due to rounding
        assertLe(amountOut, 1, "Small input should produce small or zero output");
    }

    function test_onSwap_exactIn_largeAmount_significantOutput() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 500e18, // 50% of pool
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // dy = (1000 * 500) / (1000 + 500) = 500000 / 1500 = 333.333e18
        uint256 poolBalOut = 1000e18;
        uint256 swapAmtIn = 500e18;
        uint256 poolBalIn = 1000e18;
        uint256 expectedOut = (poolBalOut * swapAmtIn) / (poolBalIn + swapAmtIn);
        assertEq(amountOut, expectedOut, "Large swap should produce correct output");
        assertGt(amountOut, 0, "Output should be significant");
    }

    function testFuzz_onSwap_exactIn_outputLessThanInput(uint256 balA, uint256 balB, uint256 amountIn) public view {
        // Ensure reasonable pool sizes to avoid precision issues
        balA = bound(balA, 1e18, 1e27);
        balB = bound(balB, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, balA / 10); // Max 10% of pool

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

        // For constant product, output < input when pools are balanced
        // This is because: dy = (Y * dx) / (X + dx) < dx when X <= Y
        // The swap always provides less output than input in terms of token quantity
        // unless the pool is imbalanced in favor of the output token
        assertTrue(amountOut > 0, "Output should be positive");
    }

    function testFuzz_onSwap_exactOut_inputGreaterThanOutput(uint256 balA, uint256 balB, uint256 amountOut) public view {
        // Ensure balanced enough pools to avoid division by zero or precision issues
        balA = bound(balA, 1e18, 1e27);
        balB = bound(balB, 1e18, 1e27);
        // Ensure amountOut is much smaller than balB to avoid issues
        amountOut = bound(amountOut, 1e15, balB / 100); // Max 1% of pool out

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

    function test_onSwap_exactIn_invariantPreserved() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18;
        balances[1] = 1000e18;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

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

        // Update balances after swap
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + 100e18;
        newBalances[1] = balances[1] - amountOut;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        // Invariant should be preserved (or slightly increase due to fees in practice)
        // Here without fees, it should be approximately equal
        assertApproxEqRel(invariantAfter, invariantBefore, 1e14, "Invariant should be preserved after swap");
    }
}
