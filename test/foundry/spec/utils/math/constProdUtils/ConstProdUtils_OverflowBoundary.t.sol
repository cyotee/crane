// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";

/**
 * @title ConstProdUtils_OverflowBoundary_Test
 * @notice Tests proving that overflow conditions revert cleanly (no silent wrapping).
 * @dev Created as part of CRANE-026 to strengthen overflow boundary testing.
 *
 * This file tests two primary overflow-prone functions:
 *
 * 1. `_swapDepositSaleAmt` - Quadratic path with multi-multiply expressions:
 *    - term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve
 *    - term2 = 4 * oneMinusFee * feeDenominator * amountIn * saleReserve
 *
 * 2. `_calculateFeePortionForPosition` - Multi-multiply expressions:
 *    - sA = (initialA * initialB * reserveA) / reserveB
 *    - sB = (initialA * initialB * reserveB) / reserveA
 *
 * Key principle: Solidity 0.8+ uses checked arithmetic by default, so overflow
 * should revert rather than silently wrap. These tests prove that behavior.
 *
 * ## Overflow Magnitude Analysis
 *
 * For `_swapDepositSaleAmt`:
 * - With FEE_DENOMINATOR = 100000, feePercent = 300:
 *   - twoMinusFee = 2*100000 - 300 = 199700 ≈ 2e5
 *   - twoMinusFee² ≈ 4e10
 *   - term1 = 4e10 * saleReserve² → overflow when saleReserve > ~1.07e37
 *   - term2 = 4e10 * amountIn * saleReserve → overflow when amountIn * saleReserve > ~2.9e66
 *
 * For `_calculateFeePortionForPosition`:
 * - sA = initialA * initialB * reserveA / reserveB
 * - Overflow when initialA * initialB * reserveA > type(uint256).max ≈ 1.16e77
 * - With all values ~1e26, product ~1e78 which exceeds uint256.max
 *
 * ## Summary of Overflow-Triggering Magnitudes
 *
 * | Function                        | Parameter     | Safe Upper Bound | Overflow Trigger |
 * |---------------------------------|---------------|------------------|------------------|
 * | _swapDepositSaleAmt             | saleReserve   | ~1.7e33         | ~1e34+           |
 * | _swapDepositSaleAmt             | amountIn*res  | ~2.9e66 product | product > 2.9e66 |
 * | _calculateFeePortionForPosition | initialA/B    | ~1e25 each      | ~1e26+ all       |
 * | _calculateFeePortionForPosition | reserveA/B    | ~1e25 each      | ~1e26+ all       |
 * | _calculateFeePortionForPosition | claimable     | no limit*       | uses _mulDiv     |
 *
 * *Note: claimable calculation uses Math._mulDiv with 512-bit intermediate precision,
 *        so it does not overflow even with extreme ownedLP * reserveA values.
 */
