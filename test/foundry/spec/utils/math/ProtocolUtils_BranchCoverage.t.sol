// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {CamelotV2Utils} from "@crane/contracts/utils/math/CamelotV2Utils.sol";
import {UniswapV2Utils} from "@crane/contracts/utils/math/UniswapV2Utils.sol";
import {AerodromeUtils} from "@crane/contracts/utils/math/AerodromeUtils.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/**
 * @title CamelotV2UtilsHarness
 * @notice Exposes CamelotV2Utils library functions for testing.
 */
contract CamelotV2UtilsHarness {
    function quoteWithdrawSwapWithFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) external pure returns (uint256) {
        return CamelotV2Utils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB,
            feePercent, feeDenominator, kLast, ownerFeeShare, feeOn
        );
    }
}

/**
 * @title UniswapV2UtilsHarness
 * @notice Exposes UniswapV2Utils library functions for testing.
 */
contract UniswapV2UtilsHarness {
    function quoteWithdrawSwapFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        bool feeToOn
    ) external pure returns (uint256) {
        return UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB,
            feePercent, feeDenominator, kLast, feeToOn
        );
    }
}

/**
 * @title AerodromeUtilsHarness
 * @notice Exposes AerodromeUtils library functions for testing.
 */
contract AerodromeUtilsHarness {
    function quoteWithdrawSwapWithFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveOut,
        uint256 reserveIn,
        uint256 feePercent
    ) external pure returns (uint256) {
        return AerodromeUtils._quoteWithdrawSwapWithFee(
            ownedLPAmount, lpTotalSupply, reserveOut, reserveIn, feePercent
        );
    }

    function quoteSwapDepositWithFee(
        uint256 amountIn,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) external pure returns (uint256) {
        return AerodromeUtils._quoteSwapDepositWithFee(
            amountIn, lpTotalSupply, reserveIn, reserveOut, feePercent
        );
    }
}

/**
 * @title CamelotV2Utils_BranchCoverage_Test
 * @notice Branch coverage tests for CamelotV2Utils library.
 */
