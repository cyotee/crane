// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@crane/contracts/constants/Constants.sol";
import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol";

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

    // /**
    //  * @dev Mirror CamelotPair._mintFee + burn math exactly to compute the
    //  *      fee portion (token amounts) attributable to `ownedLP`.
    //  *
    //  * Parameters mirror the values available in tests: owned LP, the original
    //  * position token amounts, current reserves, current total supply, the
    //  * pair's kLast, the factory owner fee share, the pair fee denominator and
    //  * whether fee is considered on (feeTo != address(0)).
    //  */
    // function _calculateFeePortionForPosition(
    //     uint256 ownedLP,
    //     uint256 initialPositionA,
    //     uint256 initialPositionB,
    //     uint256 reserveA,
    //     uint256 reserveB,
    //     uint256 lpTotalSupply
    // ) public pure returns (uint256 calculatedFeeA, uint256 calculatedFeeB) {
    //     if (ownedLP == 0 || lpTotalSupply == 0 || reserveA == 0 || reserveB == 0) return (0, 0);

    //     // Use the provided total supply from the pair; tests supply the live
    //     // `totalSupply()` so performing an additional simulated mint here can
    //     // double-count protocol fee mints and skew pro-rata math. Keep the
    //     // supply exactly as passed in to match `ConstProdUtils` expectations.
    //     // uint256 _totalSupply = lpTotalSupply;

    //     // Claimable amounts after possible fee mint
    //     uint256 claimableA = (ownedLP * reserveA) / lpTotalSupply;
    //     uint256 claimableB = (ownedLP * reserveB) / lpTotalSupply;

    //     // No-fee baseline using Camelot's sqrt-based math (same as test expectation)
    //     uint256 tempA = 0;
    //     uint256 tempB = 0;
    //     if (reserveB != 0) tempA = (initialPositionA * initialPositionB * reserveA) / reserveB;
    //     if (reserveA != 0) tempB = (initialPositionA * initialPositionB * reserveB) / reserveA;
    //     uint256 noFeeA = CamMath.sqrt(tempA);
    //     uint256 noFeeB = CamMath.sqrt(tempB);

    //     calculatedFeeA = claimableA > noFeeA ? claimableA - noFeeA : 0;
    //     calculatedFeeB = claimableB > noFeeB ? claimableB - noFeeB : 0;
    //     return (calculatedFeeA, calculatedFeeB);
    // }
}
