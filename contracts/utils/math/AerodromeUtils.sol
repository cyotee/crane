// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {Uint512, BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";

library AerodromeUtils {

    uint256 constant AERO_FEE_DENOM = 10000;

    /// @notice Wrapper to produce quoting parity with Aerodrome pools which use a 1/10000 fee denominator
    function _quoteWithdrawSwapWithFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveOut,
        uint256 reserveIn,
        uint256 feePercent
    ) internal pure returns (uint256 totalAmountA) {
        if (ownedLPAmount == 0 || lpTotalSupply == 0 || reserveOut == 0 || reserveIn == 0 || feePercent >= AERO_FEE_DENOM)
        {
            return (0);
        }
        if (ownedLPAmount > lpTotalSupply) {
            return (0);
        }
        (uint256 amountAWD, uint256 amountBWD) = ConstProdUtils._withdrawQuote(ownedLPAmount, lpTotalSupply, reserveOut, reserveIn);
        uint256 newReserveB = reserveIn - amountBWD;
        uint256 newReserveA = reserveOut - amountAWD;
        uint256 swapOut = ConstProdUtils._saleQuote(amountBWD, newReserveB, newReserveA, feePercent, AERO_FEE_DENOM);
        totalAmountA = amountAWD + swapOut;
        return (totalAmountA);
    }

    function _quoteSwapDepositWithFee(
        uint256 amountIn,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) internal pure returns (uint256 lpAmtLocal) {
        if (lpTotalSupply == 0) {
            return 0;
        }
        // uint256 feeDenom = (feePercent <= 10) ? 1000 : AERO_FEE_DENOM;
        uint256 opTokenAmtIn;
        // uint256 amountInWithFee;
        uint256 remaining;
        uint256 newReserveIn;
        uint256 newReserveOut;
        {
            uint256 amtInSaleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveIn, feePercent, AERO_FEE_DENOM);
            uint256 amountInWithFee = amtInSaleAmt - ((amtInSaleAmt * feePercent) / AERO_FEE_DENOM);
            opTokenAmtIn = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
            remaining = amountIn - amtInSaleAmt;
            newReserveIn = reserveIn + amountInWithFee;
            newReserveOut = reserveOut - opTokenAmtIn;
        }


        uint256 amountBOptimal = (remaining * newReserveOut) / newReserveIn;
        uint256 amountA;
        uint256 amountB;
        if (amountBOptimal <= opTokenAmtIn) {
            amountA = remaining;
            amountB = amountBOptimal;
        } else {
            uint256 amountAOptimal = (opTokenAmtIn * newReserveIn) / newReserveOut;
            amountA = amountAOptimal;
            amountB = opTokenAmtIn;
        }

        uint256 amountA_ratio = (amountA * lpTotalSupply) / newReserveIn;
        uint256 amountB_ratio = (amountB * lpTotalSupply) / newReserveOut;
        lpAmtLocal = amountA_ratio < amountB_ratio ? amountA_ratio : amountB_ratio;
    }

}
