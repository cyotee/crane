// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import "../../../../../constants/Constants.sol";

import {
    Uint512,
    BetterMath
} from "../../../../../utils/math/BetterMath.sol";

import {
    BetterIERC20 as IERC20
} from "../../../../../token/ERC20/BetterIERC20.sol";

import {
    ICamelotPair
} from "../ICamelotPair.sol";

import {
    ICamelotFactory
} from "../ICamelotFactory.sol";

import {
    ICamelotV2Router
} from "../ICamelotV2Router.sol";

library CamelotV2Utils {

    using BetterMath for uint256;
    using BetterMath for Uint512;
    using CamelotV2Utils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10**3;

    // uint256 constant PRECISION = 1e18;
    // uint256 constant FEE_DENOMINATOR = 100_000;
    
    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    // tag::_quote[]
    /**
     * @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function _calcEquiv(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "CamelotV2Utils: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "CamelotV2Utils: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
    // end::_quote[]

    /**
     * @dev Provides the LP token mint amount for a given deposit, reserve, and total supply.
     */
    function _calcDeposit(
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 lpTotalSupply,
        uint256 lpReserveA,
        uint256 lpReserveB
    ) internal pure returns(uint256 lpAmount) {
         lpAmount = lpTotalSupply == 0
            ? BetterMath.sqrt((amountADeposit * amountBDeposit)) - _MINIMUM_LIQUIDITY
            : BetterMath.min(
                (amountADeposit * lpTotalSupply) / lpReserveA,
                (amountBDeposit * lpTotalSupply) / lpReserveB
            );
    }

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Provides the owned balances of a given liquidity pool reserve.
     * @dev Uses A/B nomenclature to indicate order DOES NOT matter, simply correlate variables to the same tokens.
     * @param ownedLPAmount Owned amount of LP token.
     * @param lpTotalSupply LP token total supply.
     * @param totalReserveA LP reserve of Token A
     * @param totalReserveB LP reserve of Token B.
     * @return ownedReserveA Owned share of Token A from LP reserve.
     * @return ownedReserveB Owned share of Token B from LP reserve.
     */
    function _calcWithdraw(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA,
        uint256 totalReserveB
    ) internal pure returns(
        uint256 ownedReserveA,
        uint256 ownedReserveB
    ) {
        // using balances ensures pro-rata distribution
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
        ownedReserveB = ((ownedLPAmount * totalReserveB) / lpTotalSupply);
    }

    function _calcWithdrawOneSide(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA
    ) internal pure returns(uint256 ownedReserveA) {
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
    }

    /**
     * @dev Calculates the amount of LP to withdraw to extract a desired amount of one token.
     * @dev Could be done more efficiently with optimized math.
     */
    // TODO Optimize math.
    function _calcWithdrawAmt(
        uint256 targetOutAmt,
        uint256 lpTotalSupply,
        uint256 outRes,
        uint256 // opRes
    ) internal pure returns(uint256 lpWithdrawAmt) {
        // uint256 opTAmt = _calcEquiv(
        //     targetOutAmt,
        //     outRes,
        //     opRes
        // );
        // lpWithdrawAmt = _calcDeposit(
        //     targetOutAmt,
        //     opTAmt,
        //     lpTotalSupply,
        //     outRes,
        //     opRes
        // );
        // Ceiling division to avoid truncation
        return (targetOutAmt * lpTotalSupply + outRes - 1) / outRes;
    }

    /* ---------------------------------------------------------------------- */
    /*                           RESERVE/FEE DELTAS                           */
    /* ---------------------------------------------------------------------- */

    // /**
    //  * @dev Calculates the fee earned per LP token in IT and OT terms.
    //  * @param reserveIT_last Last stored reserve of Index Target (IT) token.
    //  * @param reserveOT_last Last stored reserve of Other Token (OT).
    //  * @param lpTotalSupply_last Last stored total LP token supply.
    //  * @param reserveIT_current Current reserve of Index Target (IT) token.
    //  * @param reserveOT_current Current reserve of Other Token (OT).
    //  * @param lpTotalSupply_current Current total LP token supply.
    //  * @return feeITPerLp Fee per LP token in IT terms.
    //  * @return feeOTPerLp Fee per LP token in OT terms.
    //  */
    // function _calcReserveDeltas(
    //     uint256 reserveIT_last,
    //     uint256 reserveOT_last,
    //     uint256 lpTotalSupply_last,
    //     uint256 reserveIT_current,
    //     uint256 reserveOT_current,
    //     uint256 lpTotalSupply_current
    // ) internal pure returns (uint256 feeITPerLp, uint256 feeOTPerLp) {
    //     require(lpTotalSupply_last > 0 && lpTotalSupply_current > 0, "Invalid LP supply");

    //     // Calculate reserves per LP token at the last stored state
    //     uint256 reserveITPerLp_last = (reserveIT_last * ONE_WAD) / lpTotalSupply_last;
    //     uint256 reserveOTPerLp_last = (reserveOT_last * ONE_WAD) / lpTotalSupply_last;

    //     // Calculate reserves per LP token at the current state
    //     uint256 reserveITPerLp_current = (reserveIT_current * ONE_WAD) / lpTotalSupply_current;
    //     uint256 reserveOTPerLp_current = (reserveOT_current * ONE_WAD) / lpTotalSupply_current;

    //     // Fees per LP token are the increase in reserves per LP token
    //     feeITPerLp = reserveITPerLp_current > reserveITPerLp_last 
    //         ? reserveITPerLp_current - reserveITPerLp_last 
    //         : 0;
    //     feeOTPerLp = reserveOTPerLp_current > reserveOTPerLp_last 
    //         ? reserveOTPerLp_current - reserveOTPerLp_last 
    //         : 0;
    // }

    // /**
    //  * @dev Calculates the accumulated maker fees per LP token in IT and OT terms.
    //  * @param k_last Last stored product of reserves (reserveIT_last * reserveOT_last).
    //  * @param lpTotalSupply_last Last stored total LP token supply.
    //  * @param reserveIT_current Current reserve of Index Target (IT) token.
    //  * @param reserveOT_current Current reserve of Other Token (OT).
    //  * @param lpTotalSupply_current Current total LP token supply.
    //  * @return feeITPerLp Fee per LP token in IT terms.
    //  * @return feeOTPerLp Fee per LP token in OT terms.
    //  */
    // function _calcFeePerLp(
    //     uint256 k_last,
    //     uint256 lpTotalSupply_last,
    //     uint256 reserveIT_current,
    //     uint256 reserveOT_current,
    //     uint256 lpTotalSupply_current
    // ) internal pure returns (uint256 feeITPerLp, uint256 feeOTPerLp) {
    //     require(lpTotalSupply_last > 0 && lpTotalSupply_current > 0, "Invalid LP supply");

    //     // Current k (product of current reserves)
    //     uint256 k_current = reserveIT_current * reserveOT_current;

    //     // Expected k if no fees were collected, scaled by LP supply change
    //     uint256 k_expected = (k_last * lpTotalSupply_current) / lpTotalSupply_last;

    //     if (k_current <= k_expected) {
    //         // No fees accrued
    //         return (0, 0);
    //     }

    //     // Fee factor: ratio of current k to expected k, representing fee growth
    //     uint256 feeFactor = (k_current * ONE_WAD) / k_expected;

    //     // Expected reserves if no fees were added (adjusted by fee factor)
    //     uint256 expectedIT = (reserveIT_current * ONE_WAD) / feeFactor;
    //     uint256 expectedOT = (reserveOT_current * ONE_WAD) / feeFactor;

    //     // Fees per LP token: difference between current and expected reserves
    //     feeITPerLp = ((reserveIT_current - expectedIT) * ONE_WAD) / lpTotalSupply_current;
    //     feeOTPerLp = ((reserveOT_current - expectedOT) * ONE_WAD) / lpTotalSupply_current;
    // }

    // /**
    //  * @dev Calculates the ZapOut value of the fees earned by the vault’s LP tokens in IT terms.
    //  * @param ownedLPAmount Vault’s current LP token balance.
    //  * @param feeITPerLp Fee per LP token in IT terms (from calcFeePerLp).
    //  * @param feeOTPerLp Fee per LP token in OT terms (from calcFeePerLp).
    //  * @param reserveIT_current Current reserve of Index Target (IT) token.
    //  * @param reserveOT_current Current reserve of Other Token (OT).
    //  * @param swapFeePercent Swap fee percent (e.g., 3000 for 0.3%).
    //  * @return zapOutFees Total ZapOut value of the fees in IT terms.
    //  */
    // function _calcFeeAsZapOut(
    //     uint256 ownedLPAmount,
    //     uint256 feeITPerLp,
    //     uint256 feeOTPerLp,
    //     uint256 reserveIT_current,
    //     uint256 reserveOT_current,
    //     uint256 swapFeePercent
    // ) internal pure returns (uint256 zapOutFees) {
    //     require(reserveOT_current > 0, "Invalid OT reserve");
    //     require(swapFeePercent < FEE_DENOMINATOR, "Invalid swap fee");

    //     // Total fees earned by the vault’s LP tokens
    //     uint256 feeIT = (feeITPerLp * ownedLPAmount) / PRECISION;
    //     uint256 feeOT = (feeOTPerLp * ownedLPAmount) / PRECISION;

    //     // Calculate IT obtained by swapping OT fees
    //     uint256 gamma = FEE_DENOMINATOR - swapFeePercent; // Fee complement (e.g., 997000 for 0.3%)
    //     uint256 numerator = feeOT * gamma * reserveIT_current;
    //     uint256 denominator = (reserveOT_current * FEE_DENOMINATOR) + (feeOT * gamma);
    //     uint256 itFromOt = (numerator / denominator);

    //     // Total ZapOut value is the sum of direct IT fees and IT from swapped OT fees
    //     zapOutFees = feeIT + itFromOt;
    // }

    /* ---------------------------------------------------------------------- */
    /*                                  Swap                                  */
    /* ---------------------------------------------------------------------- */

    // TODO optimize with better conditionals.
    function _calcAmountOutStable(
        uint256 amountIn,
        // address tokenIn,
        // address token0,
        // uint256 _reserve0,
        uint256 reserveIn,
        // uint256 precisionMultiplier0,
        uint256 resInPrecisionMultiplier,
        // uint256 _reserve1,
        uint256 reserveOut,
        // uint256 precisionMultiplier1,
        uint256 resOutPrecisionMultiplier,
        uint256 feePercent
    ) internal pure returns (uint) {
        amountIn = (
            amountIn
            - (
                (amountIn * feePercent)
                / FEE_DENOMINATOR
            )
        ); // remove fee from amount received
        uint256 xy = _k(
            // _reserve0,
            reserveIn,
            // precisionMultiplier0,
            resInPrecisionMultiplier,
            // _reserve1,
            reserveOut,
            // precisionMultiplier1
            resOutPrecisionMultiplier
        );
        // _reserve0 = _reserve0 * 1e18 / precisionMultiplier0;
        reserveIn = reserveIn * 1e18 / resInPrecisionMultiplier;
        // _reserve1 = _reserve1 * 1e18 / precisionMultiplier1;
        reserveOut = reserveOut * 1e18 / resOutPrecisionMultiplier;

        // (uint256 reserveA, uint256 reserveB)
        //     = tokenIn == token0
        //     ? (_reserve0, _reserve1)
        //     : (_reserve1, _reserve0);
        // amountIn
        //     = tokenIn == token0
        //     ? amountIn * 1e18 / precisionMultiplier0
        //     : amountIn * 1e18 / precisionMultiplier1;
        amountIn = reserveIn * 1e18 / resInPrecisionMultiplier;
        // uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
        uint256 y = reserveOut - _get_y(amountIn + reserveIn, xy, reserveOut);
        // return y * (tokenIn == token0 ? precisionMultiplier1 : precisionMultiplier0) / 1e18;
        return y * resOutPrecisionMultiplier / 1e18;
    }

    // TODO optimize with better conditionals.
    function _calcAmountOutConstProd(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) internal pure returns (uint) {
        amountIn = amountIn * (FEE_DENOMINATOR - feePercent);
        // return (amountIn.mul(reserveB)) / (reserveA.mul(FEE_DENOMINATOR).add(amountIn));
        // return (amountIn * reserveB) / ((reserveA * FEE_DENOMINATOR) + amountIn);
        return (amountIn * reserveOut)
        / ((reserveIn * FEE_DENOMINATOR) + amountIn);
    }

    function _calcAmountIn(
        uint256 amountOut, 
        // uint256 _reserve0,
        uint256 reserveIn,
        // uint256 _reserve1,
        uint256 reserveOut,
        uint256 feePercent
    ) internal pure returns (uint amountIn) {
        // amountIn = amountIn * (FEE_DENOMINATOR - feePercent);
        // amountOut = (amountIn * reserveOut)
        // / ((reserveIn * FEE_DENOMINATOR) + amountIn);

        // amountIn = ((reserveIn * amountOut) * FEE_DENOMINATOR)
        // / (((reserveOut * feePercent) - (amountOut * feePercent))) * FEE_DENOMINATOR;
        amountIn = ((reserveIn * amountOut) * FEE_DENOMINATOR)
        / (((reserveOut - amountOut) * (FEE_DENOMINATOR - feePercent)));
        amountIn = amountIn + 1;
    }

    /* ---------------------------------------------------------------------- */
    /*                              Withdraw/Swap                             */
    /* ---------------------------------------------------------------------- */

    function _calcWithdrawSwap(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 exitTokenTotalReserve,
        uint256 opposingTokenTotalReserve,
        uint256 feePercent
    ) internal pure returns(uint256 exitAmount) {
        (
            uint256 exitTokenOwnedReserve,
            uint256 opposingTokenOwnedReserve
        ) = ownedLPAmount._calcWithdraw(
            // uint256 ownedLPAmount,
            // uint256 lpTotalSupply,
            lpTotalSupply,
            // uint256 totalReserveA,
            exitTokenTotalReserve,
            // uint256 totalReserveB
            opposingTokenTotalReserve
        );
        exitAmount = opposingTokenTotalReserve
        ._calcExit(
            // uint256 saleTokenTotalReserve,
            // uint256 saleTokenOwnedReserve,
            opposingTokenOwnedReserve,
            // uint256 exitTokenTotalReserve,
            exitTokenTotalReserve,
            // uint256 exitTokenOwnedReserve,
            exitTokenOwnedReserve,
            // uint256 feePercent
            feePercent
        );
        // (uint256 exitTokenOwnedReserve, uint256 opposingTokenOwnedReserve) = 
        //     _calcWithdraw(ownedLPAmount, lpTotalSupply, exitTokenTotalReserve, opposingTokenTotalReserve);
        
        // if (ownedLPAmount == 0 || opposingTokenOwnedReserve == 0) {
        //     return exitTokenOwnedReserve;
        // }

        // uint256 amountIn = opposingTokenOwnedReserve;
        // uint256 reserveIn = opposingTokenTotalReserve - opposingTokenOwnedReserve;
        // uint256 reserveOut = exitTokenTotalReserve - exitTokenOwnedReserve;
        // uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - feePercent);
        // uint256 saleProceeds = (amountInWithFee * reserveOut) / 
        //                     (reserveIn * FEE_DENOMINATOR + amountInWithFee);
        
        // exitAmount = exitTokenOwnedReserve + saleProceeds;
    }

    /**
     * @dev Calculates the proceeds of of a swap MINUS a portion of liquidity.
     * @param saleTokenTotalReserve LP reserve of token to be sold BEFORE withdraw.
     * @param saleTokenOwnedReserve Owned share of LP reserve of token to be sold.
     * @param exitTokenTotalReserve LP reserve of token to purchased BEFORE withdraw.
     * @param exitTokenOwnedReserve Owned share of LP reserve of token to be purchsed.
     * @return exitAmount
     */
    function _calcExit(
        uint256 saleTokenTotalReserve,
        uint256 saleTokenOwnedReserve,
        uint256 exitTokenTotalReserve,
        uint256 exitTokenOwnedReserve,
        uint256 feePercent
    ) internal pure returns(uint256 exitAmount) {
        uint256 saleProceeds = CamelotV2Utils
        ._calcAmountOutConstProd(
            // uint256 amountIn,
            saleTokenOwnedReserve,
            // uint256 reserveIn,
            saleTokenTotalReserve - saleTokenOwnedReserve,
            // uint256 reserveOut,
            exitTokenTotalReserve - exitTokenOwnedReserve,
            // uint256 feePercent
            feePercent
        );
        exitAmount = exitTokenOwnedReserve + saleProceeds;
    }

    /**
     * @dev Calculates the minimum amount of LP tokens to burn to achieve at least the desired amount of the output token.
     * @param desiredAmountOut The minimum amount of the output token desired after the ZapOut.
     * @param reserveOut The reserve of the output token in the pool (e.g., token A).
     * @param reserveIn The reserve of the input token in the pool (e.g., token B).
     * @param lpTotalSupply The total supply of LP tokens.
     * @param feePercent The swap fee in basis points (e.g., 30 for 0.3%).
     * @return lpAmountToBurn The amount of LP tokens to burn.
     */
    function _calcZapOutLpAmount(
        uint256 desiredAmountOut,
        uint256 reserveOut,
        uint256 reserveIn,
        uint256 lpTotalSupply,
        uint256 feePercent
    ) internal pure returns (uint256 lpAmountToBurn) {
        // Edge cases
        if (desiredAmountOut == 0) {
            return 0;
        }
        require(reserveOut > desiredAmountOut, "Insufficient reserve to meet desired amount");
        require(reserveIn > 0 && lpTotalSupply > 0, "Invalid pool reserves or LP supply");
        require(feePercent < FEE_DENOMINATOR, "Fee percent too high");

        // Define constants for readability
        uint256 gamma = FEE_DENOMINATOR - feePercent; // e.g., 9970 if fee is 30
        uint256 a = reserveOut * gamma;
        uint256 b = reserveIn * FEE_DENOMINATOR;
        // uint256 d = desiredAmountOut * b;

        // Calculate the discriminant for the quadratic equation
        uint256 sqrtTerm = BetterMath.sqrt(
            (a * a * desiredAmountOut * desiredAmountOut) +
            (2 * a * b * reserveOut * desiredAmountOut) +
            (b * b * reserveOut * reserveOut) -
            (2 * a * b * desiredAmountOut * desiredAmountOut) -
            (a * a * desiredAmountOut * reserveOut)
        );

        // Calculate the numerator and denominator for the proportion x = lpAmountToBurn / lpTotalSupply
        uint256 numerator = (a * desiredAmountOut) + (b * reserveOut) - sqrtTerm;
        uint256 denominator = a * (desiredAmountOut - reserveOut);

        // Calculate the proportion x (scaled by 1e18 for precision)
        uint256 x = (numerator * 1e18) / denominator;

        // Calculate lpAmountToBurn
        lpAmountToBurn = (x * lpTotalSupply) / 1e18;

        // Adjust for integer division rounding (ensure we meet or exceed desiredAmountOut)
        lpAmountToBurn += 1;
    }

    /* ---------------------------------------------------------------------- */
    /*                              Swap/Deposit                              */
    /* ---------------------------------------------------------------------- */

    function _calcSwapDeposit(
        uint256 lpTotalSupply,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) internal pure returns(uint256 lpAmt) {
        uint256 amtInSaleAmt = amountIn
        ._calcSwapDepositSaleAmt(
            reserveIn,
            feePercent
        );
        uint256 opTokenAmtIn = amtInSaleAmt
        ._calcAmountOutConstProd(
            // uint256 amountIn,
            reserveIn,
            reserveOut,
            feePercent
        );
        return (amountIn - amtInSaleAmt)
        ._calcDeposit(
            // uint256 amountADeposit,
            // uint256 amountBDeposit,
            opTokenAmtIn,
            lpTotalSupply,
            // uint256 lpReserveA,
            (reserveIn + amtInSaleAmt),
            // uint256 lpReserveB
            (reserveOut - opTokenAmtIn)
        );
    }

    function _calcSwapDepositSaleAmt(
        uint256 amountIn,
        uint256 saleReserve,
        uint256 feePercent
    ) internal pure returns(uint256 saleAmt) {
        // console.log("_calcSwapDepositSaleAmt:: Entering function");
        // console.log("amountIn = %s", amountIn);
        // console.log("saleReserve = %s", saleReserve);
        // console.log("feePercent = %s", feePercent);
        uint256 twoMinusFee = 2 * FEE_DENOMINATOR - feePercent;
        uint256 oneMinusFee = 1 * FEE_DENOMINATOR - feePercent;
        saleAmt = (
            BetterMath.sqrt(
                (twoMinusFee * twoMinusFee * saleReserve * saleReserve)
                + (4 * oneMinusFee * FEE_DENOMINATOR * amountIn * saleReserve)
            ) - (twoMinusFee * saleReserve)
        ) / (2 * oneMinusFee);
        // console.log("_calcSwapDepositSaleAmt:: Sale amount calculated");
        // console.log("_calcSwapDepositSaleAmt:: Returning sale amount");
        // console.log("saleAmt = %s", saleAmt);
        // console.log("_calcSwapDepositSaleAmt:: Exiting function");
        return saleAmt;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Utils                                 */
    /* ---------------------------------------------------------------------- */

    function _k(
        // uint256 balance0,
        uint256 resA,
        // uint256 precisionMultiplier0,
        uint256 precisionMultiplierA,
        // uint256 balance1,
        uint256 resB,
        // uint256 precisionMultiplier1,
        uint256 precisionMultiplierB
    ) internal pure returns (uint) {
        // uint256 _x = (balance0 * 1e18) / precisionMultiplier0;
        uint256 _x = (resA * 1e18) / precisionMultiplierA;
        // uint256 _y = (balance1 * 1e18) / precisionMultiplier1;
        uint256 _y = (resB * 1e18) / precisionMultiplierB;
        uint256 _a = (_x * _y) / 1e18;
        // uint256 _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
        uint256 _b = ((_x * _x) / 1e18) + ((_y * _y) / 1e18);
        return (_a * _b) / 1e18; // x3y+y3x >= k
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint) {
        for (uint256 i = 0; i < 255; i++) {
        uint256 y_prev = y;
        uint256 k = _f(x0, y);
        if (k < xy) {
            uint256 dy = (xy - k) * 1e18 / _d(x0, y);
            y = y + dy;
        } else {
            uint256 dy = (k - xy) * 1e18 / _d(x0, y);
            y = y - dy;
        }
        if (y > y_prev) {
            if (y - y_prev <= 1) {
            return y;
            }
        } else {
            if (y_prev - y <= 1) {
            return y;
            }
        }
        }
        return y;
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint) {
        return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint) {
        return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
    }


}