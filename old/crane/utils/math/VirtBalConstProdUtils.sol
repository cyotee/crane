// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";

library VirtBalConstProdUtils {
    using BetterMath for uint256;
    // Import ConstProdUtils and use its logic where virtual balances don't alter the calculation
    using ConstProdUtils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10 ** 3;

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates the equivalent amount of Token B for a given amount of Token A based on virtual reserves.
     * @param amountA Amount of Token A to deposit.
     * @param virtReserveA Virtual balance for addition of Token A (from getBalanceForAddition(Token A)).
     * @param virtReserveB Virtual balance for addition of Token B (from getBalanceForAddition(Token B)).
     * @return amountB Equivalent amount of Token B required to maintain the virtual reserve ratio.
     */
    function _equivLiquidity(uint256 amountA, uint256 virtReserveA, uint256 virtReserveB)
        internal
        pure
        returns (uint256 amountB)
    {
        require(amountA > 0, "VirtBalConstProdUtils: INSUFFICIENT_AMOUNT");
        require(virtReserveA > 0 && virtReserveB > 0, "VirtBalConstProdUtils: INSUFFICIENT_LIQUIDITY");
        // Use virtual balances for addition to reflect the pool's pricing state
        amountB = (amountA * virtReserveB) / virtReserveA;
    }

    /**
     * @dev Calculates LP tokens to mint for a deposit, using virtual balances for addition.
     * @param amountADeposit Amount of Token A to deposit.
     * @param amountBDeposit Amount of Token B to deposit.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param virtReserveA Virtual balance for addition of Token A (from getBalanceForAddition(Token A)).
     * @param virtReserveB Virtual balance for addition of Token B (from getBalanceForAddition(Token B)).
     * @return lpAmount Amount of LP tokens to mint.
     * @notice Reminder: Update virtual balances (e.g., _virtBalAdds) after minting LP tokens if reserves change.
     */
    function _depositQuote(
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 lpTotalSupply,
        uint256 virtReserveA,
        uint256 virtReserveB
    ) internal pure returns (uint256 lpAmount) {
        if (lpTotalSupply == 0) {
            // First deposit: Use sqrt of product minus minimum liquidity
            lpAmount = BetterMath.sqrt(amountADeposit * amountBDeposit) - _MINIMUM_LIQUIDITY;
        } else {
            // Subsequent deposit: Use virtual balances for addition to determine proportional mint
            lpAmount = BetterMath.min(
                (amountADeposit * lpTotalSupply) / virtReserveA, (amountBDeposit * lpTotalSupply) / virtReserveB
            );
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                                WITHDRAW                                */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates owned token amounts from withdrawing LP tokens, using virtual balances for removal.
     * @param ownedLPAmount Amount of LP tokens to burn.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param virtReserveA Virtual balance for removal of Token A (from getBalanceForRemoval(Token A)).
     * @param virtReserveB Virtual balance for removal of Token B (from getBalanceForRemoval(Token B)).
     * @return ownedReserveA Owned share of Token A.
     * @return ownedReserveB Owned share of Token B.
     * @notice Reminder: Update virtual balances (e.g., _virtBalRems) after withdrawal if reserves change.
     */
    function _withdrawQuote(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 virtReserveA,
        uint256 virtReserveB
    ) internal pure returns (uint256 ownedReserveA, uint256 ownedReserveB) {
        // Use virtual balances for removal to ensure withdrawal reflects available liquidity
        ownedReserveA = (ownedLPAmount * virtReserveA) / lpTotalSupply;
        ownedReserveB = (ownedLPAmount * virtReserveB) / lpTotalSupply;
    }

    /**
     * @dev Calculates owned amount of one token from withdrawing LP tokens, using virtual balance for removal.
     * @param ownedLPAmount Amount of LP tokens to burn.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param virtReserveA Virtual balance for removal of Token A (from getBalanceForRemoval(Token A)).
     * @return ownedReserveA Owned share of Token A.
     * @notice Reminder: Update virtual balance (e.g., _virtBalRems(Token A)) after withdrawal.
     */
    function _withdrawQuoteOneSide(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 virtReserveA
    )
        internal
        pure
        returns (uint256 ownedReserveA)
    {
        ownedReserveA = (ownedLPAmount * virtReserveA) / lpTotalSupply;
    }

    /**
     * @dev Calculates LP tokens needed to withdraw a target amount of one token, using virtual balance for removal.
     * @param targetOutAmt Desired amount of the output token.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param virtOutRes Virtual balance for removal of the output token (from getBalanceForRemoval(output token)).
     * @return lpWithdrawAmt LP tokens to burn.
     * @notice Reminder: Update virtual balance (e.g., _virtBalRems) after withdrawal.
     */
    function _withdrawTargetQuote(uint256 targetOutAmt, uint256 lpTotalSupply, uint256 virtOutRes)
        internal
        pure
        returns (uint256 lpWithdrawAmt)
    {
        // Use virtual balance for removal to reflect available liquidity
        lpWithdrawAmt = (targetOutAmt * lpTotalSupply + virtOutRes - 1) / virtOutRes; // Ceiling division
    }

    /**
     * @dev Calculates accumulated maker fees per LP token using virtual reserves.
     * @param k_last Last stored product of virtual reserves (from previous _k calculation).
     * @param lpTotalSupply_last Last total supply of LP tokens (from _totalSupply() at last update).
     * @param virtReserveIT_current Current virtual balance for addition of Index Target (from getBalanceForAddition(IT)).
     * @param virtReserveOT_current Current virtual balance for addition of Other Token (from getBalanceForAddition(OT)).
     * @param lpTotalSupply_current Current total supply of LP tokens (from _totalSupply()).
     * @return feeITPerLp Fee per LP in Index Target terms.
     * @return feeOTPerLp Fee per LP in Other Token terms.
     * @notice Reminder: Update k_last and lpTotalSupply_last externally if fees are minted.
     */
    function _calcFeePerLp(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 k_last,
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 lpTotalSupply_last,
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 virtReserveIT_current,
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 virtReserveOT_current,
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 lpTotalSupply_current
    )
        internal
        pure
        returns (
            /// forge-lint: disable-next-line(mixed-case-variable)
            uint256 feeITPerLp,
            uint256 feeOTPerLp
        )
    {
        if (lpTotalSupply_last == 0) return (0, 0);

        // Use virtual balances for addition to calculate current K
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 k_current = virtReserveIT_current * virtReserveOT_current;
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 k_expected = (lpTotalSupply_current > lpTotalSupply_last)
            ? (k_last * lpTotalSupply_current) / lpTotalSupply_last
            : k_last;

        if (k_current <= k_expected) return (0, 0);

        uint256 feeFactor = ((k_current - k_expected) * 1e18) / k_current;
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 expectedIT = (virtReserveIT_current * 1e18) / (1e18 + feeFactor);
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 expectedOT = (virtReserveOT_current * 1e18) / (1e18 + feeFactor);

        feeITPerLp = (virtReserveIT_current > expectedIT)
            ? ((virtReserveIT_current - expectedIT) * 1e18) / lpTotalSupply_current
            : 0;
        feeOTPerLp = (virtReserveOT_current > expectedOT)
            ? ((virtReserveOT_current - expectedOT) * 1e18) / lpTotalSupply_current
            : 0;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  SWAP                                  */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates swap proceeds using virtual balances for addition and removal.
     * @param amountIn Amount of input token to sell.
     * @param virtReserveIn Virtual balance for addition of input token (from getBalanceForAddition(input token)).
     * @param virtReserveOut Virtual balance for removal of output token (from getBalanceForRemoval(output token)).
     * @param saleFeePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @return saleProceeds Amount of output token received.
     * @notice Reminder: Update virtual balances (e.g., _virtBalAdds, _virtBalRems) after the swap.
     */
    function _saleQuote(uint256 amountIn, uint256 virtReserveIn, uint256 virtReserveOut, uint256 saleFeePercent)
        internal
        pure
        returns (uint256 saleProceeds)
    {
        // Pass through to ConstProdUtils, using virtual balances instead of raw reserves
        saleProceeds = amountIn._saleQuote(virtReserveIn, virtReserveOut, saleFeePercent);
    }

    // /**
    //  * @dev Calculates minimum input for 1 unit of output using virtual balances.
    //  * @param virtSaleReserve Virtual balance for addition of sale token (from getBalanceForAddition(sale token)).
    //  * @param virtPurchaseReserve Virtual balance for removal of purchase token (from getBalanceForRemoval(purchase token)).
    //  * @param fee Swap fee numerator (e.g., 300 for 0.3%).
    //  * @param feeDenominator Fee denominator (e.g., 100000).
    //  * @return amountIn_min Minimum input amount for 1 unit output.
    //  */
    // function _saleQuoteMin(
    //     uint256 virtSaleReserve,
    //     uint256 virtPurchaseReserve,
    //     uint256 fee,
    //     uint256 feeDenominator
    // ) internal pure
    // /// forge-lint: disable-next-line(mixed-case-variable)
    // returns (uint256 amountIn_min) {
    //     // Pass through to ConstProdUtils with virtual balances
    //     amountIn_min = ConstProdUtils._saleQuoteMin(virtSaleReserve, virtPurchaseReserve, fee, feeDenominator);
    // }

    /**
     * @dev Calculates input amount needed for a desired output using virtual balances.
     * @param amountOut Desired output amount.
     * @param virtReserveIn Virtual balance for addition of input token (from getBalanceForAddition(input token)).
     * @param virtReserveOut Virtual balance for removal of output token (from getBalanceForRemoval(output token)).
     * @param feePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @return amountIn Required input amount.
     */
    function _purchaseQuote(uint256 amountOut, uint256 virtReserveIn, uint256 virtReserveOut, uint256 feePercent)
        internal
        pure
        returns (uint256 amountIn)
    {
        // Pass through to ConstProdUtils with virtual balances
        amountIn = ConstProdUtils._purchaseQuote(amountOut, virtReserveIn, virtReserveOut, feePercent);
    }

    /**
     * @dev Calculates sale amount for a ZapIn swap using virtual balance for addition.
     * @param amountIn Total input amount for ZapIn.
     * @param virtSaleReserve Virtual balance for addition of sale token (from getBalanceForAddition(sale token)).
     * @param feePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @return saleAmt Amount to sell in the swap.
     */
    function _swapDepositSaleAmt(uint256 amountIn, uint256 virtSaleReserve, uint256 feePercent)
        internal
        pure
        returns (uint256 saleAmt)
    {
        // Pass through to ConstProdUtils with virtual balance
        saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, virtSaleReserve, feePercent);
    }

    /* ---------------------------------------------------------------------- */
    /*                          SWAP/DEPOSIT (ZapIn)                          */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates LP tokens from a ZapIn deposit using virtual balances.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param amountIn Total amount of input token for ZapIn.
     * @param virtReserveIn Virtual balance for addition of input token (from getBalanceForAddition(input token)).
     * @param virtReserveOut Virtual balance for removal of output token (from getBalanceForRemoval(output token)).
     * @param feePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @return lpAmt LP tokens minted.
     * @notice Reminder: Update virtual balances (e.g., _virtBalAdds, _virtBalRems) after the ZapIn.
     */
    function _swapDepositQuote(
        uint256 lpTotalSupply,
        uint256 amountIn,
        uint256 virtReserveIn,
        uint256 virtReserveOut,
        uint256 feePercent
    ) internal pure returns (uint256 lpAmt) {
        uint256 amtInSaleAmt = amountIn._swapDepositSaleAmt(virtReserveIn, feePercent);
        uint256 opTokenAmtIn = amtInSaleAmt._saleQuote(virtReserveIn, virtReserveOut, feePercent);
        uint256 amountRemaining = amountIn - amtInSaleAmt;
        uint256 newReserveIn = virtReserveIn + amtInSaleAmt;
        uint256 newReserveOut = virtReserveOut - opTokenAmtIn;
        lpAmt = amountRemaining._depositQuote(opTokenAmtIn, lpTotalSupply, newReserveIn, newReserveOut);
    }

    /* ---------------------------------------------------------------------- */
    /*                              WITHDRAW/SWAP                             */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates ZapOut proceeds using virtual balances.
     * @param ownedLPAmount LP tokens to burn.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param virtExitReserve Virtual balance for removal of exit token (from getBalanceForRemoval(exit token)).
     * @param virtOpposingReserve Virtual balance for addition of opposing token (from getBalanceForAddition(opposing token)).
     * @param opTokenFeePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @return exitAmount Amount of exit token received.
     * @notice Reminder: Update virtual balances (e.g., _virtBalAdds, _virtBalRems) after the ZapOut.
     */
    function _withdrawSwapQuote(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 virtExitReserve,
        uint256 virtOpposingReserve,
        uint256 opTokenFeePercent
    ) internal pure returns (uint256 exitAmount) {
        (uint256 exitTokenOwnedReserve, uint256 opposingTokenOwnedReserve) = ownedLPAmount._withdrawQuote(
            lpTotalSupply, virtExitReserve, virtOpposingReserve
        );
        exitAmount = opposingTokenOwnedReserve._saleQuote(
            virtOpposingReserve - opposingTokenOwnedReserve, virtExitReserve - exitTokenOwnedReserve, opTokenFeePercent
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                          SWAP/DEPOSIT WITH FEES                        */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates protocol fee for ZapIn using virtual balances.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param newK New K value after operation (calculate externally with virtual balances).
     * @param kLast Last stored K value (from previous calculation).
     * @param ownerFeeShare Fee share percentage (e.g., 30000 for 30%).
     * @return feeAmount LP tokens to mint as protocol fee.
     * @notice Reminder: Update kLast externally if fee is minted.
     */
    function _calculateProtocolFee(uint256 lpTotalSupply, uint256 newK, uint256 kLast, uint256 ownerFeeShare)
        internal
        pure
        returns (uint256 feeAmount)
    {
        // Pass through to ConstProdUtils, as logic is identical with virtual balance-derived K
        feeAmount = ConstProdUtils._calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
    }

    /**
     * @dev Calculates LP tokens from ZapIn with protocol fees using virtual balances.
     * @param lpTotalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param amountIn Total input amount for ZapIn.
     * @param virtReserveIn Virtual balance for addition of input token (from getBalanceForAddition(input token)).
     * @param virtReserveOut Virtual balance for removal of output token (from getBalanceForRemoval(output token)).
     * @param feePercent Swap fee in PPHK (e.g., 300 for 0.3%).
     * @param kLast Last stored K value (from previous calculation).
     * @param ownerFeeShare Fee share percentage (e.g., 30000 for 30%).
     * @param feeOn Whether protocol fees are enabled.
     * @return lpAmt LP tokens minted.
     * @return protocolFee Protocol fee in LP tokens.
     * @notice Reminder: Update virtual balances and kLast externally after operation.
     */
    function _quoteSwapDepositWithFee(
        uint256 lpTotalSupply,
        uint256 amountIn,
        uint256 virtReserveIn,
        uint256 virtReserveOut,
        uint256 feePercent,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 lpAmt, uint256 protocolFee) {
        uint256 amtInSaleAmt = amountIn._swapDepositSaleAmt(virtReserveIn, feePercent);
        uint256 opTokenAmtIn = amtInSaleAmt._saleQuote(virtReserveIn, virtReserveOut, feePercent);
        uint256 amountRemaining = amountIn - amtInSaleAmt;
        uint256 newReserveIn = virtReserveIn + amtInSaleAmt;
        uint256 newReserveOut = virtReserveOut - opTokenAmtIn;

        if (feeOn && kLast != 0) {
            uint256 newK = newReserveIn * newReserveOut;
            protocolFee = _calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
        }

        lpAmt = amountRemaining._depositQuote(opTokenAmtIn, lpTotalSupply + protocolFee, newReserveIn, newReserveOut);
    }

    /* ---------------------------------------------------------------------- */
    /*                              PROTOCOL FEES                             */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates protocol fee and new K using virtual balances.
     * @param virtReserveA Virtual balance for addition of Token A (from getBalanceForAddition(Token A)).
     * @param virtReserveB Virtual balance for addition of Token B (from getBalanceForAddition(Token B)).
     * @param totalSupply Current total supply of LP tokens (from _totalSupply()).
     * @param lastK Last stored K value (from previous calculation).
     * @param vaultFee Fee share percentage (e.g., 30000 for 30%).
     * @return feeAmount LP tokens to mint as protocol fee.
     * @return newK New K value after operation.
     * @notice Reminder: Update kLast externally if fee is minted.
     */
    function _calculateProtocolFee(
        uint256 virtReserveA,
        uint256 virtReserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 vaultFee
    ) internal pure returns (uint256 feeAmount, uint256 newK) {
        // Use virtual balances for addition to calculate K
        newK = virtReserveA * virtReserveB;
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(lastK);
        if (rootK > rootKLast) {
            uint256 d = ((FEE_DENOMINATOR * 100) / vaultFee) - 100;
            uint256 numerator = (totalSupply * (rootK - rootKLast)) * 100;
            uint256 denominator = (rootK * d) + (rootKLast * 100);
            uint256 liquidity = numerator / denominator;
            if (liquidity > 0) feeAmount = liquidity;
        }
    }

    /**
     * @dev Calculates K value using virtual balances.
     * @param virtBalanceA Virtual balance for addition of Token A (from getBalanceForAddition(Token A)).
     * @param virtBalanceB Virtual balance for addition of Token B (from getBalanceForAddition(Token B)).
     * @return k Product of virtual balances.
     */
    function _k(uint256 virtBalanceA, uint256 virtBalanceB) internal pure returns (uint256 k) {
        k = virtBalanceA * virtBalanceB;
    }
}
