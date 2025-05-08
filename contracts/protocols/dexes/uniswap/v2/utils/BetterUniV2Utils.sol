// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    Uint512,
    BetterMath
} from "../../../../../utils/math/BetterMath.sol";

library BetterUniV2Utils {

    using BetterMath for uint256;
    using BetterMath for Uint512;
    using BetterUniV2Utils for uint256;

    uint constant _MINIMUM_LIQUIDITY = 10**3;

    // tag::_quote[]
    /**
     * @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function _calcEquiv(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "UniV2Utils: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniV2Utils: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
    // end::_quote[]

    // tag::_quoteSwapIn[]
    /**
     * @dev Provides the proceeds of a sale of a provided amount.
     * @param amountIn The amount of token for which too quote a sale.
     * @param reserveIn The LP reserve of the sale token.
     * @param reserveOut The LP reserve of the proceeds tokens.
     * @return amountOut The proceeds of selling `amountIn`.
     */
    function _calcSaleProceeds(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = (amountIn * 997);
        uint numerator = (amountInWithFee * reserveOut);
        uint denominator = (reserveIn * 1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }
    // end::_quoteSwapIn[]

    // tag::_quoteSwapOut[]
    /**
     * @dev Provides the sale amount for a desired proceeds amount.
     * @param amountOut The desired swap proceeds.
     * @param reserveIn The LP reserve of the sale token.
     * @param reserveOut The LP reserve of the proceeds tokens.
     * @return amountIn The amount of token to sell to get the desired proceeds.
     */
    function _calcSaleAmount(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        uint numerator = (reserveIn * amountOut) * (1000);
        uint denominator = (reserveOut - amountOut) * (997);
        amountIn = (numerator / denominator) + (1);
    }
    // end::_quoteSwapOut[]

    // tag::_calcExit[]
    /**
     * @dev Calculates the proceeds of of a swap MINUS a portion of liquidity.
     * @param saleTokenTotalReserve LP reserve of token to be sold BEFORE withdraw.
     * @param saleTokenOwnedReserve Owned sharre of LP reserve of token to be sold.
     * @param exitTokenTotalReserve LP reserve of token to purchased BEFORE withdraw.
     * @param exitTokenOwnedReserve Owned sharre of LP reserve of token to be purchsed.
     * @return exitAmount
     */
    function _calcExit(
        uint256 saleTokenTotalReserve,
        uint256 saleTokenOwnedReserve,
        uint256 exitTokenTotalReserve,
        uint256 exitTokenOwnedReserve
    ) internal pure returns(uint256 exitAmount) {
        uint256 saleProceeds = BetterUniV2Utils
        ._calcSaleProceeds(
            saleTokenOwnedReserve,
            saleTokenTotalReserve - saleTokenOwnedReserve,
            exitTokenTotalReserve - exitTokenOwnedReserve
        );
        exitAmount = exitTokenOwnedReserve + saleProceeds;
    }
    // end::_calcExit[]

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

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

    // tag::_calcReserveShares[]
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
    function _calcReserveShares(
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
    // end::_calcReserveShares[]

    function _calcReserveShare(
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
        uint256 opRes
    ) internal pure returns(uint256 lpWithdrawAmt) {
        uint256 opTAmt = _calcEquiv(
            targetOutAmt,
            outRes,
            opRes
        );
        lpWithdrawAmt = _calcDeposit(
            targetOutAmt,
            opTAmt,
            lpTotalSupply,
            outRes,
            opRes
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                                Combined                                */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------- Swap/Deposit ---------------------------- */

    function _calcSwapDeposit(
        uint256 saleTokenAmount,
        uint256 lpTotalSupply,
        uint256 saleTokenReserve,
        uint256 opposingTokenReserve
    ) internal pure returns(uint256 lpProceeds) {
        uint256 amountToSwap = _calcSwapDepositAmtIn(saleTokenAmount, saleTokenReserve);
        uint256 saleTokenDeposit = saleTokenAmount - amountToSwap;
        uint256 opposingTokenDeposit = _calcSaleProceeds(
            amountToSwap,
            saleTokenReserve,
            opposingTokenReserve
        );

        lpProceeds = _calcDeposit(
            saleTokenDeposit,
            opposingTokenDeposit,
            lpTotalSupply,
            saleTokenReserve + amountToSwap,
            opposingTokenReserve - opposingTokenDeposit
        );
    }

    function _calcSwapDepositAmtIn(
        uint256 userIn,
        uint256 reserveIn
    ) internal pure returns (uint256 swapAmount_) {
      return (
            BetterMath.sqrt(
                reserveIn 
                * (
                    (userIn * 3988000) + (reserveIn * 3988009)
                )
            ) - (reserveIn * 1997)
        ) / 1994;
    }

    /* ---------------------------- Withdraw/Swap --------------------------- */

    function _calcWithdrawSwap(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 exitTokenTotalReserve,
        uint256 opposingTokenTotalReserve
    ) internal pure returns(uint256 exitAmount) {
        (
            uint256 exitTokenOwnedReserve,
            uint256 opposingTokenOwnedReserve
        ) = ownedLPAmount._calcReserveShares(
            lpTotalSupply,
            exitTokenTotalReserve,
            opposingTokenTotalReserve
        );
        exitAmount = opposingTokenTotalReserve
        ._calcExit(
            // saleTokenTotalReserve
            // saleTokenOwnedReserve
            opposingTokenOwnedReserve,
            // exitTokenTotalReserve
            exitTokenTotalReserve,
            // exitTokenOwnedReserve
            exitTokenOwnedReserve
        );
    }

    // _reduceExposureToTargetQuote
    /**
     * @dev exitTokenReserve = index Target = token for targetSettlementAmount
     * @dev Returns 0 if LP reserve is lower then `targetSettlementAmount`.
     */
    // TODO Double check with tests. Make sure reserve args are correct.
    function _calcReduceExposureToTarget(
        uint256 targetSettlementAmount,
        uint256 exitTokenReserve,
        uint256 opTokenReserve,
        uint256 lpTotalSupply
    ) internal pure returns (
        uint256 lpAmountToWithdraw
    ) {
        if (exitTokenReserve > targetSettlementAmount) {
            lpAmountToWithdraw = _calcLpSettlement(
                // uint reserveI,
                exitTokenReserve,
                // uint reserveO,
                opTokenReserve,
                // uint256 targetSettlementAmount,
                targetSettlementAmount,
                // uint256 supply
                lpTotalSupply
            );
        } else  {
            lpAmountToWithdraw = 0;
        }
        // lpAmountToWithdraw = lpAmount;
        //  > pair.balanceOf(holder) ? 0 : lpAmount;
    }

    /**
     * @dev reserveI = index Target = token for targetSettlementAmount
     */
    function _calcLpSettlement(
        uint reserveI,
        uint reserveO,
        uint256 targetSettlementAmount,
        uint256 supply
    ) internal pure returns (uint256 LpSettlement) { 
        uint a1 = (reserveO * reserveI) / supply;
        uint a2 = supply;
        uint b = _calcLpSettlement__partB(reserveI, reserveO, targetSettlementAmount, supply);
        uint c = (targetSettlementAmount * reserveO);

        uint Lp1;
        uint Lp2;
        uint Lp3;
        {
            Lp1 = (b * a2);
            Lp2 = (a2 * BetterMath.sqrt((b * b) - (BetterMath.mul512ForUint512(a1, (c * 4)).div256(a2))));
            Lp3 = (a1 * 2);
        }

        LpSettlement = ((Lp1 - Lp2)) / (Lp3);
    }

    function _calcLpSettlement__partB(
        uint reserveI,
        uint reserveO,
        uint256 targetSettlementAmount,
        uint256 supply
    ) private pure returns (
        uint b
    ) { 
        uint gamma = 997;

        uint b1 = (targetSettlementAmount * reserveO) * (1000);
        uint b2 = ((targetSettlementAmount * gamma) * (reserveO));
        uint b3 = ((reserveO * reserveI) * (1000));
        uint b4 = (reserveO * reserveI) * (gamma);
        uint b5 = (supply * 1000);

        b = (b1 - b2 + b3 + b4) / b5;
    }

    /* ---------------------------- Swap/Withdraw --------------------------- */

    function _calcSwapWithdraw(
        uint256 targetAmtOut,
        uint256 tokenOutRes_,
        uint256 opTokenRes_
    ) internal pure returns(uint256 swapAmt) {
        uint256 opResWFee_ = opTokenRes_ * 1000;
        uint256 numerator = opResWFee_.mulWadDown(targetAmtOut);
        uint256 outResWFee_ = tokenOutRes_ * 997;
        uint256 outResAmtOut = targetAmtOut * 997;
        uint256 denominator = outResWFee_ - outResAmtOut;
        swapAmt = numerator.divWadDown(denominator);
    }

}