// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
import "contracts/crane/GeneralErrors.sol";
// import { Uint512, BetterMath} from "./BetterMath.sol";
import {Uint512, BetterMath as Math} from "contracts/crane/utils/math/BetterMath.sol";

library UniswapV2Utils {
    uint256 constant _MINIMUM_LIQUIDITY = 10 ** 3;

    /* ---------------------------------------------------------------------- */
    /*                                  Fees                                  */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates the protocol fee amount based on the growth of K value.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param newK The new K value after the operation.
     * @param kLast The last stored K value before the operation.
     * @param ownerFeeShare The fee share percentage for the protocol owner (e.g., 30000 for 30%).
     * @return lpOfYield The amount of LP tokens to be minted as a protocol fee.
     */
    function _calculateProtocolFee(uint256 lpTotalSupply, uint256 newK, uint256 kLast, uint256 ownerFeeShare)
        internal
        pure
        returns (uint256 lpOfYield)
    {
        // If kLast is 0 or newK <= kLast, no fee is charged
        if (kLast == 0 || newK <= kLast) {
            // console.log("No fee - kLast is zero or K hasn't grown");
            // console.log("=== _calculateProtocolFee END ===");
            return 0;
        }

        uint256 rootK = Math.sqrt(newK);
        uint256 rootKLast = Math.sqrt(kLast);

        if (rootK <= rootKLast) {
            return 0;
        }

        // Calculate the fee based on the growth of K
        // Formula from CamelotPair._mintFee:
        // uint d = (FEE_DENOMINATOR.mul(100) / ownerFeeShare).sub(100);
        // uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
        // uint denominator = rootK.mul(d).add(rootKLast.mul(100));
        // uint liquidity = numerator / denominator;

        uint256 d = (FEE_DENOMINATOR * 100) / ownerFeeShare - 100;
        // console.log("Intermediate - d:", d);

        uint256 numerator = lpTotalSupply * (rootK - rootKLast) * 100;

        uint256 denominator = rootK * d + rootKLast * 100;

        lpOfYield = numerator / denominator;
        return lpOfYield;
    }

    /* ---------------------------------------------------------------------- */
    /*                                Reserves                                */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Sorts reserves based on the known token and token0.
     * @param knownToken The token that is known.
     * @param token0 The token that is token0.
     * @param reserve0 The reserve of the known token.
     * @param reserve1 The reserve of the unknown token.
     * @return knownReserve The reserve of the known token.
     * @return unknownReserve The reserve of the unknown token.
     */
    function _sortReserves(address knownToken, address token0, uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint256 knownReserve, uint256 unknownReserve)
    {
        return knownToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    // tag::_equivLiquidity[]
    /**
     * @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     * @param amountA The amount of the first asset.
     * @param reserveA The reserve of the first asset.
     * @param reserveB The reserve of the second asset.
     * @return amountB The equivalent amount of the second asset.
     */
    function _equivLiquidity(uint256 amountA, uint256 reserveA, uint256 reserveB)
        internal
        pure
        returns (uint256 amountB)
    {
        require(amountA > 0, "UniswapV2Utils: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Utils: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // end::_equivLiquidity[]

    /**
     * @dev Provides the LP token mint amount for a given deposit, reserve, and total supply.
     * @param amountADeposit The amount of the first asset to deposit.
     * @param amountBDeposit The amount of the second asset to deposit.
     * @param lpTotalSupply The total supply of the LP token.
     * @param lpReserveA The reserve of the first asset in the LP.
     * @param lpReserveB The reserve of the second asset in the LP.
     * @return lpAmount The amount of the LP token to mint.
     */
    function _depositQuote(
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 lpTotalSupply,
        uint256 lpReserveA,
        uint256 lpReserveB
    ) internal pure returns (uint256 lpAmount) {
        if (lpTotalSupply == 0) {
            // First deposit case
            uint256 product = amountADeposit * amountBDeposit;

            uint256 sqrtProduct = Math.sqrt(product);

            lpAmount = sqrtProduct - _MINIMUM_LIQUIDITY;
        } else {
            // Normal deposit case
            /// forge-lint: disable-next-line(mixed-case-variable)
            uint256 amountA_ratio = (amountADeposit * lpTotalSupply) / lpReserveA;

            /// forge-lint: disable-next-line(mixed-case-variable)
            uint256 amountB_ratio = (amountBDeposit * lpTotalSupply) / lpReserveB;

            lpAmount = Math.min(amountA_ratio, amountB_ratio);
        }
        return lpAmount;
    }

    function _quoteDepositWithFee(
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 lpTotalSupply,
        uint256 lpReserveA,
        uint256 lpReserveB,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 lpAmt) {
        if (amountADeposit == 0 || amountBDeposit == 0 || lpTotalSupply == 0 || lpReserveA == 0 || lpReserveB == 0) {
            return (0);
        }
        uint256 protocolFee;
        uint256 newReserveA = lpReserveA + amountADeposit;
        uint256 newReserveB = lpReserveB + amountBDeposit;
        if (feeOn && kLast != 0) {
            uint256 newK = newReserveA * newReserveB;
            protocolFee = _calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
            lpTotalSupply += protocolFee;
        }
        lpAmt = _depositQuote(amountADeposit, amountBDeposit, lpTotalSupply, lpReserveA, lpReserveB);
        return (lpAmt);
    }

    /* ---------------------------------------------------------------------- */
    /*                                WITHDRAW                                */
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
    function _withdrawQuote(
        /// forge-lint: disable-next-line(mixed-case-variable)
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA,
        uint256 totalReserveB
    ) internal pure returns (uint256 ownedReserveA, uint256 ownedReserveB) {
        // Guard against division-by-zero — return zeros for empty pools or zero-owned LP
        if (lpTotalSupply == 0 || ownedLPAmount == 0) {
            return (0, 0);
        }

        // using balances ensures pro-rata distribution
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
        ownedReserveB = ((ownedLPAmount * totalReserveB) / lpTotalSupply);
    }

    function _quoteWithdrawWithFee(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA,
        uint256 totalReserveB,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 ownedReserveA, uint256 ownedReserveB) {
        if (ownedLPAmount == 0 || lpTotalSupply == 0 || totalReserveA == 0 || totalReserveB == 0) {
            return (0, 0);
        }
        if (ownedLPAmount > lpTotalSupply) {
            return (0, 0);
        }
        if (feeOn && kLast != 0) {
            // Calculate new reserves after withdrawal
            uint256 amountA = (ownedLPAmount * totalReserveA) / lpTotalSupply;
            uint256 amountB = (ownedLPAmount * totalReserveB) / lpTotalSupply;
            uint256 newReserveA = totalReserveA - amountA;
            uint256 newReserveB = totalReserveB - amountB;
            uint256 newK = newReserveA * newReserveB;
            // Calculate protocol fee based on reserve growth (if any, typically 0 for withdrawals)
            uint256 protocolFee = _calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
            lpTotalSupply += protocolFee;
        }
        // Calculate token amounts with adjusted supply
        (ownedReserveA, ownedReserveB) = _withdrawQuote(ownedLPAmount, lpTotalSupply, totalReserveA, totalReserveB);
    }

    /**
     * @dev Calculates the amount of LP to withdraw to extract a desired amount of one token.
     * @dev Returns 0 for edge cases: zero LP supply, zero reserves, or insufficient reserves.
     * @param targetOutAmt The amount of the token to withdraw.
     * @param lpTotalSupply The total supply of the LP token.
     * @param outRes The reserve of the token to withdraw.
     * @return lpWithdrawAmt The amount of the LP token to withdraw.
     */
    function _withdrawTargetQuote(uint256 targetOutAmt, uint256 lpTotalSupply, uint256 outRes)
        internal
        pure
        returns (uint256 lpWithdrawAmt)
    {
        if (lpTotalSupply == 0 || outRes == 0 || targetOutAmt == 0) {
            return 0;
        }

        // Check if target amount exceeds available reserves
        if (targetOutAmt > outRes) {
            return 0;
        }

        // Calculate LP amount needed, using ceiling division to ensure enough LP is provided
        lpWithdrawAmt = (targetOutAmt * lpTotalSupply + outRes - 1) / outRes;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  SWAP                                  */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates the proceeds of a swap.
     * @param amountIn The amount of token to be sold.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param saleFeePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @return saleProceeds The proceeds of the swap.
     */
    function _saleQuote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 saleFeePercent)
        internal
        pure
        returns (uint256)
    {
        // uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - saleFeePercent) / FEE_DENOMINATOR;
        // uint256 numerator = amountInWithFee * reserveOut;
        // uint256 denominator = reserveIn + amountInWithFee;
        // uint256 result = numerator / denominator;
        // return result;
        return _saleQuote(
            // uint256 amountIn,
            amountIn,
            // uint256 reserveIn,
            reserveIn,
            // uint256 reserveOut,
            reserveOut,
            // uint256 saleFeePercent,
            saleFeePercent,
            // uint256 feeDenominator
            FEE_DENOMINATOR
        );
    }

    /**
     * @dev Calculates the proceeds of a swap.
     * @param amountIn The amount of token to be sold.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param saleFeePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @return saleProceeds The proceeds of the swap.
     */
    function _saleQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 saleFeePercent,
        uint256 feeDenominator
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * (feeDenominator - saleFeePercent) / feeDenominator;

        uint256 numerator = amountInWithFee * reserveOut;

        uint256 denominator = reserveIn + amountInWithFee;

        uint256 result = numerator / denominator;
        return result;
    }

    /**
     * @dev Calculates the amount of token to sell to effect a purchase of a desired amount of the other token.
     * @param amountOut The amount of the token to purchase.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param feePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @return amountIn The amount of the token to sell.
     */
    function _purchaseQuote(uint256 amountOut, uint256 reserveIn, uint256 reserveOut, uint256 feePercent)
        internal
        pure
        returns (uint256 amountIn)
    {
        // require(amountOut > 0, "Invalid output amount");
        // require(reserveIn > 0 && reserveOut > amountOut, "Insufficient liquidity");
        // uint256 numerator = (reserveIn * amountOut) * FEE_DENOMINATOR;
        // uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - feePercent);
        // amountIn = (numerator / denominator) + 1;
        // // amountIn = (numerator / denominator);
        return _purchaseQuote(amountOut, reserveIn, reserveOut, feePercent, FEE_DENOMINATOR);
    }

    /**
     * @dev Calculates the amount of token to sell to effect a purchase of a desired amount of the other token.
     * @param amountOut The amount of the token to purchase.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param feePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @param feeDenominator The fee denominator used by the pool (e.g., 100,000).
     * @return amountIn The amount of the token to sell.
     */
    function _purchaseQuote(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal pure returns (uint256 amountIn) {
        // require(amountOut > 0, "Invalid output amount");
        if (amountOut == 0) revert ArgumentMustNotBeZero(0);
        // require(reserveIn > 0 && reserveOut > amountOut, "Insufficient liquidity");
        if (reserveIn == 0) revert ArgumentMustNotBeZero(1);
        if (reserveOut <= amountOut) revert ArgumentMustBeGreaterThan(2, 0);
        uint256 numerator = (reserveIn * amountOut) * feeDenominator;
        uint256 denominator = (reserveOut - amountOut) * (feeDenominator - feePercent);
        amountIn = (numerator / denominator) + 1;
        // amountIn = (numerator / denominator);
    }

    /* ---------------------------------------------------------------------- */
    /*                           Yield Calculations                           */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates the portion of reserves attributable to market maker fees for a specific LP position
     * in a Uniswap V2-like pool, ensuring non-negative yields for vault fee calculations.
     * Returns unsigned integers, clamping negatives to 0 (ignoring IL effects).
     * @param ownedLP Amount of LP tokens owned by the position.
     * @param initialA Initial amount of Token A deposited to mint ownedLP.
     * @param initialB Initial amount of Token B deposited to mint ownedLP.
     * @param reserveA Current reserve of Token A in the pool.
     * @param reserveB Current reserve of Token B in the pool.
     * @param totalSupply Current LP total supply (includes past protocol fee mints).
     * @return feeA Portion of Token A reserves from swap fees (non-negative).
     * @return feeB Portion of Token B reserves from swap fees (non-negative).
     */
    // NOTE MOST PRECISE
    function _calculateFeePortionForPosition(
        uint256 ownedLP,
        uint256 initialA,
        uint256 initialB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply
    ) internal pure returns (uint256 feeA, uint256 feeB) {
        if (totalSupply == 0 || ownedLP == 0 || reserveA == 0 || reserveB == 0) {
            return (0, 0);
        }
        // Actual claimable amounts
        uint256 claimableA = (ownedLP * reserveA) / totalSupply;
        uint256 claimableB = (ownedLP * reserveB) / totalSupply;
        // Hypothetical no-fee claimable amounts (adjusted for current price ratio)
        uint256 tempA = (initialA * initialB * reserveA) / reserveB;
        uint256 noFeeA = Math.sqrt(tempA);
        uint256 tempB = (initialA * initialB * reserveB) / reserveA;
        uint256 noFeeB = Math.sqrt(tempB);
        // Fee portions, clamped to 0
        feeA = claimableA > noFeeA ? claimableA - noFeeA : 0;
        feeB = claimableB > noFeeB ? claimableB - noFeeB : 0;
    }
}