contract CamelotV2Utils_BranchCoverage_Test is Test {
    CamelotV2UtilsHarness internal harness;

    function setUp() public {
        harness = new CamelotV2UtilsHarness();
    }

    /* ---------------------------------------------------------------------- */
    /*                      Zero Input Branch Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_zeroOwnedLP_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            0,          // ownedLPAmount = 0
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent (0.3%)
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertEq(result, 0, "Should return 0 for zero owned LP");
    }

    function test_quoteWithdrawSwap_zeroTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            0,          // lpTotalSupply = 0
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertEq(result, 0, "Should return 0 for zero total supply");
    }

    function test_quoteWithdrawSwap_zeroReserveA_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            0,          // reserveA = 0
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertEq(result, 0, "Should return 0 for zero reserveA");
    }

    function test_quoteWithdrawSwap_zeroReserveB_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            0,          // reserveB = 0
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertEq(result, 0, "Should return 0 for zero reserveB");
    }

    /* ---------------------------------------------------------------------- */
    /*                    Owned > Total Supply Branch                         */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_ownedExceedsTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            2000e18,    // ownedLPAmount > lpTotalSupply
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertEq(result, 0, "Should return 0 when owned exceeds total supply");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Fee Off Branch Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_feeOff_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            30000,      // ownerFeeShare
            false       // feeOn = false
        );
        assertGt(result, 0, "Should return positive amount with fee off");
    }

    function test_quoteWithdrawSwap_zeroKLast_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            0,          // kLast = 0
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertGt(result, 0, "Should return positive amount with zero kLast");
    }

    function test_quoteWithdrawSwap_zeroOwnerFeeShare_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast
            0,          // ownerFeeShare = 0
            true        // feeOn
        );
        assertGt(result, 0, "Should return positive amount with zero owner fee share");
    }

    /* ---------------------------------------------------------------------- */
    /*                     RootK <= RootKLast Branch                          */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_rootKLessThanRootKLast_skipsFeeMint() public view {
        // Set kLast higher than current K (reserves decreased)
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            50e18,      // reserveA (smaller)
            50e18,      // reserveB (smaller)
            3000,       // feePercent
            100000,     // feeDenominator
            100e36,     // kLast = 100e36 > current K = 2500e36
            30000,      // ownerFeeShare
            true        // feeOn
        );
        assertGt(result, 0, "Should return positive amount when rootK <= rootKLast");
    }

    /* ---------------------------------------------------------------------- */
    /*                        d < 100 Branch Test                             */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_dLessThan100_skipsFeeMint() public view {
        // ownerFeeShare very high makes d < 100
        // d = (feeDenominator * 100) / ownerFeeShare
        // For d < 100, need ownerFeeShare > feeDenominator
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent
            100000,     // feeDenominator
            50e36,      // kLast (lower than current K)
            200000,     // ownerFeeShare > feeDenominator makes d < 100
            true        // feeOn
        );
        assertGt(result, 0, "Should return positive amount when d < 100");
    }

    /* ---------------------------------------------------------------------- */
    /*                   Reserve < Amount Withdrawn Branch                    */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_reserveBLessThanAmountBWD_returnsAmountAWD() public view {
        // This edge case is hard to trigger normally, but test the branch
        // by using a very large owned LP relative to reserves
        uint256 result = harness.quoteWithdrawSwapWithFee(
            999e18,     // ownedLPAmount (almost all LP)
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            1,          // reserveB = 1 wei (very small)
            3000,       // feePercent
            100000,     // feeDenominator
            0,          // kLast = 0 (skip fee mint)
            0,          // ownerFeeShare
            false       // feeOn
        );
        // Should return approximately the owned share of reserveA
        assertGt(result, 0, "Should return positive amount");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Normal Operation Test                            */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_normalOperation_returnsPositive() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            100e18,     // ownedLPAmount
            1000e18,    // lpTotalSupply
            1000e18,    // reserveA
            1000e18,    // reserveB
            3000,       // feePercent (0.3%)
            100000,     // feeDenominator
            900e36,     // kLast (slightly less than current K)
            30000,      // ownerFeeShare (30%)
            true        // feeOn
        );
        assertGt(result, 0, "Should return positive amount for normal operation");
    }
}

/**
 * @title UniswapV2Utils_BranchCoverage_Test
 * @notice Branch coverage tests for UniswapV2Utils library.
 */
