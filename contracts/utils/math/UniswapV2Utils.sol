// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Math as UniV2Math} from "@crane/contracts/protocols/dexes/uniswap/v2/deps/libs/Math.sol";
import "@crane/contracts/constants/Constants.sol";

/**
 * @title UniswapV2Utils
 * @dev Small helper library that reproduces UniswapV2 pair math for quoting
 *      withdraw-then-swap flows. This mirrors the pair's exact fee-mint
 *      calculation and Uniswap swap formula so callers can obtain identical
 *      integer-rounded results.
 */
library UniswapV2Utils {
    /**
     * @dev Quote total TokenA obtained when burning `ownedLPAmount` LP tokens
     *      and swapping the withdrawn TokenB -> TokenA using Uniswap V2 math.
     *      This function mirrors Uniswap V2's `_mintFee` (owner fee mint) and
     *      its getAmountOut arithmetic (with integer rounding) to ensure parity
     *      with on-chain pair execution.
     * @param ownedLPAmount LP tokens to burn
     * @param lpTotalSupply current LP total supply
     * @param reserveA current reserve of TokenA
     * @param reserveB current reserve of TokenB
    * @param feePercent swap fee numerator (e.g., 300 for 0.3% when denom=100000)
     * @param kLast pair.kLast value (used by Uniswap fee mint); pass 0 to disable
     * @param feeToOn whether Uniswap-style feeTo mint should be applied
     * @return totalAmountA amount of TokenA expected after burn+swap
     */
    function _quoteWithdrawSwapFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feePercent,
        uint256 /* feeDenominator */, // kept for signature compatibility
        uint256 kLast,
        bool feeToOn
    ) internal pure returns (uint256 totalAmountA) {
        if (ownedLPAmount == 0 || lpTotalSupply == 0 || reserveA == 0 || reserveB == 0) {
            return 0;
        }
        // (feeDenom validated below after selecting repo-consistent denominator)
        if (ownedLPAmount > lpTotalSupply) return 0;

        uint256 lpSupplyAdj = lpTotalSupply;

        // Mirror Uniswap V2 _mintFee exact calculation when feeTo is set
        if (feeToOn && kLast != 0) {
            uint256 rootK = UniV2Math._sqrt(reserveA * reserveB);
            uint256 rootKLast = UniV2Math._sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 liquidityNumer = lpTotalSupply * (rootK - rootKLast);
                uint256 liquidityDenom = (rootK * 5) + rootKLast;
                if (liquidityDenom != 0) {
                    uint256 liquidity = liquidityNumer / liquidityDenom;
                    lpSupplyAdj += liquidity;
                }
            }
        }

        // Owned token amounts after burning (uses adjusted supply)
        uint256 amountAWD = (ownedLPAmount * reserveA) / lpSupplyAdj;
        uint256 amountBWD = (ownedLPAmount * reserveB) / lpSupplyAdj;

        // Reserves after the burn (used for swap calculation)
        if (reserveB < amountBWD) return amountAWD; // defensive
        uint256 newReserveB = reserveB - amountBWD;
        uint256 newReserveA = reserveA - amountAWD;

        // Determine fee denominator the same way ConstProdUtils does:
        // small-int fees (<= 10) use 1000, otherwise use FEE_DENOMINATOR (100000)
        uint256 feeDenom = (feePercent <= 10) ? 1000 : uint256(FEE_DENOMINATOR);

        // Uniswap swap formula (integer math)
        // amountInWithFee = amountBWD * (feeDenom - feePercent)
        // numerator = amountInWithFee * newReserveA
        // denominator = newReserveB * feeDenom + amountInWithFee
        if (amountBWD == 0) return amountAWD;
        uint256 oneMinusFee = feeDenom - feePercent;
        uint256 amountInWithFee = amountBWD * oneMinusFee;
        uint256 numerator = amountInWithFee * newReserveA;
        uint256 denominator = (newReserveB * feeDenom) + amountInWithFee;
        uint256 swapOut = 0;
        if (denominator != 0) swapOut = numerator / denominator;

        totalAmountA = amountAWD + swapOut;
        return totalAmountA;
    }
}
