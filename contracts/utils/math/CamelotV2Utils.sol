// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@crane/contracts/constants/Constants.sol";
import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/libraries/Math.sol";

/**
 * @title CamelotV2Utils
 * @dev Helper to reproduce CamelotPair withdraw+swap quoting including its
 *      protocol fee mint formula and Camelot swap integer math so callers
 *      obtain identical integer-rounded results.
 */
library CamelotV2Utils {
    function _quoteWithdrawSwapWithFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 totalAmountA) {
        if (ownedLPAmount == 0 || lpTotalSupply == 0 || reserveA == 0 || reserveB == 0) return 0;
        if (ownedLPAmount > lpTotalSupply) return 0;

        uint256 lpSupplyAdj = lpTotalSupply;

        // Mirror CamelotPair._mintFee when feeOn
        if (feeOn && kLast != 0 && ownerFeeShare != 0) {
            uint256 rootK = CamMath.sqrt(reserveA * reserveB);
            uint256 rootKLast = CamMath.sqrt(kLast);
            if (rootK > rootKLast) {
                // d = (feeDenominator * 100 / ownerFeeShare) - 100
                uint256 d = (feeDenominator * 100) / ownerFeeShare;
                if (d >= 100) {
                    d = d - 100;
                    uint256 liquidityNumer = lpTotalSupply * (rootK - rootKLast) * 100;
                    uint256 liquidityDenom = (rootK * d) + (rootKLast * 100);
                    if (liquidityDenom != 0) {
                        uint256 liquidity = liquidityNumer / liquidityDenom;
                        lpSupplyAdj += liquidity;
                    }
                }
            }
        }

        uint256 amountAWD = (ownedLPAmount * reserveA) / lpSupplyAdj;
        uint256 amountBWD = (ownedLPAmount * reserveB) / lpSupplyAdj;

        if (reserveB < amountBWD) return amountAWD;
        uint256 newReserveB = reserveB - amountBWD;
        uint256 newReserveA = reserveA - amountAWD;

        // Compute swap output using the same integer ordering as CamelotPair._getAmountOut
        // For a swap of TokenB->TokenA: reserveIn = newReserveB, reserveOut = newReserveA
        uint256 swapOut = 0;
        // amountIn is scaled by (feeDenominator - feePercent) (no division yet)
        uint256 amountInScaled = amountBWD * (feeDenominator - feePercent);
        uint256 denom = (newReserveB * feeDenominator) + amountInScaled;
        if (denom != 0) {
            // out = (amountInScaled * reserveOut) / denom
            swapOut = (amountInScaled * newReserveA) / denom;
        }

        totalAmountA = amountAWD + swapOut / 1; // keep integer semantics
        return totalAmountA;
    }
}