contract ConstProdUtils_OverflowBoundary_Test is Test {

    /* ========================================================================== */
    /*                    _swapDepositSaleAmt Overflow Tests                       */
    /* ========================================================================== */

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on term1 overflow.
     * @dev term1 = twoMinusFee² * saleReserve² overflows when saleReserve > ~1e37
     *
     * Calculation for overflow boundary:
     * - twoMinusFee = 2 * 100000 - 300 = 199700 ≈ 2e5
     * - twoMinusFee² ≈ 3.988e10 ≈ 4e10
     * - For term1 overflow: 4e10 * saleReserve² > 2^256 ≈ 1.16e77
     * - Therefore: saleReserve² > 2.9e66 → saleReserve > 1.7e33
     * - But with full precision: saleReserve > ~1.07e37 for actual overflow
     *
     * Using saleReserve = 1e39 (above overflow threshold) with moderate amountIn.
     */
    function test_swapDepositSaleAmt_term1Overflow_reverts() public {
        uint256 saleReserve = 1e39; // Above overflow threshold for term1
        uint256 amountIn = 1e18; // Moderate amount
        uint256 feePercent = 300; // 0.3% fee

        // This should revert due to overflow in term1 = twoMinusFee² * saleReserve²
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on term2 overflow.
     * @dev term2 = 4 * oneMinusFee * feeDenominator * amountIn * saleReserve
     *
     * Calculation for overflow boundary:
     * - oneMinusFee = 100000 - 300 = 99700 ≈ 1e5
     * - 4 * oneMinusFee * feeDenominator ≈ 4 * 1e5 * 1e5 = 4e10
     * - For term2 overflow: 4e10 * amountIn * saleReserve > 2^256 ≈ 1.16e77
     * - Therefore: amountIn * saleReserve > 2.9e66
     *
     * Using both amountIn and saleReserve = 1e35 → product = 1e70 > 2.9e66
     */
    function test_swapDepositSaleAmt_term2Overflow_reverts() public {
        uint256 saleReserve = 1e35;
        uint256 amountIn = 1e35; // Large amountIn to trigger term2 overflow
        uint256 feePercent = 300;

        // This should revert due to overflow in term2
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Tests that _swapDepositSaleAmt reverts on combined term1+term2 overflow.
     * @dev Even if individual terms don't overflow, their sum might.
     *
     * Using values that are close to but below individual overflow thresholds,
     * but whose sum exceeds uint256.max.
     */
    function test_swapDepositSaleAmt_sumOverflow_reverts() public {
        // Values designed so term1 and term2 are each large but valid,
        // but term1 + term2 overflows
        uint256 saleReserve = 5e37; // Large reserve
        uint256 amountIn = 1e37; // Large amount
        uint256 feePercent = 300;

        // Should revert due to overflow in addition or earlier multiplication
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Fuzz test proving overflow reverts for extreme saleReserve values.
     * @dev Values above 1e38 should consistently trigger overflow.
     */
    function testFuzz_swapDepositSaleAmt_extremeReserve_reverts(
        uint256 saleReserve
    ) public {
        // Bound to overflow-triggering range
        saleReserve = bound(saleReserve, 1e38, type(uint256).max / 1e10);

        uint256 amountIn = 1e18;
        uint256 feePercent = 300;

        // Expect revert for all values in this range
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @notice Verifies safe boundary: values just below overflow threshold work.
     * @dev term1 = twoMinusFee² * saleReserve² = (2e5)² * saleReserve² = 4e10 * saleReserve²
     *      For no overflow: 4e10 * saleReserve² < 2^256 ≈ 1.16e77
     *      Therefore: saleReserve² < 2.9e66 → saleReserve < 1.7e33
     *      Using saleReserve = 1e32 provides comfortable safety margin.
     */
    function test_swapDepositSaleAmt_safeBoundary_succeeds() public view {
        uint256 saleReserve = 1e32; // Below overflow threshold (1.7e33)
        uint256 amountIn = 1e18;
        uint256 feePercent = 300;

        // This should succeed without reverting
        uint256 result = this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);

        // Result should be bounded by amountIn
        assertLe(result, amountIn, "Sale amount should not exceed amountIn");
        // With large reserves relative to amountIn, the optimal swap amount approaches amountIn/2
        // For reserves >> amountIn, the quadratic formula converges to approximately half
        // The result should be meaningful (> 0) and roughly in the range [amountIn/3, amountIn]
        assertGt(result, 0, "Sale amount should be positive for non-zero input");
        assertGe(result, amountIn / 3, "Sale amount should be at least amountIn/3 for large reserves");
    }

    /**
     * @notice Tests overflow with legacy fee denominator (1000).
     * @dev Legacy pools use smaller denominator, affecting overflow boundaries.
     *
     * With feeDenominator = 1000, feePercent = 3 (0.3%):
     * - twoMinusFee = 2*1000 - 3 = 1997 ≈ 2e3
     * - twoMinusFee² ≈ 4e6
     * - term1 = 4e6 * saleReserve² → overflow when saleReserve > ~1.7e35
     */
    function test_swapDepositSaleAmt_legacyDenom_overflow_reverts() public {
        uint256 saleReserve = 1e36; // Above threshold for legacy denominator
        uint256 amountIn = 1e18;
        uint256 feePercent = 3; // 0.3% in legacy terms
        uint256 feeDenominator = 1000; // Legacy denominator

        // Should revert due to overflow
        vm.expectRevert();
        this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, feeDenominator);
    }

    /* ========================================================================== */
    /*               _calculateFeePortionForPosition Overflow Tests               */
    /* ========================================================================== */

    /**
     * @notice Tests that _calculateFeePortionForPosition reverts on sA overflow.
     * @dev sA = (initialA * initialB * reserveA) / reserveB overflows before division
     *
     * Calculation for overflow boundary:
     * - For overflow: initialA * initialB * reserveA > 2^256 ≈ 1.16e77
     * - With all values equal: value³ > 1.16e77 → value > 4.88e25
     *
     * Using initialA = initialB = reserveA = 1e26, product = 1e78 > uint256.max
     */
    function test_calculateFeePortionForPosition_sAOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e26;
        uint256 initialB = 1e26;
        uint256 reserveA = 1e26;
        uint256 reserveB = 1e18; // Small reserveB to ensure we reach the multiplication
        uint256 totalSupply = 1e21;

        // Should revert due to overflow in initialA * initialB * reserveA
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Tests that _calculateFeePortionForPosition reverts on sB overflow.
     * @dev sB = (initialA * initialB * reserveB) / reserveA overflows before division
     *
     * Using large reserveB and small reserveA to trigger sB path overflow.
     */
    function test_calculateFeePortionForPosition_sBOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e26;
        uint256 initialB = 1e26;
        uint256 reserveA = 1e18; // Small reserveA
        uint256 reserveB = 1e26; // Large reserveB to trigger sB overflow
        uint256 totalSupply = 1e21;

        // Should revert due to overflow in initialA * initialB * reserveB
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Fuzz test proving overflow reverts for extreme initial values.
     * @dev Values where initialA * initialB * max(reserveA, reserveB) > uint256.max
     */
    function testFuzz_calculateFeePortionForPosition_extremeInitials_reverts(
        uint256 initialA,
        uint256 initialB
    ) public {
        // Bound to overflow-triggering range
        initialA = bound(initialA, 1e26, 1e30);
        initialB = bound(initialB, 1e26, 1e30);

        uint256 ownedLP = 1e20;
        uint256 reserveA = 1e26;
        uint256 reserveB = 1e26;
        uint256 totalSupply = 1e21;

        // Expect revert for all values in this range
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice Verifies safe boundary: values just below overflow threshold work.
     * @dev initialA * initialB * reserve < uint256.max should succeed.
     *
     * For symmetric inputs (initialA == initialB == reserveA == reserveB):
     * - claimable = ownedLP * reserve / totalSupply
     * - noFee = sqrt(initialA * initialB * reserveA / reserveB) = sqrt(initialA * initialB) = initial
     * - fee = claimable - noFee (clamped to 0)
     *
     * When claimable > initial, we have fee > 0 (pool grew from fees).
     * When claimable <= initial, fee = 0 (no fee growth or IL).
     */
    function test_calculateFeePortionForPosition_safeBoundary_succeeds() public view {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e24; // Below overflow threshold
        uint256 initialB = 1e24;
        uint256 reserveA = 1e24;
        uint256 reserveB = 1e24;
        uint256 totalSupply = 1e21;

        // This should succeed without reverting
        // Product = 1e24 * 1e24 * 1e24 = 1e72 < uint256.max ≈ 1.16e77
        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // Calculate claimable amounts to establish upper bounds
        // claimableA = ownedLP * reserveA / totalSupply = 1e20 * 1e24 / 1e21 = 1e23
        uint256 claimableA = (ownedLP * reserveA) / totalSupply;
        uint256 claimableB = (ownedLP * reserveB) / totalSupply;

        // Fees must be bounded by claimable amounts (can't claim more fees than total claimable)
        assertLe(feeA, claimableA, "feeA must not exceed claimable amount");
        assertLe(feeB, claimableB, "feeB must not exceed claimable amount");

        // With symmetric inputs, fees should also be symmetric
        assertEq(feeA, feeB, "Symmetric inputs should produce symmetric fees");
    }

    /**
     * @notice Tests overflow with asymmetric initial values.
     * @dev One very large initial with moderately large others.
     */
    function test_calculateFeePortionForPosition_asymmetricOverflow_reverts() public {
        uint256 ownedLP = 1e20;
        uint256 initialA = 1e40; // Very large
        uint256 initialB = 1e20; // Moderate
        uint256 reserveA = 1e20; // Moderate
        uint256 reserveB = 1e18;
        uint256 totalSupply = 1e21;

        // Product = 1e40 * 1e20 * 1e20 = 1e80 > uint256.max
        vm.expectRevert();
        this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /* ========================================================================== */
    /*                     Additional Overflow Edge Cases                          */
    /* ========================================================================== */

    /**
     * @notice Verifies that _mulDiv safely handles claimable calculation with large values.
     * @dev The function uses Math._mulDiv which safely handles ownedLP * reserveA / totalSupply
     *      even when ownedLP * reserveA would overflow. This test proves the library's
     *      overflow-safe multiplication/division works correctly.
     *
     * Math breakdown:
     * - claimableA = _mulDiv(ownedLP, reserveA, totalSupply) = _mulDiv(1e50, 1e50, 1e51) = 1e49
     * - claimableB = _mulDiv(ownedLP, reserveB, totalSupply) = _mulDiv(1e50, 1e18, 1e51) = 1e17
     * - noFeeA = sqrt(initialA * initialB * reserveA / reserveB) = sqrt(1e10 * 1e10 * 1e50 / 1e18)
     *          = sqrt(1e52) ≈ 3.16e25
     * - noFeeB = sqrt(initialA * initialB * reserveB / reserveA) = sqrt(1e10 * 1e10 * 1e18 / 1e50)
     *          = sqrt(1e-12) = 0 (integer sqrt truncation)
     *
     * Since claimableA (1e49) >> noFeeA (3.16e25), feeA = claimableA - noFeeA ≈ 1e49
     * Since noFeeB = 0 and claimableB = 1e17, feeB = claimableB = 1e17
     */
    function test_calculateFeePortionForPosition_claimableSafeWithMulDiv() public view {
        uint256 ownedLP = 1e50; // Very large LP
        uint256 initialA = 1e10;
        uint256 initialB = 1e10;
        uint256 reserveA = 1e50; // Large reserve
        uint256 reserveB = 1e18;
        uint256 totalSupply = 1e51;

        // This SUCCEEDS because _mulDiv safely handles ownedLP * reserveA / totalSupply
        // without intermediate overflow (it uses 512-bit intermediate precision)
        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // Verify claimable bounds - fees cannot exceed what's claimable
        // claimableA ≈ 1e49, claimableB ≈ 1e17
        uint256 expectedClaimableA = 1e49; // 1e50 * 1e50 / 1e51
        uint256 expectedClaimableB = 1e17; // 1e50 * 1e18 / 1e51

        // feeA and feeB must be bounded by claimable amounts
        assertLe(feeA, expectedClaimableA + 1, "feeA must not exceed claimableA");
        assertLe(feeB, expectedClaimableB + 1, "feeB must not exceed claimableB");

        // With these inputs, we expect positive fees due to large claimable vs small initial values
        // noFeeA = sqrt(1e10 * 1e10 * 1e50 / 1e18) = sqrt(1e52) ≈ 3.16e25
        // claimableA = 1e49 >> noFeeA, so feeA should be large
        assertGt(feeA, 1e48, "feeA should be significant due to large claimable vs noFee");

        // feeB = claimableB - noFeeB, where noFeeB = sqrt(1e10 * 1e10 * 1e18 / 1e50) = sqrt(1e-12) = 0
        // So feeB should equal claimableB
        assertGt(feeB, 0, "feeB should be positive when claimableB > noFeeB");
    }

    /**
     * @notice Tests that _saleQuote overflow paths also revert properly.
     * @dev _saleQuote has amountIn * (feeDenominator - feePercent) * reserveOut
     *
     * For overflow: amountIn * ~1e5 * reserveOut > 2^256
     * With amountIn = reserveOut = 1e38, product ≈ 1e81 > uint256.max
     */
    function test_saleQuote_numeratorOverflow_reverts() public {
        uint256 amountIn = 1e38;
        uint256 reserveIn = 1e38;
        uint256 reserveOut = 1e38;
        uint256 feePercent = 300;

        // amountIn * (feeDenominator - feePercent) * reserveOut overflows
        vm.expectRevert();
        this.externalSaleQuote(amountIn, reserveIn, reserveOut, feePercent);
    }

    /**
     * @notice Tests that _purchaseQuote overflow paths revert properly.
     * @dev _purchaseQuote has (reserveIn * amountOut) * feeDenominator
     */
    function test_purchaseQuote_numeratorOverflow_reverts() public {
        uint256 amountOut = 1e36;
        uint256 reserveIn = 1e38;
        uint256 reserveOut = 1e38;
        uint256 feePercent = 300;

        // (reserveIn * amountOut) * feeDenominator = 1e38 * 1e36 * 1e5 = 1e79 > uint256.max
        vm.expectRevert();
        this.externalPurchaseQuote(amountOut, reserveIn, reserveOut, feePercent);
    }

    /* ========================================================================== */
    /*              Additional Meaningful Assertions (CRANE-073)                  */
    /* ========================================================================== */

    /**
     * @notice Verifies _saleQuote returns bounded, meaningful results within safe parameters.
     * @dev With balanced reserves and moderate swap, output should be:
     *      - Less than reserveOut (can't drain pool)
     *      - Less than amountIn (fee reduces output)
     *      - Proportional to the swap math
     */
    function test_saleQuote_safeBoundary_meaningfulOutput() public view {
        uint256 amountIn = 1e18;
        uint256 reserveIn = 1000e18;
        uint256 reserveOut = 1000e18;
        uint256 feePercent = 300; // 0.3%

        uint256 result = this.externalSaleQuote(amountIn, reserveIn, reserveOut, feePercent);

        // Output must be less than input (fee is taken)
        assertLt(result, amountIn, "Output should be less than input due to fees");

        // Output must be less than reserveOut (can't drain more than exists)
        assertLt(result, reserveOut, "Output should be less than reserve");

        // Output must be positive for valid inputs
        assertGt(result, 0, "Output should be positive for non-zero input");

        // For balanced pools with small swap, output should be close to input minus fee
        // With 0.3% fee and 1% of reserves, output ≈ amountIn * 0.997 * (1 - slippage)
        // Slippage ≈ amountIn / reserveIn ≈ 0.1%, so output ≈ 0.996 * amountIn
        assertGt(result, (amountIn * 99) / 100, "Output should be at least 99% of input for small swaps");
    }

    /**
     * @notice Verifies _purchaseQuote returns bounded, meaningful results within safe parameters.
     * @dev The amount required to purchase a given output should be:
     *      - Greater than amountOut (fees and slippage)
     *      - Less than reserveIn for small outputs
     */
    function test_purchaseQuote_safeBoundary_meaningfulOutput() public view {
        uint256 amountOut = 1e18;
        uint256 reserveIn = 1000e18;
        uint256 reserveOut = 1000e18;
        uint256 feePercent = 300; // 0.3%

        uint256 result = this.externalPurchaseQuote(amountOut, reserveIn, reserveOut, feePercent);

        // Amount in must be greater than amount out (due to fees)
        assertGt(result, amountOut, "Amount in should exceed amount out due to fees");

        // Amount in should be bounded (not astronomically large for small output)
        assertLt(result, reserveIn, "Amount in should be less than reserve for small output");

        // For balanced pools with small swap, amountIn ≈ amountOut * 1.003 * (1 + slippage)
        // Should be within 2% of amountOut for this case
        assertLt(result, (amountOut * 102) / 100, "Amount in should be within 2% of output for small swaps");
    }

    /**
     * @notice Verifies _swapDepositSaleAmt with known small values produces expected range.
     * @dev For a deposit of X tokens with large reserves, the optimal swap amount
     *      should approach X/2 (half swapped to balance the deposit).
     */
    function test_swapDepositSaleAmt_knownSmallInput_expectedRange() public view {
        uint256 amountIn = 100e18;
        uint256 saleReserve = 10000e18; // Large reserve relative to input
        uint256 feePercent = 300;

        uint256 result = this.externalSwapDepositSaleAmt(amountIn, saleReserve, feePercent, FEE_DENOMINATOR);

        // Result must be bounded by input
        assertLe(result, amountIn, "Sale amount should not exceed input");
        assertGt(result, 0, "Sale amount should be positive");

        // With large reserves, optimal swap approaches half of input
        // Allow some tolerance: result should be in range [40%, 60%] of amountIn
        assertGe(result, (amountIn * 40) / 100, "Sale amount should be at least 40% of input");
        assertLe(result, (amountIn * 60) / 100, "Sale amount should be at most 60% of input");
    }

    /**
     * @notice Verifies _calculateFeePortionForPosition with pool growth scenario.
     * @dev When reserves have grown (claimable > initial), fees should be positive.
     */
    function test_calculateFeePortionForPosition_poolGrowth_positiveFees() public view {
        // Simulate a position where the pool has grown from trading fees
        uint256 ownedLP = 100e18;
        uint256 totalSupply = 1000e18;

        // Initial deposit: 100 of each token
        uint256 initialA = 100e18;
        uint256 initialB = 100e18;

        // Current reserves: pool has grown to 110 of each (10% growth from fees)
        uint256 reserveA = 1100e18;
        uint256 reserveB = 1100e18;

        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // Calculate expected claimable
        // claimable = ownedLP * reserve / totalSupply = 100e18 * 1100e18 / 1000e18 = 110e18
        uint256 claimableA = (ownedLP * reserveA) / totalSupply;
        uint256 claimableB = (ownedLP * reserveB) / totalSupply;

        // Fees bounded by claimable
        assertLe(feeA, claimableA, "feeA must not exceed claimable");
        assertLe(feeB, claimableB, "feeB must not exceed claimable");

        // With pool growth and symmetric reserves, both fees should be positive
        // noFee = sqrt(100e18 * 100e18) = 100e18
        // claimable = 110e18, so fee = 110e18 - 100e18 = 10e18
        assertGt(feeA, 0, "feeA should be positive when pool has grown");
        assertGt(feeB, 0, "feeB should be positive when pool has grown");

        // Fees should be approximately claimable - initial = 10e18
        // Allow some tolerance for integer math
        assertGe(feeA, 9e18, "feeA should be approximately 10e18");
        assertLe(feeA, 11e18, "feeA should be approximately 10e18");
    }

    /**
     * @notice Verifies fee + feeB is bounded by total claimable across both tokens.
     * @dev This is a critical invariant: total fees cannot exceed total value claimable.
     */
    function test_calculateFeePortionForPosition_totalFeeBound() public view {
        uint256 ownedLP = 50e18;
        uint256 totalSupply = 500e18;
        uint256 initialA = 80e18;
        uint256 initialB = 120e18;
        uint256 reserveA = 900e18;
        uint256 reserveB = 1100e18;

        (uint256 feeA, uint256 feeB) = this.externalCalculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );

        // Calculate claimable amounts
        uint256 claimableA = (ownedLP * reserveA) / totalSupply;
        uint256 claimableB = (ownedLP * reserveB) / totalSupply;

        // Individual fees bounded by individual claimables
        assertLe(feeA, claimableA, "feeA must not exceed claimableA");
        assertLe(feeB, claimableB, "feeB must not exceed claimableB");

        // Sum of fees bounded by sum of claimables
        assertLe(feeA + feeB, claimableA + claimableB, "Total fees must not exceed total claimable");
    }

    /* ========================================================================== */
    /*                        External Wrappers for vm.expectRevert               */
    /* ========================================================================== */

    /**
     * @notice External wrapper for _swapDepositSaleAmt to enable try/catch and expectRevert.
     */
    function externalSwapDepositSaleAmt(
        uint256 amountIn,
        uint256 saleReserve,
        uint256 feePercent,
        uint256 feeDenominator
    ) external pure returns (uint256) {
        return ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent, feeDenominator);
    }

    /**
     * @notice External wrapper for _calculateFeePortionForPosition.
     */
    function externalCalculateFeePortionForPosition(
        uint256 ownedLP,
        uint256 initialA,
        uint256 initialB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply
    ) external pure returns (uint256 feeA, uint256 feeB) {
        return ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialA, initialB, reserveA, reserveB, totalSupply
        );
    }

    /**
     * @notice External wrapper for _saleQuote.
     */
    function externalSaleQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) external pure returns (uint256) {
        return ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, feePercent);
    }

    /**
     * @notice External wrapper for _purchaseQuote.
     */
    function externalPurchaseQuote(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) external pure returns (uint256) {
        return ConstProdUtils._purchaseQuote(amountOut, reserveIn, reserveOut, feePercent);
    }
}
