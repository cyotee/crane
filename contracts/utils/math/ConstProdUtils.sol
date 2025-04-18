// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import "forge-std/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";
import {betterconsole as console} from "../vm/foundry/tools/console/betterconsole.sol";

import "../../constants/Constants.sol";
import {BetterMath} from "./BetterMath.sol";

library ConstProdUtils {

    using ConstProdUtils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10**3;

    // uint256 constant FEE_DENOMINATOR = 100_000;
    
    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    // tag::_quote[]
    /**
     * @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function _equivLiquidity(
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
    function _depositQuote(
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 lpTotalSupply,
        uint256 lpReserveA,
        uint256 lpReserveB
    ) internal pure returns(uint256 lpAmount) {
        // lpAmount = lpTotalSupply == 0
        //     ? BetterMath._sqrt((amountADeposit * amountBDeposit)) - _MINIMUM_LIQUIDITY
        //     : BetterMath._min(
        //         (amountADeposit * lpTotalSupply) / lpReserveA,
        //         (amountBDeposit * lpTotalSupply) / lpReserveB
        //     );
        // console.log("=== _depositQuote START ===");
        // console.log("Input params - amountADeposit:", amountADeposit);
        // console.log("Input params - amountBDeposit:", amountBDeposit);
        // console.log("Input params - lpTotalSupply:", lpTotalSupply);
        // console.log("Input params - lpReserveA:", lpReserveA);
        // console.log("Input params - lpReserveB:", lpReserveB);
        
        if (lpTotalSupply == 0) {
            // First deposit case
            uint256 product = amountADeposit * amountBDeposit;
            // console.log("First deposit - product:", product);
            
            uint256 sqrtProduct = BetterMath._sqrt(product);
            // console.log("First deposit - sqrt(product):", sqrtProduct);
            
            lpAmount = sqrtProduct - _MINIMUM_LIQUIDITY;
            // console.log("First deposit - lpAmount:", lpAmount);
        } else {
            // Normal deposit case
            uint256 amountA_ratio = (amountADeposit * lpTotalSupply) / lpReserveA;
            // console.log("Normal deposit - amountA_ratio:", amountA_ratio);
            
            uint256 amountB_ratio = (amountBDeposit * lpTotalSupply) / lpReserveB;
            // console.log("Normal deposit - amountB_ratio:", amountB_ratio);
            
            lpAmount = BetterMath._min(amountA_ratio, amountB_ratio);
            // console.log("Normal deposit - min(ratios):", lpAmount);
        }
        
        // console.log("Final lpAmount:", lpAmount);
        // console.log("=== _depositQuote END ===");
        
        return lpAmount;
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
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA,
        uint256 totalReserveB
    ) internal pure returns(
        uint256 ownedReserveA,
        uint256 ownedReserveB
    ) {
        // console.log("=== _withdrawQuote START ===");
        // console.log("Input - ownedLPAmount:", ownedLPAmount);
        // console.log("Input - lpTotalSupply:", lpTotalSupply);
        // console.log("Input - totalReserveA:", totalReserveA);
        // console.log("Input - totalReserveB:", totalReserveB);

        // using balances ensures pro-rata distribution
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
        ownedReserveB = ((ownedLPAmount * totalReserveB) / lpTotalSupply);

        // console.log("Output - ownedReserveA:", ownedReserveA);
        // console.log("Output - ownedReserveB:", ownedReserveB);
        // console.log("=== _withdrawQuote END ===");
    }

    function _withdrawQuoteOneSide(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 totalReserveA
    ) internal pure returns(uint256 ownedReserveA) {
        // console.log("=== _withdrawQuoteOneSide START ===");
        // console.log("Input - ownedLPAmount:", ownedLPAmount);
        // console.log("Input - lpTotalSupply:", lpTotalSupply);
        // console.log("Input - totalReserveA:", totalReserveA);

        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);

        // console.log("Output - ownedReserveA:", ownedReserveA);
        // console.log("=== _withdrawQuoteOneSide END ===");
    }

    /**
     * @dev Calculates the amount of LP to withdraw to extract a desired amount of one token.
     * @dev Returns 0 for edge cases: zero LP supply, zero reserves, or insufficient reserves.
     */
    function _withdrawTargetQuote(
        uint256 targetOutAmt,
        uint256 lpTotalSupply,
        uint256 outRes
    ) internal pure returns (uint256 lpWithdrawAmt) {
        // console.log("=== _withdrawTargetQuote START ===");
        // console.log("Input - targetOutAmt:", targetOutAmt);
        // console.log("Input - lpTotalSupply:", lpTotalSupply);
        // console.log("Input - outRes:", outRes);

        // Edge cases
        if (lpTotalSupply == 0 || outRes == 0 || targetOutAmt == 0) {
            // console.log("Edge case detected - returning 0");
            // console.log("lpTotalSupply == 0:", lpTotalSupply == 0);
            // console.log("outRes == 0:", outRes == 0);
            // console.log("targetOutAmt == 0:", targetOutAmt == 0);
            return 0;
        }
        
        // Check if target amount exceeds available reserves
        if (targetOutAmt > outRes) {
            // console.log("Target amount exceeds reserves");
            // console.log("targetOutAmt:", targetOutAmt);
            // console.log("outRes:", outRes);
            return 0;
        }

        // Calculate LP amount needed, using ceiling division to ensure enough LP is provided
        lpWithdrawAmt = (targetOutAmt * lpTotalSupply + outRes - 1) / outRes;
        // console.log("Calculated lpWithdrawAmt:", lpWithdrawAmt);
        // console.log("=== _withdrawTargetQuote END ===");
    }

    /**
     * @dev Calculates the accumulated maker fees per LP token in IT and OT terms.
     * @param k_last Last stored product of reserves (reserveIT_last * reserveOT_last).
     * @param lpTotalSupply_last Last stored total LP token supply.
     * @param reserveIT_current Current reserve of Index Target (IT) token.
     * @param reserveOT_current Current reserve of Other Token (OT).
     * @param lpTotalSupply_current Current total LP token supply.
     * @return feeITPerLp Fee per LP token in IT terms.
     * @return feeOTPerLp Fee per LP token in OT terms.
     */
    function _calcFeePerLp(
        uint256 k_last,
        uint256 lpTotalSupply_last,
        uint256 reserveIT_current,
        uint256 reserveOT_current,
        uint256 lpTotalSupply_current
    ) internal pure returns (uint256 feeITPerLp, uint256 feeOTPerLp) {
        // No existing liquidity, so no fees accrued
        if (lpTotalSupply_last == 0) {
            return (0, 0);
        }

        // Calculate current K
        uint256 k_current = reserveIT_current * reserveOT_current;

        // Compute expected K based on the last known reserves and current LP supply
        uint256 k_expected;
        if (lpTotalSupply_current > lpTotalSupply_last) {
            k_expected = (k_last * lpTotalSupply_current) / lpTotalSupply_last;
        } else {
            k_expected = k_last;
        }

        // If k_current <= k_expected, no fees
        if (k_current <= k_expected) {
            return (0, 0);
        }

        // Calculate fee factor
        uint256 feeFactor = ((k_current - k_expected) * 1e18) / k_current;

        // Calculate expected reserves adjusted by fee factor
        uint256 expectedIT = (reserveIT_current * 1e18) / (1e18 + feeFactor);
        uint256 expectedOT = (reserveOT_current * 1e18) / (1e18 + feeFactor);

        // Calculate the fees per LP - with overflow protection
        if (reserveIT_current > expectedIT) {
            feeITPerLp = ((reserveIT_current - expectedIT) * 1e18) / lpTotalSupply_current;
        } else {
            feeITPerLp = 0; // Prevent underflow
        }
        
        if (reserveOT_current > expectedOT) {
            feeOTPerLp = ((reserveOT_current - expectedOT) * 1e18) / lpTotalSupply_current;
        } else {
            feeOTPerLp = 0; // Prevent underflow
        }
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
    // function _saleQuote(
    //     uint256 amountIn,
    //     uint256 reserveIn,
    //     uint256 reserveOut,
    //     uint256 saleFeePercent
    // ) internal pure returns (uint) {
    //     // console.log("=== _saleQuote START ===");
    //     // console.log("Input params - amountIn:", amountIn);
    //     // console.log("Input params - reserveIn:", reserveIn);
    //     // console.log("Input params - reserveOut:", reserveOut);
    //     // console.log("Input params - saleFeePercent:", saleFeePercent);
        
    //     uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - saleFeePercent);
    //     // console.log("Intermediate - amountInWithFee:", amountInWithFee);
        
    //     uint256 numerator = amountInWithFee * reserveOut;
    //     // console.log("Intermediate - numerator:", numerator);
        
    //     uint256 denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
    //     // uint256 denominator = (reserveIn) + amountInWithFee;
    //     // console.log("Intermediate - denominator:", denominator);
        
    //     uint256 result = numerator / denominator;
    //     // console.log("Final result:", result);
    //     // console.log("=== _saleQuote END ===");
        
    //     return result;
    // }
    // function _saleQuote(
    //     uint256 amountIn,
    //     uint256 reserveIn,
    //     uint256 reserveOut,
    //     uint256 saleFeePercent
    // ) internal pure returns (uint) {
    //     uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - saleFeePercent) / FEE_DENOMINATOR;
    //     uint256 numerator = amountInWithFee * reserveOut;
    //     uint256 denominator = reserveIn + amountInWithFee;
    //     return numerator / denominator;
    // }
function _saleQuote(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 saleFeePercent
) internal pure returns (uint) {
    uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - saleFeePercent) / FEE_DENOMINATOR;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn + amountInWithFee;
    return numerator / denominator;
}

    /**
     * @dev Calculates the minimum input amount required to receive at least 1 unit of output token.
     * @param saleReserve The reserve of the input token in the pool.
     * @param purchaseReserve The reserve of the output token in the pool.
     * @param fee The fee numerator provided by the pool (e.g., 500 for 0.5% fee).
     * @param feeDenominator The fee denominator used by the pool (e.g., 100,000).
     * @return amountIn_min The minimum amount of input tokens required.
     */
    function _saleQuoteMin(
        uint256 saleReserve,
        uint256 purchaseReserve,
        uint256 fee,
        uint256 feeDenominator
    ) public pure returns (uint256 amountIn_min) {
        // Input validation
        require(purchaseReserve > 1, "ReserveB must be greater than 1");
        require(fee < feeDenominator, "Fee must be less than feeDenominator");
        require(feeDenominator > 0, "Invalid feeDenominator");

        // Calculate the multiplier from fee and feeDenominator
        uint256 multiplier = feeDenominator - fee;

        // Step 1: Calculate k_min
        // k_min = ceil((saleReserve + purchaseReserve - 2) / (purchaseReserve - 1))
        uint256 numeratorK = saleReserve + purchaseReserve - 2;
        uint256 denominatorK = purchaseReserve - 1;
        uint256 k_min = (numeratorK + denominatorK - 1) / denominatorK; // Ceiling division

        // Step 2: Calculate amountIn_min with fee adjustment
        // amountIn_min = ceil((k_min * feeDenominator) / multiplier)
        uint256 numeratorAmountIn = k_min * feeDenominator;
        amountIn_min = (numeratorAmountIn + multiplier - 1) / multiplier; // Ceiling division

        return amountIn_min;
    }

    /**
     * @dev Calculates the amount of token to sell to effect a purchase of a desired amount of the other token.
     */
    function _purchaseQuote(
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

    // function _swapDepositSaleAmt(
    //     uint256 amountIn,
    //     uint256 saleReserve,
    //     uint256 feePercent
    // ) internal pure returns(uint256 saleAmt) {
    //     // console.log("=== _swapDepositSaleAmt START ===");
    //     // console.log("Input params - amountIn:", amountIn);
    //     // console.log("Input params - saleReserve:", saleReserve);
    //     // console.log("Input params - feePercent:", feePercent);
        
    //     uint256 twoMinusFee = 2 * FEE_DENOMINATOR - feePercent;
    //     uint256 oneMinusFee = 1 * FEE_DENOMINATOR - feePercent;
    //     // console.log("Intermediate - twoMinusFee:", twoMinusFee);
    //     // console.log("Intermediate - oneMinusFee:", oneMinusFee);
        
    //     // Calculate the square term
    //     uint256 term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve;
    //     // console.log("Intermediate - term1 (squared part 1):", term1);
        
    //     uint256 term2 = 4 * oneMinusFee * FEE_DENOMINATOR * amountIn * saleReserve;
    //     // console.log("Intermediate - term2 (squared part 2):", term2);
        
    //     uint256 sqrtTerm = BetterMath._sqrt(term1 + term2);
    //     // console.log("Intermediate - sqrtTerm (sqrt result):", sqrtTerm);
        
    //     saleAmt = (sqrtTerm - (twoMinusFee * saleReserve)) / (2 * oneMinusFee);
    //     // console.log("Final saleAmt:", saleAmt);
    //     // console.log("=== _swapDepositSaleAmt END ===");
        
    //     return saleAmt;
    // }
function _swapDepositSaleAmt(
    uint256 amountIn,
    uint256 saleReserve,
    uint256 feePercent
) internal pure returns(uint256 saleAmt) {
    uint256 twoMinusFee = 2 * FEE_DENOMINATOR - feePercent;
    uint256 oneMinusFee = FEE_DENOMINATOR - feePercent;
    uint256 term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve;
    uint256 term2 = 4 * oneMinusFee * FEE_DENOMINATOR * amountIn * saleReserve;
    uint256 sqrtTerm = BetterMath._sqrt(term1 + term2);
    if (sqrtTerm <= twoMinusFee * saleReserve) {
        return amountIn / 2; // Fallback to half for small deposits
    }
    saleAmt = (sqrtTerm - (twoMinusFee * saleReserve)) / (2 * oneMinusFee);
    return saleAmt > amountIn ? amountIn : saleAmt; // Cap at amountIn
}

    /* ---------------------------------------------------------------------- */
    /*                          SWAP/DEPOSIT (ZapIn)                          */
    /* ---------------------------------------------------------------------- */

    // function _swapDepositQuote(
    //     uint256 lpTotalSupply,
    //     uint256 amountIn,
    //     uint256 reserveIn,
    //     uint256 reserveOut,
    //     uint256 feePercent
    // ) internal pure returns(uint256 lpAmt) {
    //     // console.log("=== _swapDepositQuote DETAILED TRACE ===");
    //     // console.log("Input params - lpTotalSupply:", lpTotalSupply);
    //     // console.log("Input params - amountIn:", amountIn);
    //     // console.log("Input params - reserveIn:", reserveIn);
    //     // console.log("Input params - reserveOut:", reserveOut);
    //     // console.log("Input params - feePercent:", feePercent);
        
    //     // Step 1: Calculate sale amount
    //     uint256 amtInSaleAmt = amountIn
    //     ._swapDepositSaleAmt(
    //         reserveIn,
    //         feePercent
    //     );
    //     // console.log("Step 1: Sale amount calculated:", amtInSaleAmt);
        
    //     // Step 2: Calculate opposing token amount from swap
    //     uint256 opTokenAmtIn = amtInSaleAmt
    //     ._saleQuote(
    //         // uint256 amountIn,
    //         reserveIn,
    //         reserveOut,
    //         feePercent
    //     );
    //     // console.log("Step 2: Opposing token amount from swap:", opTokenAmtIn);
        
    //     // Step 3: Calculate remaining amount after sale
    //     uint256 amountRemaining = amountIn - amtInSaleAmt;
    //     // console.log("Step 3: Remaining amount after sale:", amountRemaining);
        
    //     // Step 4: Calculate updated reserves after swap
    //     uint256 newReserveIn = reserveIn + amtInSaleAmt;
    //     uint256 newReserveOut = reserveOut - opTokenAmtIn;
    //     // console.log("Step 4: New reserve in after swap:", newReserveIn);
    //     // console.log("Step 4: New reserve out after swap:", newReserveOut);
        
    //     // Step 5: Calculate LP amount from deposit
    //     lpAmt = amountRemaining
    //     ._depositQuote(
    //         // uint256 amountADeposit,
    //         // uint256 amountBDeposit,
    //         opTokenAmtIn,
    //         lpTotalSupply,
    //         // uint256 lpReserveA,
    //         newReserveIn,
    //         // uint256 lpReserveB
    //         newReserveOut
    //     );
    //     // console.log("Step 5: Final LP amount from deposit:", lpAmt);
    //     // console.log("=== _swapDepositQuote END ===");
        
    //     return lpAmt;
    // }
function _swapDepositQuote(
    uint256 lpTotalSupply,
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 feePercent
) internal pure returns(uint256 lpAmt) {
    uint256 amtInSaleAmt = amountIn._swapDepositSaleAmt(reserveIn, feePercent);
    uint256 opTokenAmtIn = amtInSaleAmt._saleQuote(reserveIn, reserveOut, feePercent);
    uint256 amountRemaining = amountIn - amtInSaleAmt;
    lpAmt = amountRemaining._depositQuote(
        opTokenAmtIn,
        lpTotalSupply,
        reserveIn + amtInSaleAmt,
        reserveOut - opTokenAmtIn
    );
}


    /* ---------------------------------------------------------------------- */
    /*                              WITHDRAW/SWAP                             */
    /* ---------------------------------------------------------------------- */

    // /**
    //  * @dev Calculates the proceeds of a "ZapOut" from a liquidity pool.
    //  * @dev "ZapOut" being a common term for withdrawing liquidity, then selling one of the toknes into the same pool to settle with only the other token.
    //  * @param ownedLPAmount The amount of LP tokens owned.
    //  * @param lpTotalSupply The total supply of LP tokens.
    //  * @param exitTokenTotalReserve The total reserve of the exit token.
    //  * @param opposingTokenTotalReserve The total reserve of the opposing token.
    //  * @param opTokenFeePercent The swap fee in PPHK, i.e 0.5% == 500.
    //  * @return exitAmount The proceeds of the "ZapOut".
    //  */
    // function _withdrawSwapQuote(
    //     uint256 ownedLPAmount,
    //     uint256 lpTotalSupply,
    //     uint256 exitTokenTotalReserve,
    //     uint256 opposingTokenTotalReserve,
    //     uint256 opTokenFeePercent
    // ) internal pure returns(uint256 exitAmount) {
    //     (
    //         uint256 exitTokenOwnedReserve,
    //         uint256 opposingTokenOwnedReserve
    //     ) = ownedLPAmount._withdrawQuote(
    //         // uint256 ownedLPAmount,
    //         // uint256 lpTotalSupply,
    //         lpTotalSupply,
    //         // uint256 totalReserveA,
    //         exitTokenTotalReserve,
    //         // uint256 totalReserveB
    //         opposingTokenTotalReserve
    //     );
    //     exitAmount = opposingTokenOwnedReserve
    //     ._saleQuote(
    //         // uint256 amountIn,
    //         // uint256 reserveIn,
    //         opposingTokenTotalReserve - opposingTokenOwnedReserve,
    //         // uint256 reserveOut,
    //         exitTokenTotalReserve  - exitTokenOwnedReserve,
    //         // uint256 feePercent
    //         opTokenFeePercent
    //     );
    // }
function _withdrawSwapQuote(
    uint256 ownedLPAmount,
    uint256 lpTotalSupply,
    uint256 reserveA,
    uint256 reserveB,
    uint256 feePercent
) internal pure returns (uint256) {
    // Get direct amounts from LP withdrawal
    (uint256 amountA, uint256 amountB) = _withdrawQuote(
        ownedLPAmount,
        lpTotalSupply,
        reserveA,
        reserveB
    );
    // uint256 swapOut = amountB._saleQuote(reserveB, reserveA, feePercent);
    uint256 swapOut = amountB._saleQuote(reserveB - amountB, reserveA - amountA, feePercent);
    return amountA + swapOut;
}


    /* ---------------------------------------------------------------------- */
    /*                          SWAP/DEPOSIT WITH FEES                          */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Calculates the protocol fee amount based on the growth of K value.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param newK The new K value after the operation.
     * @param kLast The last stored K value before the operation.
     * @param ownerFeeShare The fee share percentage for the protocol owner (e.g., 30000 for 30%).
     * @return feeAmount The amount of LP tokens to be minted as a protocol fee.
     */
    function _calculateProtocolFee(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 kLast,
        uint256 ownerFeeShare
    ) internal pure returns (uint256 feeAmount) {
        // console.log("=== _calculateProtocolFee START ===");
        // console.log("Input params - lpTotalSupply:", lpTotalSupply);
        // console.log("Input params - newK:", newK);
        // console.log("Input params - kLast:", kLast);
        // console.log("Input params - ownerFeeShare:", ownerFeeShare);
        
        // If kLast is 0 or newK <= kLast, no fee is charged
        if (kLast == 0 || newK <= kLast) {
            // console.log("No fee - kLast is zero or K hasn't grown");
            // console.log("=== _calculateProtocolFee END ===");
            return 0;
        }
        
        uint256 rootK = BetterMath._sqrt(newK);
        uint256 rootKLast = BetterMath._sqrt(kLast);
        // console.log("Intermediate - rootK:", rootK);
        // console.log("Intermediate - rootKLast:", rootKLast);
        
        if (rootK <= rootKLast) {
            // console.log("No fee - rootK <= rootKLast");
            // console.log("=== _calculateProtocolFee END ===");
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
        // console.log("Intermediate - numerator:", numerator);
        
        uint256 denominator = rootK * d + rootKLast * 100;
        // console.log("Intermediate - denominator:", denominator);
        
        feeAmount = numerator / denominator;
        // console.log("Final feeAmount:", feeAmount);
        // console.log("=== _calculateProtocolFee END ===");
        
        return feeAmount;
    }

    /**
     * @dev Calculates the expected LP tokens from a swap deposit operation, accounting for protocol fees.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param amountIn The amount of token being deposited.
     * @param reserveIn The reserve of the input token.
     * @param reserveOut The reserve of the output token.
     * @param feePercent The swap fee percentage.
     * @param kLast The last stored K value before the operation.
     * @param ownerFeeShare The fee share percentage for the protocol owner (e.g., 30000 for 30%).
     * @param feeOn Whether protocol fees are enabled.
     * @return lpAmt The expected amount of LP tokens after accounting for protocol fees.
     */
    function _swapDepositQuoteWithFee(
        uint256 lpTotalSupply,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 lpAmt, uint256 protocolFee) {
        // First calculate the standard LP tokens
        uint256 amtInSaleAmt = amountIn._swapDepositSaleAmt(reserveIn, feePercent);
        
        uint256 opTokenAmtIn = amtInSaleAmt._saleQuote(reserveIn, reserveOut, feePercent);
        
        amountIn -= amtInSaleAmt;
        
        reserveIn += amtInSaleAmt;
        reserveOut -= opTokenAmtIn;

        // If protocol fees are enabled, calculate and account for them
        if (feeOn && kLast != 0) {
            // Calculate new K value
            uint256 newK = reserveIn * reserveOut;
            // Calculate protocol fee
            protocolFee = _calculateProtocolFee(
                lpTotalSupply, 
                newK, 
                kLast, 
                ownerFeeShare
            );
            lpTotalSupply += protocolFee;
        }
        
        // Calculate standard LP amount
        lpAmt = amountIn._depositQuote(
            opTokenAmtIn,
            lpTotalSupply,
            reserveIn,
            reserveOut
        );
        return (lpAmt, protocolFee);
    }

    /* ---------------------------------------------------------------------- */
    /*                              PROTOCOL FEES                             */
    /* ---------------------------------------------------------------------- */

    function _calculateProtocolFee(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        // uint256 currentK,
        uint256 lastK,
        uint256 vaultFee
    ) internal pure returns (uint256 feeAmount, uint256 newK) {
        newK = _k(uint(reserveA), uint(reserveB));
        uint rootK = BetterMath._sqrt(newK);
        uint rootKLast = BetterMath._sqrt(lastK);
        if (rootK > rootKLast) {
            // Commented out code kept as reference to original known good code.
            // Errors should start by validating this is a correct conversion to native operators.
            // uint d = (FEE_DENOMINATOR.mul(100) / ownerFeeShare).sub(100);
            uint d = ((FEE_DENOMINATOR * 100) / vaultFee) - 100;
            // uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
            uint numerator = ((totalSupply * (rootK - rootKLast)) * 100);
            // uint denominator = rootK.mul(d).add(rootKLast.mul(100));
            uint denominator = ((rootK * d) + (rootKLast * 100));
            uint liquidity = numerator / denominator;
            if (liquidity > 0) feeAmount = liquidity;
        }
        return (feeAmount, newK);
    }

    function _k(uint balanceA, uint balanceB) internal pure returns (uint) {
        return balanceA * balanceB;
    }


}