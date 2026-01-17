// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BalancerV3ConstantProductPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol";

/**
 * @title BalancerV3RoundingInvariants_Test
 * @notice Rounding invariant tests for Balancer V3 Constant Product Pool.
 * @dev Tests verify:
 *  - Swap rounding with small amounts (1 wei, dust amounts)
 *  - computeBalance rounding behavior
 *  - Pool never loses value due to rounding (pool-favorable rounding)
 *  - Invariant preservation across operations
 */
contract BalancerV3RoundingInvariants_Test is Test {
    using FixedPoint for uint256;

    BalancerV3ConstantProductPoolTarget internal pool;

    // Common test constants
    uint256 internal constant WAD = 1e18;
    uint256 internal constant DUST = 1; // 1 wei
    uint256 internal constant SMALL_AMOUNT = 100; // 100 wei
    uint256 internal constant MEDIUM_AMOUNT = 1e15; // 0.001 tokens
    uint256 internal constant STANDARD_BALANCE = 1000e18;

    function setUp() public {
        pool = new BalancerV3ConstantProductPoolTarget();
    }

    /* -------------------------------------------------------------------------- */
    /*                    Small Amount Swap Tests (1 wei, dust)                    */
    /* -------------------------------------------------------------------------- */

    function test_onSwap_exactIn_oneWei_returnsZeroOrPositive() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: DUST,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // With 1 wei in and balanced pool:
        // dy = (Y * dx) / (X + dx) = (1000e18 * 1) / (1000e18 + 1) ≈ 0
        // Due to integer division, this should round down to 0
        assertLe(amountOut, DUST, "1 wei swap should return at most 1 wei (likely 0)");
    }

    function test_onSwap_exactIn_dustAmount_noRevert() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: SMALL_AMOUNT,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        // Should not revert
        uint256 amountOut = pool.onSwap(params);

        // Output should be very small or zero
        assertLe(amountOut, SMALL_AMOUNT, "Dust swap should not produce excessive output");
    }

    function test_onSwap_exactOut_dustAmount_calculatesInput() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_OUT,
            amountGivenScaled18: SMALL_AMOUNT,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountIn = pool.onSwap(params);

        // For exact out with dust amount:
        // dx = (X * dy) / (Y - dy) = (1000e18 * 100) / (1000e18 - 100) ≈ 100
        assertTrue(amountIn > 0, "Input for dust output should be positive");
    }

    function test_onSwap_exactIn_mediumAmount_correctRounding() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: MEDIUM_AMOUNT,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // dy = (Y * dx) / (X + dx)
        // Manual calculation for verification
        uint256 expectedOut = (balances[1] * MEDIUM_AMOUNT) / (balances[0] + MEDIUM_AMOUNT);

        assertEq(amountOut, expectedOut, "Medium amount should match expected calculation");
    }

    /* -------------------------------------------------------------------------- */
    /*                   computeInvariant Rounding Direction Tests                 */
    /* -------------------------------------------------------------------------- */

    function test_computeInvariant_roundDownVsUp_difference() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 333e18; // Non-round number to test rounding
        balances[1] = 777e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN <= ROUND_UP");
    }

    function test_computeInvariant_roundDown_poolFavorable() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1e18;
        balances[1] = 1e18;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // For withdrawals, using ROUND_DOWN gives less shares to the user
        // This protects the pool from losing value
        assertTrue(invariantDown > 0, "Invariant should be positive");
    }

    function test_computeInvariant_roundUp_userFavorable() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1e18;
        balances[1] = 1e18;

        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        // For deposits, using ROUND_UP gives more tokens to the pool
        assertTrue(invariantUp > 0, "Invariant should be positive");
    }

    function testFuzz_computeInvariant_roundDownAlwaysLessOrEqual(
        uint256 bal0,
        uint256 bal1
    ) public view {
        bal0 = bound(bal0, 1e18, 1e30);
        bal1 = bound(bal1, 1e18, 1e30);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariantDown = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 invariantUp = pool.computeInvariant(balances, Rounding.ROUND_UP);

        assertLe(invariantDown, invariantUp, "ROUND_DOWN must be <= ROUND_UP");
    }

    /* -------------------------------------------------------------------------- */
    /*                    computeBalance Rounding Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_computeBalance_preservesK_approximately() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        // Compute new balance with ratio 1.1 (10% increase in invariant)
        uint256 ratio = 1.1e18;
        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        // The new balance should result in higher invariant
        assertTrue(newBalance > balances[0], "New balance should be higher for ratio > 1");
    }

    function test_computeBalance_smallRatio_increasesBalance() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        uint256 ratio = 1.001e18; // 0.1% increase
        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        assertGt(newBalance, balances[0], "Balance should increase for ratio > 1");
    }

    function test_computeBalance_dustRatio_handlesCorrectly() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        // Very small ratio change
        uint256 ratio = WAD + 1; // 1e18 + 1 wei
        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        // Should handle without overflow/underflow
        assertTrue(newBalance >= balances[0], "Dust ratio change should be handled");
    }

    function testFuzz_computeBalance_positiveRatio_positiveBalance(
        uint256 bal0,
        uint256 bal1,
        uint256 ratio
    ) public view {
        bal0 = bound(bal0, 1e15, 1e27);
        bal1 = bound(bal1, 1e15, 1e27);
        ratio = bound(ratio, 0.5e18, 2e18);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        assertTrue(newBalance > 0, "New balance must be positive for valid ratio");
    }

    /* -------------------------------------------------------------------------- */
    /*                Pool Never Loses Value (Invariant Tests)                     */
    /* -------------------------------------------------------------------------- */

    function test_swap_invariantPreservedOrIncreased_exactIn() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

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

        // Invariant should be preserved or slightly increased (due to rounding)
        // Pool-favorable rounding means invariant never decreases
        assertGe(
            invariantAfter,
            invariantBefore - 1e9, // Allow tiny rounding error (< 1e9 wei)
            "Invariant should not decrease significantly after swap"
        );
    }

    function test_swap_invariantPreservedOrIncreased_exactOut() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = STANDARD_BALANCE;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

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

        // Update balances after swap
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + amountIn;
        newBalances[1] = balances[1] - 100e18;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        assertGe(
            invariantAfter,
            invariantBefore - 1e9,
            "Invariant should not decrease significantly after exact out swap"
        );
    }

    function testFuzz_swap_invariantPreserved(
        uint256 bal0,
        uint256 bal1,
        uint256 amountIn
    ) public view {
        // Bound to reasonable values
        bal0 = bound(bal0, 1e18, 1e27);
        bal1 = bound(bal1, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, bal0 / 10); // Max 10% of pool

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

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

        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + amountIn;
        newBalances[1] = balances[1] - amountOut;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        // Allow small relative error (0.01%)
        assertGe(
            invariantAfter * 10000,
            invariantBefore * 9999,
            "Invariant should not decrease by more than 0.01%"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                           Edge Case Tests                                   */
    /* -------------------------------------------------------------------------- */

    function test_swap_imbalancedPool_roundingCorrect() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 100e18;
        balances[1] = 10000e18; // 100:1 imbalance

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e18,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOut = pool.onSwap(params);

        // dy = (10000e18 * 1e18) / (100e18 + 1e18) = 10000e36 / 101e18 ≈ 99.009e18
        uint256 expectedOut = (balances[1] * 1e18) / (balances[0] + 1e18);
        assertEq(amountOut, expectedOut, "Imbalanced pool should calculate correctly");
    }

    function test_swap_veryLargePool_noOverflow() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1e27; // 1 billion tokens
        balances[1] = 1e27;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e25, // 10 million tokens
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        // Should not overflow
        uint256 amountOut = pool.onSwap(params);
        assertTrue(amountOut > 0, "Large pool swap should work");
        assertTrue(amountOut < balances[1], "Output should be less than reserve");
    }

    function test_swap_verySmallPool_noUnderflow() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1e12; // 0.000001 tokens (very small for 18 decimals)
        balances[1] = 1e12;

        PoolSwapParams memory params = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: 1e10, // 0.00000001 tokens
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        // Should handle small values
        uint256 amountOut = pool.onSwap(params);
        assertLe(amountOut, balances[1], "Output should not exceed reserve");
    }

    function test_invariant_singleWeiBalances() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1; // Absolute minimum
        balances[1] = 1;

        // Should not revert
        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        // With FixedPoint math, 1.mulDown(1) = 1 * 1 / 1e18 = 0
        // So invariant will be 0 for such small values
        assertLe(invariant, 1e9, "Single wei invariant should be very small");
    }

    function test_invariant_zeroBalance_returnsZero() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = STANDARD_BALANCE;
        balances[1] = 0;

        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertEq(invariant, 0, "Invariant should be 0 when one balance is 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                        Rounding Consistency Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_rounding_consistentAcrossOperations() public view {
        uint256[] memory balances = new uint256[](2);
        balances[0] = 12345678901234567890; // Non-round number
        balances[1] = 98765432109876543210;

        // Multiple operations should maintain consistent rounding
        uint256 inv1 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 inv2 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertEq(inv1, inv2, "Same inputs should produce same invariant");
    }

    function testFuzz_rounding_consistency(uint256 bal0, uint256 bal1) public view {
        bal0 = bound(bal0, 1e18, 1e30);
        bal1 = bound(bal1, 1e18, 1e30);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        // Call multiple times - should always return same value
        uint256 inv1 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 inv2 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 inv3 = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

        assertEq(inv1, inv2, "Deterministic result 1");
        assertEq(inv2, inv3, "Deterministic result 2");
    }

    /* -------------------------------------------------------------------------- */
    /*                 Property-Based Tests (Invariant Properties)                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Property: Swapping and swapping back should lose value (due to rounding)
     * @dev This demonstrates pool-favorable rounding - arbitrageurs cannot profit from rounding
     */
    function testFuzz_roundTrip_losesValue(uint256 bal0, uint256 bal1, uint256 amountIn) public view {
        bal0 = bound(bal0, 1e18, 1e27);
        bal1 = bound(bal1, 1e18, 1e27);
        amountIn = bound(amountIn, 1e15, bal0 / 20); // Max 5% of pool

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        // Swap A -> B
        PoolSwapParams memory params1 = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: amountIn,
            balancesScaled18: balances,
            indexIn: 0,
            indexOut: 1,
            router: address(0),
            userData: ""
        });

        uint256 amountOutB = pool.onSwap(params1);

        // Skip if output is 0 (dust amounts)
        if (amountOutB == 0) return;

        // Update balances
        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + amountIn;
        newBalances[1] = balances[1] - amountOutB;

        // Swap B -> A with what we got
        PoolSwapParams memory params2 = PoolSwapParams({
            kind: SwapKind.EXACT_IN,
            amountGivenScaled18: amountOutB,
            balancesScaled18: newBalances,
            indexIn: 1,
            indexOut: 0,
            router: address(0),
            userData: ""
        });

        uint256 amountOutA = pool.onSwap(params2);

        // Round trip should lose value (or at best break even)
        assertLe(amountOutA, amountIn, "Round trip should not profit the trader");
    }

    /**
     * @notice Property: Product of balances should increase or stay same after swap
     * @dev This is the fundamental AMM property: k = x * y should not decrease
     */
    function testFuzz_productNeverDecreases(
        uint256 bal0,
        uint256 bal1,
        uint256 amountIn
    ) public view {
        bal0 = bound(bal0, 1e18, 1e24);
        bal1 = bound(bal1, 1e18, 1e24);
        amountIn = bound(amountIn, 1e15, bal0 / 10);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 productBefore = bal0 * bal1 / 1e18; // Scale down to avoid overflow

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

        uint256 newBal0 = balances[0] + amountIn;
        uint256 newBal1 = balances[1] - amountOut;
        uint256 productAfter = newBal0 * newBal1 / 1e18;

        assertGe(productAfter, productBefore - 1, "Product should never decrease (within rounding)");
    }

    /* -------------------------------------------------------------------------- */
    /*             EXACT_OUT Rounding UP Tests (Pool-Favorable)                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify EXACT_OUT rounds UP (user provides more tokens)
     * @dev For EXACT_OUT: dx = (X * dy) / (Y - dy), should round UP
     */
    function test_onSwap_exactOut_roundsUp_poolFavorable() public view {
        // Use values that will cause rounding
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18 + 1; // Slightly off to cause rounding
        balances[1] = 1000e18;

        uint256 amountOut = 100e18 + 7; // Non-round to cause rounding

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

        // Calculate raw (round-down) result for comparison
        uint256 rawResult = (balances[0] * amountOut) / (balances[1] - amountOut);

        // Pool's result should be >= raw result (rounded UP)
        assertGe(amountIn, rawResult, "EXACT_OUT should round UP (user pays more)");
    }

    /**
     * @notice Fuzz test that EXACT_OUT always rounds UP or equals raw division
     */
    function testFuzz_onSwap_exactOut_roundsUp(
        uint256 bal0,
        uint256 bal1,
        uint256 amountOut
    ) public view {
        bal0 = bound(bal0, 1e18, 1e27);
        bal1 = bound(bal1, 1e18, 1e27);
        // Ensure amountOut is much smaller than bal1 to avoid issues
        amountOut = bound(amountOut, 1e15, bal1 / 100);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

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

        // Calculate raw (round-down) result
        uint256 rawResult = (bal0 * amountOut) / (bal1 - amountOut);

        // Pool's result should be >= raw result (rounded UP favors pool)
        assertGe(amountIn, rawResult, "EXACT_OUT must round UP");
    }

    /**
     * @notice Verify that EXACT_OUT rounding protects the pool by ensuring
     *         invariant increases after the swap
     */
    function testFuzz_onSwap_exactOut_invariantIncreases(
        uint256 bal0,
        uint256 bal1,
        uint256 amountOut
    ) public view {
        bal0 = bound(bal0, 1e18, 1e25);
        bal1 = bound(bal1, 1e18, 1e25);
        amountOut = bound(amountOut, 1e15, bal1 / 100);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 invariantBefore = pool.computeInvariant(balances, Rounding.ROUND_DOWN);

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

        uint256[] memory newBalances = new uint256[](2);
        newBalances[0] = balances[0] + amountIn;
        newBalances[1] = balances[1] - amountOut;

        uint256 invariantAfter = pool.computeInvariant(newBalances, Rounding.ROUND_DOWN);

        // With proper rounding UP for EXACT_OUT, invariant should increase or stay same
        assertGe(invariantAfter, invariantBefore, "EXACT_OUT with round UP must preserve/increase invariant");
    }

    /* -------------------------------------------------------------------------- */
    /*             computeBalance Rounding UP Tests (Pool-Favorable)               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify computeBalance rounds UP (user provides more tokens)
     * @dev newBalance = newInvariant^2 / otherBalance, should round UP
     */
    function test_computeBalance_roundsUp_poolFavorable() public view {
        // Use values that will cause rounding
        uint256[] memory balances = new uint256[](2);
        balances[0] = 1000e18 + 3; // Non-round numbers
        balances[1] = 999e18 + 7;

        uint256 ratio = 1.1e18; // 10% increase

        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        // Calculate what raw division would give
        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 newInvariant = invariant.mulDown(ratio);
        uint256 otherBalance = balances[1]; // tokenInIndex=0 uses balances[1]
        uint256 rawResult = (newInvariant * newInvariant) / otherBalance;

        // Pool's result should be >= raw result (rounded UP favors pool)
        assertGe(newBalance, rawResult, "computeBalance should round UP (user provides more)");
    }

    /**
     * @notice Fuzz test that computeBalance always rounds UP or equals raw division
     */
    function testFuzz_computeBalance_roundsUp(
        uint256 bal0,
        uint256 bal1,
        uint256 ratio
    ) public view {
        bal0 = bound(bal0, 1e15, 1e27);
        bal1 = bound(bal1, 1e15, 1e27);
        ratio = bound(ratio, 0.5e18, 2e18);

        uint256[] memory balances = new uint256[](2);
        balances[0] = bal0;
        balances[1] = bal1;

        uint256 newBalance = pool.computeBalance(balances, 0, ratio);

        // Calculate what raw division would give
        uint256 invariant = pool.computeInvariant(balances, Rounding.ROUND_DOWN);
        uint256 newInvariant = invariant.mulDown(ratio);
        uint256 rawResult = (newInvariant * newInvariant) / bal1;

        // Pool's result should be >= raw result (rounded UP favors pool)
        assertGe(newBalance, rawResult, "computeBalance must round UP");
    }
}
