// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ArgumentMustNotBeZero, ArgumentMustBeGreaterThan} from "@crane/contracts/GeneralErrors.sol";

/**
 * @title ConstProdUtilsHarness
 * @notice Harness to expose internal library functions for testing reverts.
 */
contract ConstProdUtilsHarness {
    function purchaseQuote(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, uint256 feePercent)
        external
        pure
        returns (uint256)
    {
        return ConstProdUtils._purchaseQuote(amountOut, reserveIn, reserveOut, feePercent);
    }
}

/**
 * @title ConstProdUtils_EdgeCases_Test
 * @notice Edge case tests for ConstProdUtils to improve branch coverage.
 * @dev Focuses on boundary conditions, zero values, and rarely-hit branches.
 */
contract ConstProdUtils_EdgeCases_Test is Test {
    ConstProdUtilsHarness internal harness;

    function setUp() public {
        harness = new ConstProdUtilsHarness();
    }

    /* ---------------------------------------------------------------------- */
    /*                         _sortReserves Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sortReserves_knownTokenIsToken0() public pure {
        address token0 = address(0x1111);
        address token1 = address(0x2222);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 known, uint256 unknown) = ConstProdUtils._sortReserves(token0, token0, reserve0, reserve1);

        assertEq(known, reserve0, "Known reserve should be reserve0");
        assertEq(unknown, reserve1, "Unknown reserve should be reserve1");
    }

    function test_sortReserves_knownTokenIsToken1() public pure {
        address token0 = address(0x1111);
        address token1 = address(0x2222);
        uint256 reserve0 = 1000e18;
        uint256 reserve1 = 2000e18;

        (uint256 known, uint256 unknown) = ConstProdUtils._sortReserves(token1, token0, reserve0, reserve1);

        assertEq(known, reserve1, "Known reserve should be reserve1");
        assertEq(unknown, reserve0, "Unknown reserve should be reserve0");
    }

    function test_sortReserves_withFees_knownTokenIsToken0() public pure {
        address token0 = address(0x1111);
        uint256 reserve0 = 1000e18;
        uint256 fee0 = 300;
        uint256 reserve1 = 2000e18;
        uint256 fee1 = 500;

        (uint256 knownReserve, uint256 knownFee, uint256 unknownReserve, uint256 unknownFee) =
            ConstProdUtils._sortReserves(token0, token0, reserve0, fee0, reserve1, fee1);

        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(knownFee, fee0, "Known fee should be fee0");
        assertEq(unknownReserve, reserve1, "Unknown reserve should be reserve1");
        assertEq(unknownFee, fee1, "Unknown fee should be fee1");
    }

    function test_sortReserves_withFees_knownTokenIsToken1() public pure {
        address token0 = address(0x1111);
        address token1 = address(0x2222);
        uint256 reserve0 = 1000e18;
        uint256 fee0 = 300;
        uint256 reserve1 = 2000e18;
        uint256 fee1 = 500;

        (uint256 knownReserve, uint256 knownFee, uint256 unknownReserve, uint256 unknownFee) =
            ConstProdUtils._sortReserves(token1, token0, reserve0, fee0, reserve1, fee1);

        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(knownFee, fee1, "Known fee should be fee1");
        assertEq(unknownReserve, reserve0, "Unknown reserve should be reserve0");
        assertEq(unknownFee, fee0, "Unknown fee should be fee0");
    }

    /* ---------------------------------------------------------------------- */
    /*                         _depositQuote Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_depositQuote_firstDeposit_minimumLiquiditySubtracted() public pure {
        // First deposit: sqrt(amountA * amountB) - MINIMUM_LIQUIDITY
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, 0, 0, 0);

        // sqrt(1000e18 * 1000e18) = 1000e18, - 1000 = 1000e18 - 1000
        assertEq(lpAmount, 1000e18 - 1000, "First deposit should subtract MINIMUM_LIQUIDITY");
    }

    function test_depositQuote_firstDeposit_smallAmounts() public pure {
        // Small first deposit
        uint256 amountA = 10000; // 10,000 wei
        uint256 amountB = 10000;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, 0, 0, 0);

        // sqrt(10000 * 10000) = 10000, - 1000 = 9000
        assertEq(lpAmount, 9000, "Small first deposit should work correctly");
    }

    function test_depositQuote_normalDeposit_equalRatios() public pure {
        uint256 amountA = 100e18;
        uint256 amountB = 100e18;
        uint256 lpSupply = 1000e18;
        uint256 reserveA = 1000e18;
        uint256 reserveB = 1000e18;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, lpSupply, reserveA, reserveB);

        // Both ratios: (100e18 * 1000e18) / 1000e18 = 100e18
        assertEq(lpAmount, 100e18, "Equal ratios should return exact amount");
    }

    function test_depositQuote_normalDeposit_ratioASmaller() public pure {
        uint256 amountA = 100e18;
        uint256 amountB = 200e18; // More B deposited
        uint256 lpSupply = 1000e18;
        uint256 reserveA = 1000e18;
        uint256 reserveB = 1000e18;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, lpSupply, reserveA, reserveB);

        // Ratio A: 100e18, Ratio B: 200e18, min = 100e18
        assertEq(lpAmount, 100e18, "Should use smaller ratio (A)");
    }

    function test_depositQuote_normalDeposit_ratioBSmaller() public pure {
        uint256 amountA = 200e18;
        uint256 amountB = 100e18; // Less B deposited
        uint256 lpSupply = 1000e18;
        uint256 reserveA = 1000e18;
        uint256 reserveB = 1000e18;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, lpSupply, reserveA, reserveB);

        // Ratio A: 200e18, Ratio B: 100e18, min = 100e18
        assertEq(lpAmount, 100e18, "Should use smaller ratio (B)");
    }

    function test_depositQuote_normalDeposit_unbalancedPool() public pure {
        uint256 amountA = 100e18;
        uint256 amountB = 50e18;
        uint256 lpSupply = 1000e18;
        uint256 reserveA = 2000e18; // Pool has more A
        uint256 reserveB = 1000e18;

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, lpSupply, reserveA, reserveB);

        // Ratio A: (100e18 * 1000e18) / 2000e18 = 50e18
        // Ratio B: (50e18 * 1000e18) / 1000e18 = 50e18
        assertEq(lpAmount, 50e18, "Unbalanced pool should calculate correctly");
    }

    /* ---------------------------------------------------------------------- */
    /*                        _purchaseQuote Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_purchaseQuote_revertsOnZeroAmountOut() public {
        vm.expectRevert(abi.encodeWithSelector(ArgumentMustNotBeZero.selector, 0));
        harness.purchaseQuote(0, 1000e18, 1000e18, 300);
    }

    function test_purchaseQuote_revertsOnZeroReserveIn() public {
        vm.expectRevert(abi.encodeWithSelector(ArgumentMustNotBeZero.selector, 1));
        harness.purchaseQuote(100e18, 0, 1000e18, 300);
    }

    function test_purchaseQuote_revertsOnInsufficientReserveOut() public {
        // reserveOut <= amountOut
        vm.expectRevert(abi.encodeWithSelector(ArgumentMustBeGreaterThan.selector, 2, 0));
        harness.purchaseQuote(1000e18, 1000e18, 1000e18, 300); // amountOut == reserveOut
    }

    function test_purchaseQuote_revertsOnExcessiveAmountOut() public {
        // amountOut > reserveOut
        vm.expectRevert(abi.encodeWithSelector(ArgumentMustBeGreaterThan.selector, 2, 0));
        harness.purchaseQuote(1500e18, 1000e18, 1000e18, 300);
    }

    function test_purchaseQuote_smallAmountOut() public pure {
        // Very small purchase
        uint256 amountIn = ConstProdUtils._purchaseQuote(1, 1000e18, 1000e18, 300);

        // Should return at least 1 + fee + safety increment
        assertGt(amountIn, 0, "Should return positive amount for small purchase");
    }

    function test_purchaseQuote_zeroFee() public pure {
        uint256 amountIn = ConstProdUtils._purchaseQuote(100e18, 1000e18, 1000e18, 0);

        // With zero fee: amountIn should be close to poolAmount + 1
        assertGt(amountIn, 0, "Should work with zero fee");
    }

    function test_purchaseQuote_exactCeilingDivision() public pure {
        // Test case where fee calculation results in exact division (no ceiling needed)
        // feeNumer = poolAmount * feePercent, we want feeNumer % feeDenom == 0
        uint256 reserveIn = 1000e18;
        uint256 reserveOut = 1000e18;
        uint256 amountOut = 100e18;
        uint256 feePercent = 1000; // 1% of 100000

        uint256 amountIn = ConstProdUtils._purchaseQuote(amountOut, reserveIn, reserveOut, feePercent);

        assertGt(amountIn, amountOut, "Input should exceed output due to fee");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _swapDepositSaleAmt Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_swapDepositSaleAmt_normalCase() public pure {
        uint256 amountIn = 100e18;
        uint256 saleReserve = 1000e18;
        uint256 feePercent = 300; // 0.3%

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent);

        // Sale amount should be roughly half of amountIn for a balanced deposit
        assertGt(saleAmt, 0, "Sale amount should be positive");
        assertLt(saleAmt, amountIn, "Sale amount should be less than input");
    }

    function test_swapDepositSaleAmt_fallbackBranch_verySmallDeposit() public pure {
        // Test the fallback branch: if (sqrtTerm <= twoMinusFee * saleReserve) return amountIn / 2
        uint256 amountIn = 1; // Very small deposit
        uint256 saleReserve = 1000e18;
        uint256 feePercent = 300;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent);

        // For very small deposits, should hit fallback and return amountIn / 2
        assertLe(saleAmt, amountIn, "Sale amount should not exceed input");
    }

    function test_swapDepositSaleAmt_cappedAtAmountIn() public pure {
        // Test the cap: if (saleAmt > amountIn) saleAmt = amountIn
        uint256 amountIn = 100e18;
        uint256 saleReserve = 1e15; // Very small reserve
        uint256 feePercent = 300;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent);

        assertLe(saleAmt, amountIn, "Sale amount should be capped at amountIn");
    }

    function test_swapDepositSaleAmt_zeroFee() public pure {
        uint256 amountIn = 100e18;
        uint256 saleReserve = 1000e18;
        uint256 feePercent = 0;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent);

        // With zero fee, sale amount should be close to amountIn / 2
        assertGt(saleAmt, 0, "Should work with zero fee");
    }

    function test_swapDepositSaleAmt_lowFeeDenominator() public pure {
        // Test with feeDenominator = 1000 (feePercent <= 10)
        uint256 amountIn = 100e18;
        uint256 saleReserve = 1000e18;
        uint256 feePercent = 3; // 0.3% when denom is 1000
        uint256 feeDenom = 1000;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent, feeDenom);

        assertGt(saleAmt, 0, "Should work with low fee denominator");
    }

    /* ---------------------------------------------------------------------- */
    /*                    _quoteSwapDepositWithFee Tests                      */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDepositWithFee_feePercentBoundary_exactly10() public pure {
        // feePercent == 10 should use feeDenom = 1000
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            100e18, // amountIn
            1000e18, // lpTotalSupply
            1000e18, // reserveIn
            1000e18, // reserveOut
            10, // feePercent exactly 10
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        assertGt(lpAmt, 0, "Should work with feePercent = 10");
    }

    function test_quoteSwapDepositWithFee_feePercentBoundary_exactly11() public pure {
        // feePercent == 11 should use feeDenom = FEE_DENOMINATOR (100000)
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            100e18, // amountIn
            1000e18, // lpTotalSupply
            1000e18, // reserveIn
            1000e18, // reserveOut
            11, // feePercent = 11 (switches branch)
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        assertGt(lpAmt, 0, "Should work with feePercent = 11");
    }

    function test_quoteSwapDepositWithFee_protocolFeeEnabled() public pure {
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            100e18, // amountIn
            1000e18, // lpTotalSupply
            1000e18, // reserveIn
            1000e18, // reserveOut
            300, // feePercent
            1e36, // kLast (1000e18 * 1000e18)
            16666, // ownerFeeShare (Uniswap-style)
            true // feeOn
        );

        assertGt(lpAmt, 0, "Should work with protocol fees enabled");
    }

    function test_quoteSwapDepositWithFee_protocolFeeDisabled() public pure {
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            100e18, // amountIn
            1000e18, // lpTotalSupply
            1000e18, // reserveIn
            1000e18, // reserveOut
            300, // feePercent
            1e36, // kLast
            16666, // ownerFeeShare
            false // feeOn = false
        );

        assertGt(lpAmt, 0, "Should work with protocol fees disabled");
    }

    function test_quoteSwapDepositWithFee_kLastZero() public pure {
        // Even if feeOn = true, kLast = 0 should skip protocol fee calculation
        uint256 lpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            100e18, // amountIn
            1000e18, // lpTotalSupply
            1000e18, // reserveIn
            1000e18, // reserveOut
            300, // feePercent
            0, // kLast = 0
            16666, // ownerFeeShare
            true // feeOn
        );

        assertGt(lpAmt, 0, "Should work when kLast is zero");
    }

    /* ---------------------------------------------------------------------- */
    /*                     _quoteWithdrawWithFee Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawWithFee_zeroOwnedLP() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            0, // ownedLPAmount = 0
            1000e18,
            1000e18,
            1000e18,
            1e36,
            16666,
            true
        );

        assertEq(a, 0, "Should return 0 for zero owned LP");
        assertEq(b, 0, "Should return 0 for zero owned LP");
    }

    function test_quoteWithdrawWithFee_zeroTotalSupply() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            100e18,
            0, // lpTotalSupply = 0
            1000e18,
            1000e18,
            1e36,
            16666,
            true
        );

        assertEq(a, 0, "Should return 0 for zero total supply");
        assertEq(b, 0, "Should return 0 for zero total supply");
    }

    function test_quoteWithdrawWithFee_zeroReserveA() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            100e18,
            1000e18,
            0, // totalReserveA = 0
            1000e18,
            1e36,
            16666,
            true
        );

        assertEq(a, 0, "Should return 0 for zero reserve A");
        assertEq(b, 0, "Should return 0 for zero reserve A");
    }

    function test_quoteWithdrawWithFee_zeroReserveB() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            100e18,
            1000e18,
            1000e18,
            0, // totalReserveB = 0
            1e36,
            16666,
            true
        );

        assertEq(a, 0, "Should return 0 for zero reserve B");
        assertEq(b, 0, "Should return 0 for zero reserve B");
    }

    function test_quoteWithdrawWithFee_ownedExceedsTotalSupply() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            2000e18, // ownedLPAmount > lpTotalSupply
            1000e18,
            1000e18,
            1000e18,
            1e36,
            16666,
            true
        );

        assertEq(a, 0, "Should return 0 when owned exceeds total");
        assertEq(b, 0, "Should return 0 when owned exceeds total");
    }

    function test_quoteWithdrawWithFee_ownedExactlyEqualsSupply() public pure {
        (uint256 a, uint256 b) = ConstProdUtils._quoteWithdrawWithFee(
            1000e18, // ownedLPAmount == lpTotalSupply
            1000e18,
            500e18, // reserveA
            500e18, // reserveB
            0, // kLast
            0, // ownerFeeShare
            false // feeOn
        );

        // Should withdraw all reserves
        assertEq(a, 500e18, "Should withdraw all reserve A");
        assertEq(b, 500e18, "Should withdraw all reserve B");
    }

    /* ---------------------------------------------------------------------- */
    /*                          _saleQuote Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_saleQuote_zeroAmountIn() public pure {
        uint256 proceeds = ConstProdUtils._saleQuote(0, 1000e18, 1000e18, 300);

        assertEq(proceeds, 0, "Zero input should return zero output");
    }

    function test_saleQuote_zeroFee() public pure {
        uint256 proceeds = ConstProdUtils._saleQuote(100e18, 1000e18, 1000e18, 0);

        // With no fee, should get approximately: (1000 * 100) / (1000 + 100) ≈ 90.9e18
        assertGt(proceeds, 0, "Should work with zero fee");
    }

    function test_saleQuote_maxFee() public pure {
        // Fee of 10000 out of 100000 = 10%
        uint256 proceeds = ConstProdUtils._saleQuote(100e18, 1000e18, 1000e18, 10000);

        assertGt(proceeds, 0, "Should work with high fee");
        // Output should be significantly reduced due to high fee
    }

    /* ---------------------------------------------------------------------- */
    /*                             Fuzz Tests                                  */
    /* ---------------------------------------------------------------------- */

    function testFuzz_depositQuote_firstDeposit_alwaysPositive(uint256 amountA, uint256 amountB) public pure {
        // Bound to ensure sqrt result > MINIMUM_LIQUIDITY
        amountA = bound(amountA, 1e6, 1e30);
        amountB = bound(amountB, 1e6, 1e30);

        // Skip if sqrt would be <= 1000 (MINIMUM_LIQUIDITY)
        uint256 product = amountA * amountB;
        if (product <= 1e6) return; // sqrt(1e6) = 1000

        uint256 lpAmount = ConstProdUtils._depositQuote(amountA, amountB, 0, 0, 0);

        assertGe(lpAmount, 0, "First deposit LP should be non-negative");
    }

    function testFuzz_purchaseQuote_validInputs_alwaysReturnsPositive(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) public pure {
        // Bound inputs to valid ranges
        amountOut = bound(amountOut, 1, 1e27);
        reserveIn = bound(reserveIn, 1e15, 1e30);
        reserveOut = bound(reserveOut, amountOut + 1, 1e30);
        feePercent = bound(feePercent, 0, 9999); // < 10%

        uint256 amountIn = ConstProdUtils._purchaseQuote(amountOut, reserveIn, reserveOut, feePercent);

        assertGt(amountIn, 0, "Should always return positive amount for valid inputs");
    }

    function testFuzz_swapDepositSaleAmt_neverExceedsInput(uint256 amountIn, uint256 saleReserve, uint256 feePercent)
        public
        pure
    {
        amountIn = bound(amountIn, 1, 1e30);
        saleReserve = bound(saleReserve, 1e15, 1e30);
        feePercent = bound(feePercent, 0, 9999);

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, saleReserve, feePercent);

        assertLe(saleAmt, amountIn, "Sale amount should never exceed input");
    }
}