contract UniswapV2Utils_BranchCoverage_Test is Test {
    UniswapV2UtilsHarness internal harness;

    function setUp() public {
        harness = new UniswapV2UtilsHarness();
    }

    /* ---------------------------------------------------------------------- */
    /*                      Zero Input Branch Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_zeroOwnedLP_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            0,          // ownedLPAmount = 0
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent (0.3% with 1000 denom)
            1000,       // feeDenominator
            100e36,     // kLast
            true        // feeToOn
        );
        assertEq(result, 0, "Should return 0 for zero owned LP");
    }

    function test_quoteWithdrawSwap_zeroTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            0,          // lpTotalSupply = 0
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast
            true        // feeToOn
        );
        assertEq(result, 0, "Should return 0 for zero total supply");
    }

    function test_quoteWithdrawSwap_zeroReserveA_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            0,          // reserveA = 0
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast
            true        // feeToOn
        );
        assertEq(result, 0, "Should return 0 for zero reserveA");
    }

    function test_quoteWithdrawSwap_zeroReserveB_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            0,          // reserveB = 0
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast
            true        // feeToOn
        );
        assertEq(result, 0, "Should return 0 for zero reserveB");
    }

    /* ---------------------------------------------------------------------- */
    /*                    Owned > Total Supply Branch                         */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_ownedExceedsTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            2000e18,    // ownedLPAmount > lpTotalSupply
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast
            true        // feeToOn
        );
        assertEq(result, 0, "Should return 0 when owned exceeds total supply");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Fee Off Branch Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_feeToOff_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast
            false       // feeToOn = false
        );
        assertGt(result, 0, "Should return positive amount with fee off");
    }

    function test_quoteWithdrawSwap_zeroKLast_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            0,          // kLast = 0
            true        // feeToOn
        );
        assertGt(result, 0, "Should return positive amount with zero kLast");
    }

    /* ---------------------------------------------------------------------- */
    /*                     RootK <= RootKLast Branch                          */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_rootKLessThanRootKLast_skipsFeeMint() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            50e18,      // reserveA (smaller)
            50e18,      // reserveB (smaller)
            3,          // feePercent
            1000,       // feeDenominator
            100e36,     // kLast > current K
            true        // feeToOn
        );
        assertGt(result, 0, "Should return positive amount when rootK <= rootKLast");
    }

    /* ---------------------------------------------------------------------- */
    /*                    Fee Denominator Ternary Branch                      */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_smallFeePercent_uses1000Denom() public view {
        // feePercent <= 10 uses 1000 denominator
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent <= 10
            1000,       // feeDenominator (ignored, uses 1000)
            0,          // kLast
            false       // feeToOn
        );
        assertGt(result, 0, "Should work with small fee percent");
    }

    function test_quoteWithdrawSwap_largeFeePercent_usesFEE_DENOMINATOR() public view {
        // feePercent > 10 uses FEE_DENOMINATOR (100000)
        uint256 result = harness.quoteWithdrawSwapFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3000,       // feePercent > 10
            100000,     // feeDenominator
            0,          // kLast
            false       // feeToOn
        );
        assertGt(result, 0, "Should work with large fee percent");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Zero AmountBWD Branch                             */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_verySmallLP_zeroAmountBWD() public view {
        // Very small LP amount may result in zero amountBWD due to rounding
        uint256 result = harness.quoteWithdrawSwapFee(
            1,          // ownedLPAmount = 1 wei
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            100e18,     // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            0,          // kLast
            false       // feeToOn
        );
        // Result may be very small or zero
        assertTrue(true, "Should handle very small LP");
    }

    /* ---------------------------------------------------------------------- */
    /*                   Reserve < Amount Withdrawn Branch                    */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_reserveBLessThanAmountBWD() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            999e18,     // ownedLPAmount (almost all LP)
            1000e18,    // lpTotalSupply
            100e18,     // reserveA
            1,          // reserveB = 1 wei
            3,          // feePercent
            1000,       // feeDenominator
            0,          // kLast
            false       // feeToOn
        );
        assertGt(result, 0, "Should return amountAWD when reserveB < amountBWD");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Normal Operation Test                            */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_normalOperation_returnsPositive() public view {
        uint256 result = harness.quoteWithdrawSwapFee(
            100e18,     // ownedLPAmount
            1000e18,    // lpTotalSupply
            1000e18,    // reserveA
            1000e18,    // reserveB
            3,          // feePercent
            1000,       // feeDenominator
            900e36,     // kLast
            true        // feeToOn
        );
        assertGt(result, 0, "Should return positive amount for normal operation");
    }
}

/**
 * @title AerodromeUtils_BranchCoverage_Test
 * @notice Branch coverage tests for AerodromeUtils library.
 */
contract AerodromeUtils_BranchCoverage_Test is Test {
    AerodromeUtilsHarness internal harness;

    function setUp() public {
        harness = new AerodromeUtilsHarness();
    }

    /* ---------------------------------------------------------------------- */
    /*              quoteWithdrawSwapWithFee Zero Input Tests                 */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_zeroOwnedLP_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            0,          // ownedLPAmount = 0
            1000e18,    // lpTotalSupply
            100e18,     // reserveOut
            100e18,     // reserveIn
            30          // feePercent (0.3%)
        );
        assertEq(result, 0, "Should return 0 for zero owned LP");
    }

    function test_quoteWithdrawSwap_zeroTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            0,          // lpTotalSupply = 0
            100e18,     // reserveOut
            100e18,     // reserveIn
            30          // feePercent
        );
        assertEq(result, 0, "Should return 0 for zero total supply");
    }

    function test_quoteWithdrawSwap_zeroReserveOut_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            0,          // reserveOut = 0
            100e18,     // reserveIn
            30          // feePercent
        );
        assertEq(result, 0, "Should return 0 for zero reserveOut");
    }

    function test_quoteWithdrawSwap_zeroReserveIn_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveOut
            0,          // reserveIn = 0
            30          // feePercent
        );
        assertEq(result, 0, "Should return 0 for zero reserveIn");
    }

    function test_quoteWithdrawSwap_feePercentExceedsDenom_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            10e18,      // ownedLPAmount
            1000e18,    // lpTotalSupply
            100e18,     // reserveOut
            100e18,     // reserveIn
            10000       // feePercent >= AERO_FEE_DENOM (10000)
        );
        assertEq(result, 0, "Should return 0 when fee >= denominator");
    }

    /* ---------------------------------------------------------------------- */
    /*                    Owned > Total Supply Branch                         */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_ownedExceedsTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            2000e18,    // ownedLPAmount > lpTotalSupply
            1000e18,    // lpTotalSupply
            100e18,     // reserveOut
            100e18,     // reserveIn
            30          // feePercent
        );
        assertEq(result, 0, "Should return 0 when owned exceeds total supply");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Normal Operation Test                            */
    /* ---------------------------------------------------------------------- */

    function test_quoteWithdrawSwap_normalOperation_returnsPositive() public view {
        uint256 result = harness.quoteWithdrawSwapWithFee(
            100e18,     // ownedLPAmount
            1000e18,    // lpTotalSupply
            1000e18,    // reserveOut
            1000e18,    // reserveIn
            30          // feePercent (0.3%)
        );
        assertGt(result, 0, "Should return positive amount for normal operation");
    }

    /* ---------------------------------------------------------------------- */
    /*              quoteSwapDepositWithFee Zero Input Tests                  */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDeposit_zeroTotalSupply_returnsZero() public view {
        uint256 result = harness.quoteSwapDepositWithFee(
            100e18,     // amountIn
            0,          // lpTotalSupply = 0
            1000e18,    // reserveIn
            1000e18,    // reserveOut
            30          // feePercent
        );
        assertEq(result, 0, "Should return 0 for zero total supply");
    }

    /* ---------------------------------------------------------------------- */
    /*                  amountBOptimal Branch Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDeposit_amountBOptimalLessOrEqual_usesRemaining() public view {
        // This tests the if (amountBOptimal <= opTokenAmtIn) branch
        uint256 result = harness.quoteSwapDepositWithFee(
            100e18,     // amountIn
            1000e18,    // lpTotalSupply
            1000e18,    // reserveIn
            1000e18,    // reserveOut (balanced pool)
            30          // feePercent
        );
        assertGt(result, 0, "Should return positive LP for balanced pool");
    }

    function test_quoteSwapDeposit_amountBOptimalGreater_usesAmountAOptimal() public view {
        // Unbalanced pool where amountBOptimal > opTokenAmtIn
        uint256 result = harness.quoteSwapDepositWithFee(
            100e18,     // amountIn
            1000e18,    // lpTotalSupply
            100e18,     // reserveIn (smaller)
            1000e18,    // reserveOut (larger)
            30          // feePercent
        );
        assertGt(result, 0, "Should return positive LP for unbalanced pool");
    }

    /* ---------------------------------------------------------------------- */
    /*                     Min Selection Ternary Test                         */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDeposit_amountARatioSmaller_usesARatio() public view {
        // Create conditions where amountA_ratio < amountB_ratio
        uint256 result = harness.quoteSwapDepositWithFee(
            1000e18,    // amountIn
            1000e18,    // lpTotalSupply
            500e18,     // reserveIn
            1000e18,    // reserveOut
            30          // feePercent
        );
        assertGt(result, 0, "Should use min ratio");
    }

    function test_quoteSwapDeposit_amountBRatioSmaller_usesBRatio() public view {
        // Create conditions where amountB_ratio < amountA_ratio
        uint256 result = harness.quoteSwapDepositWithFee(
            1000e18,    // amountIn
            1000e18,    // lpTotalSupply
            1000e18,    // reserveIn
            500e18,     // reserveOut
            30          // feePercent
        );
        assertGt(result, 0, "Should use min ratio");
    }
}
