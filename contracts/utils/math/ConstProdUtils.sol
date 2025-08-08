// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "forge-std/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";
import {betterconsole as console} from "../vm/foundry/tools/betterconsole.sol";

import "../../constants/Constants.sol";
import {BetterMath} from "./BetterMath.sol";
import {BetterMath as Math} from "./BetterMath.sol";

library ConstProdUtils {

    using Math for uint256;
    using ConstProdUtils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10**3;

    // uint256 constant FEE_DENOMINATOR = 100_000;

    /* ---------------------------------------------------------------------- */
    /*                                Reserves                                */
    /* ---------------------------------------------------------------------- */

    function _sortReserves(
        address knownToken,
        address token0,
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns(
        uint256 knownReserve,
        uint256 unknownReserve
    ) {
        return knownToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function _sortReserves(
        address knownToken,
        address token0,
        uint256 reserve0,
        uint256 reserve0Fee,
        uint256 reserve1,
        uint256 reserve1Fee
    ) internal pure returns(
        uint256 knownReserve,
        uint256 knownReserveFee,
        uint256 unknownReserve,
        uint256 unknownReserveFee
    ) {
        return knownToken == token0
            ? (reserve0, reserve0Fee, reserve1, reserve1Fee)
            : (reserve1, reserve1Fee, reserve0, reserve0Fee);
    }
    
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
            
            uint256 sqrtProduct = BetterMath.sqrt(product);
            // console.log("First deposit - sqrt(product):", sqrtProduct);
            
            lpAmount = sqrtProduct - _MINIMUM_LIQUIDITY;
            // console.log("First deposit - lpAmount:", lpAmount);
        } else {
            // Normal deposit case
            uint256 amountA_ratio = (amountADeposit * lpTotalSupply) / lpReserveA;
            // console.log("Normal deposit - amountA_ratio:", amountA_ratio);
            
            uint256 amountB_ratio = (amountBDeposit * lpTotalSupply) / lpReserveB;
            // console.log("Normal deposit - amountB_ratio:", amountB_ratio);
            
            lpAmount = BetterMath.min(amountA_ratio, amountB_ratio);
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
        uint256 totalReserveA,
        uint256 totalReserveB,
        uint256 feePercent
    ) internal pure returns(uint256 ownedReserveA) {
        // console.log("=== _withdrawQuoteOneSide START ===");
        // console.log("Input - ownedLPAmount:", ownedLPAmount);
        // console.log("Input - lpTotalSupply:", lpTotalSupply);
        // console.log("Input - totalReserveA:", totalReserveA);
        // console.log("Input - totalReserveB:", totalReserveB);
        // console.log("Input - feePercent:", feePercent);

        // Step 1: Calculate proportional withdraw amounts for both tokens
        (uint256 amountA, uint256 amountB) = _withdrawQuote(
            ownedLPAmount,
            lpTotalSupply,
            totalReserveA,
            totalReserveB
        );
        
        // console.log("Step 1 - Withdraw amounts: amountA =", amountA, "amountB =", amountB);
        
        // Step 2: Calculate new reserves after withdrawal for swap calculation
        uint256 newReserveA = totalReserveA - amountA;
        uint256 newReserveB = totalReserveB - amountB;
        
        // console.log("Step 2 - New reserves after withdrawal: newReserveA =", newReserveA, "newReserveB =", newReserveB);
        
        // Step 3: Swap all of token B for more token A
        uint256 swapOut = amountB._saleQuote(newReserveB, newReserveA, feePercent);
        
        // console.log("Step 3 - Swap output (amountB swapped for A):", swapOut);
        
        // Step 4: Total token A received = direct amount + swap proceeds
        ownedReserveA = amountA + swapOut;
        
        // console.log("Step 4 - Total amount A (direct + swapped):", ownedReserveA);
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
    function _saleQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 saleFeePercent
    ) internal pure returns (uint) {
        // console.log("=== _saleQuote START ===");
        // console.log("Input - amountIn:", amountIn);
        // console.log("Input - reserveIn:", reserveIn);
        // console.log("Input - reserveOut:", reserveOut);
        // console.log("Input - saleFeePercent:", saleFeePercent);
        // console.log("Input - FEE_DENOMINATOR:", FEE_DENOMINATOR);

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - saleFeePercent) / FEE_DENOMINATOR;
        // console.log("Step 1 - Fee reduction factor:", FEE_DENOMINATOR - saleFeePercent);
        // console.log("Step 1 - amountInWithFee:", amountInWithFee);
        
        uint256 numerator = amountInWithFee * reserveOut;
        // console.log("Step 2 - numerator (amountInWithFee * reserveOut):", numerator);
        
        uint256 denominator = reserveIn + amountInWithFee;
        // console.log("Step 3 - denominator (reserveIn + amountInWithFee):", denominator);
        
        uint256 result = numerator / denominator;
        // console.log("Step 4 - final result (numerator / denominator):", result);
        // console.log("=== _saleQuote END ===");
        
        return result;
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
    ) internal pure returns (uint) {
        // console.log("=== _saleQuote START ===");
        // console.log("Input - amountIn:", amountIn);
        // console.log("Input - reserveIn:", reserveIn);
        // console.log("Input - reserveOut:", reserveOut);
        // console.log("Input - saleFeePercent:", saleFeePercent);
        // console.log("Input - FEE_DENOMINATOR:", FEE_DENOMINATOR);

        uint256 amountInWithFee = amountIn * (feeDenominator - saleFeePercent) / feeDenominator;
        // console.log("Step 1 - Fee reduction factor:", FEE_DENOMINATOR - saleFeePercent);
        // console.log("Step 1 - amountInWithFee:", amountInWithFee);
        
        uint256 numerator = amountInWithFee * reserveOut;
        // console.log("Step 2 - numerator (amountInWithFee * reserveOut):", numerator);
        
        uint256 denominator = reserveIn + amountInWithFee;
        // console.log("Step 3 - denominator (reserveIn + amountInWithFee):", denominator);
        
        uint256 result = numerator / denominator;
        // console.log("Step 4 - final result (numerator / denominator):", result);
        // console.log("=== _saleQuote END ===");
        
        return result;
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
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "Invalid output amount");
        require(reserveIn > 0 && reserveOut > amountOut, "Insufficient liquidity");
        uint256 numerator = (reserveIn * amountOut) * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - feePercent);
        amountIn = (numerator / denominator) + 1;
    }

    function _purchaseQuote(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "Invalid output amount");
        require(reserveIn > 0 && reserveOut > amountOut, "Insufficient liquidity");
        uint256 numerator = (reserveIn * amountOut) * feeDenominator;
        uint256 denominator = (reserveOut - amountOut) * (feeDenominator - feePercent);
        amountIn = (numerator / denominator) + 1;
    }


    function _swapDepositSaleAmt(
        uint256 amountIn,
        uint256 saleReserve,
        uint256 feePercent
    ) internal pure returns(uint256 saleAmt) {
        uint256 twoMinusFee = 2 * FEE_DENOMINATOR - feePercent;
        uint256 oneMinusFee = FEE_DENOMINATOR - feePercent;
        uint256 term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve;
        uint256 term2 = 4 * oneMinusFee * FEE_DENOMINATOR * amountIn * saleReserve;
        uint256 sqrtTerm = BetterMath.sqrt(term1 + term2);
        if (sqrtTerm <= twoMinusFee * saleReserve) {
            return amountIn / 2; // Fallback to half for small deposits
        }
        saleAmt = (sqrtTerm - (twoMinusFee * saleReserve)) / (2 * oneMinusFee);
        return saleAmt > amountIn ? amountIn : saleAmt; // Cap at amountIn
    }

    /* ---------------------------------------------------------------------- */
    /*                          SWAP/DEPOSIT (ZapIn)                          */
    /* ---------------------------------------------------------------------- */

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

    // /**
    //  * @dev Calculates the amount of input token needed to ZapIn and receive a specified amount of LP tokens.
    //  * @param lpAmountDesired The desired amount of LP tokens to receive.
    //  * @param lpTotalSupply The current total supply of LP tokens.
    //  * @param reserveIn The reserve of the input token.
    //  * @param reserveOut The reserve of the output token.
    //  * @param feePercent The swap fee percentage (e.g., 300 for 0.3%).
    //  * @return amountIn The amount of input token needed.
    //  */
    // function _swapDepositRequired(
    //     uint256 lpAmountDesired,
    //     uint256 lpTotalSupply,
    //     uint256 reserveIn,
    //     uint256 reserveOut,
    //     uint256 feePercent
    // ) internal pure returns (uint256 amountIn) {
    //     // Edge cases
    //     if (lpAmountDesired == 0 || lpTotalSupply == 0 || reserveIn == 0 || reserveOut == 0) {
    //         return 0;
    //     }

    //     // Use Newton-Raphson method to find the required input
    //     // Start with a reasonable initial guess based on pool ratio
    //     uint256 k = reserveIn * reserveOut;
    //     uint256 targetTotalSupply = lpTotalSupply + lpAmountDesired;
    //     uint256 targetK = (k * targetTotalSupply * targetTotalSupply) / (lpTotalSupply * lpTotalSupply);
    //     uint256 targetReserveIn = BetterMath.sqrt((targetK * reserveIn) / reserveOut);
        
    //     // Initial guess: proportional increase in reserve
    //     amountIn = targetReserveIn > reserveIn ? (targetReserveIn - reserveIn) * 11 / 10 : lpAmountDesired; // 10% buffer
        
    //     // Newton-Raphson iterations (usually converges in 3-4 iterations)
    //     for (uint256 i = 0; i < 5; i++) {
    //         uint256 currentLP = _swapDepositQuote(lpTotalSupply, amountIn, reserveIn, reserveOut, feePercent);
            
    //         if (currentLP == lpAmountDesired) {
    //             break; // Exact match found
    //         }
            
    //         // Calculate derivative approximation (delta method)
    //         uint256 delta = amountIn / 1000; // 0.1% delta
    //         if (delta == 0) delta = 1;
            
    //         uint256 lpAtDelta = _swapDepositQuote(lpTotalSupply, amountIn + delta, reserveIn, reserveOut, feePercent);
    //         uint256 derivative = (lpAtDelta > currentLP) ? (lpAtDelta - currentLP) * 1e18 / delta : 1e18;
            
    //         // Newton-Raphson update: x = x - f(x)/f'(x)
    //         if (currentLP > lpAmountDesired) {
    //             uint256 excess = currentLP - lpAmountDesired;
    //             uint256 adjustment = (excess * 1e18) / derivative;
    //             amountIn = amountIn > adjustment ? amountIn - adjustment : amountIn / 2;
    //         } else {
    //             uint256 deficit = lpAmountDesired - currentLP;
    //             uint256 adjustment = (deficit * 1e18) / derivative;
    //             amountIn += adjustment;
    //         }
    //     }
        
    //     return amountIn;
    // }

    /**
     * @dev Calculatess the amount token A needed to ZapIn to receive a desired amount of LP tokens.
     */
    function _calculateZapInAmount(
        uint256 desiredLP,
        uint256 totalLP,
        uint256 reserveA,
        uint256 feeNum,
        uint256 feeDenom
    ) internal pure returns (uint256) {
        uint256 lt_delta = totalLP * feeDenom;
        uint256 ltd_ld = totalLP - desiredLP;
        uint256 delta_phi = feeDenom - feeNum;
        uint256 inner = lt_delta + (ltd_ld * delta_phi);
        uint256 numerator = desiredLP * reserveA * inner;
        uint256 denominator = totalLP * ltd_ld * delta_phi;
        uint256 inputAmount = numerator / denominator;
        if (numerator % denominator != 0) {
            inputAmount += 1;
        }
        return inputAmount;
    }

    /**
     * @dev Calculates the amount of input token needed to ZapIn and receive a specified amount of LP tokens.
     * @param lpAmountDesired The desired amount of LP tokens to receive.
     * @param reserveIn The reserve of the input token (e.g., Token A).
     * @param reserveOut The reserve of the output token (e.g., Token B).
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param feePercent The swap fee percentage in PPHK (e.g., 500 for 0.5%).
     * @return amountInRequired The amount of input token needed to achieve the desired LP token amount.
     */
    function _swapDepositToTargetQuote(
        uint256 lpAmountDesired,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 lpTotalSupply,
        uint256 feePercent
    ) internal pure returns (uint256 amountInRequired) {
        require(lpAmountDesired > 0, "Invalid LP amount desired");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        require(lpTotalSupply > 0, "LP total supply must be greater than 0");

        // Step 1: Calculate the equivalent amounts of Token A and Token B needed for the desired LP amount
        uint256 amountAForLP = (lpAmountDesired * reserveIn) / lpTotalSupply;
        uint256 amountBForLP = (lpAmountDesired * reserveOut) / lpTotalSupply;

        // console.log("Step 1 - amountAForLP:", amountAForLP);
        // console.log("Step 1 - amountBForLP:", amountBForLP);

        // Step 2: Determine the required input amount of Token A to swap for amountBForLP
        // This is the reverse of a sale quote, calculating how much Token A is needed to buy amountBForLP
        uint256 amountInForSwap = _purchaseQuote(
            amountBForLP,
            reserveIn,
            reserveOut,
            feePercent
        );

        // console.log("Step 2 - amountInForSwap:", amountInForSwap);

        // Step 3: The total amountInRequired is the sum of the amount swapped and the amount deposited
        // In a typical ZapIn, the user provides Token A, which is partially swapped for Token B, and both are deposited
        amountInRequired = amountInForSwap + amountAForLP;

        // console.log("Step 3 - amountInRequired:", amountInRequired);

        // Ensure the calculation is reasonable
        require(amountInRequired > 0, "Invalid amount required");
        return amountInRequired;
    }

    function _calculateZapInInput(
        uint256 lpTokensDesired,
        uint256 reserveIn,
        uint256 reserveOut, 
        uint256 poolTotalSupply,
        uint256 feePercent
    ) internal pure returns (uint256 amountIn) {
        // Direct calculation for zap-in amount
        // Formula derived from UniswapV2 swap + addLiquidity math
        
        uint256 fee = 10000 - feePercent; // e.g., 9700 for 3% fee
        
        // Calculate the target reserves after adding liquidity
        uint256 targetTotalSupply = poolTotalSupply + lpTokensDesired;
        uint256 ratio = (targetTotalSupply * 1e18) / poolTotalSupply;
        
        uint256 targetReserveIn = (reserveIn * ratio) / 1e18;
        uint256 deltaReserveIn = targetReserveIn - reserveIn;
        
        // Account for the swap fee and slippage
        // Solve the quadratic equation directly
        uint256 b = (reserveIn * fee * 2) + (deltaReserveIn * 10000);
        uint256 c = deltaReserveIn * reserveIn * fee;
        
        // Use quadratic formula: (-b + sqrt(b² + 4c)) / 2
        uint256 discriminant = b * b + 4 * c;
        amountIn = (BetterMath.sqrt(discriminant) - b) / 2;
        
        return amountIn;
    }

    /* ---------------------------------------------------------------------- */
    /*                              WITHDRAW/SWAP                             */
    /* ---------------------------------------------------------------------- */

    function _withdrawSwapQuote(
        uint256 ownedLPAmount,
        uint256 lpTotalSupply,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feePercent
    ) internal pure returns (uint256) {
        // console.log("=== _withdrawSwapQuote START ===");
        // console.log("Input - ownedLPAmount:", ownedLPAmount);
        // console.log("Input - lpTotalSupply:", lpTotalSupply);
        // console.log("Input - reserveA:", reserveA);
        // console.log("Input - reserveB:", reserveB);
        // console.log("Input - feePercent:", feePercent);

        // Get direct amounts from LP withdrawal
        (uint256 amountA, uint256 amountB) = _withdrawQuote(
            ownedLPAmount,
            lpTotalSupply,
            reserveA,
            reserveB
        );
        
        // console.log("Step 1 - Withdraw amounts: amountA =", amountA, "amountB =", amountB);
        
        // Calculate new reserves after withdrawal for swap calculation
        uint256 newReserveB = reserveB - amountB;
        uint256 newReserveA = reserveA - amountA;
        
        // console.log("Step 2 - New reserves after withdrawal: newReserveA =", newReserveA, "newReserveB =", newReserveB);
        
        // uint256 swapOut = amountB._saleQuote(reserveB, reserveA, feePercent);
        uint256 swapOut = amountB._saleQuote(newReserveB, newReserveA, feePercent);
        
        // console.log("Step 3 - Swap output (amountB swapped for A):", swapOut);
        
        uint256 totalAmountA = amountA + swapOut;
        // console.log("Step 4 - Total amount A (direct + swapped):", totalAmountA);
        // console.log("=== _withdrawSwapQuote END ===");
        
        return totalAmountA;
    }
/**
     * @dev Calculates the amount of LP tokens needed to zap out and receive a desired amount of the output token.
     * @param desiredOut The desired amount of output token (token A).
     * @param reserveA Reserve of the output token.
     * @param reserveB Reserve of the paired token.
     * @param lpTotalSupply Current total supply of LP tokens.
     * @param feePercent Swap fee in PPHK (e.g., 300 for 0.3% with FEE_DENOMINATOR = 100000).
     * @param feeDenominator Fee denominator (e.g., 100000).
     * @return lpNeeded Amount of LP tokens required.
     */
    function _calculateZapOutLP(
        uint256 desiredOut,
        uint256 reserveA,
        uint256 reserveB,
        uint256 lpTotalSupply,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal pure returns (uint256 lpNeeded) {
        // Edge cases
        if (desiredOut == 0 || lpTotalSupply == 0 || reserveA == 0 || reserveB == 0) {
            return 0;
        }
        if (desiredOut > reserveA) {
            return 0; // Cannot withdraw more than available
        }
        require(feePercent < feeDenominator, "Invalid fee");

        // g = (FEE_DENOMINATOR - feePercent) / FEE_DENOMINATOR
        uint256 gNumerator = feeDenominator - feePercent;
        // Quadratic coefficients
        uint256 a = reserveA * gNumerator; // R_a * (FEE_DENOM - feePercent)
        uint256 b = reserveA * (feeDenominator + gNumerator) - desiredOut * gNumerator;
        uint256 c = desiredOut * feeDenominator; // -D * FEE_DENOM (sign handled in discriminant)
        // Discriminant: b^2 + 4ac (since c is negative, adjust sign)
        uint256 discriminant = b * b + 4 * a * c;
        uint256 sqrtDisc = BetterMath.sqrt(discriminant);
        // r = (-b + sqrt(d)) / (2a), scaled to avoid early division
        uint256 numerator = (sqrtDisc - b) * lpTotalSupply;
        uint256 denominator = 2 * a;
        lpNeeded = numerator / denominator;
        // Ceiling for safety
        if (numerator % denominator != 0) {
            lpNeeded += 1;
        }
        return lpNeeded;
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
     * @return lpOfYield The amount of LP tokens to be minted as a protocol fee.
     */
    function _calculateProtocolFee(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 kLast,
        uint256 ownerFeeShare
    ) internal pure returns (uint256 lpOfYield) {
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
        
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(kLast);
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
        
        lpOfYield = numerator / denominator;
        // console.log("Final lpOfYield:", lpOfYield);
        // console.log("=== _calculateProtocolFee END ===");
        
        return lpOfYield;
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
    ) internal pure returns (uint256 lpOfYield, uint256 newK) {
        newK = _k(uint(reserveA), uint(reserveB));
        uint rootK = BetterMath.sqrt(newK);
        uint rootKLast = BetterMath.sqrt(lastK);
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
            if (liquidity > 0) lpOfYield = liquidity;
        }
        return (lpOfYield, newK);
    }

    function _k(uint balanceA, uint balanceB) internal pure returns (uint) {
        return balanceA * balanceB;
    }

    /**
     * @dev Calculates LP tokens to mint as vault fees based on market maker fee accrual.
     * @param reserveA Current reserve of token A.
     * @param reserveB Current reserve of token B.
     * @param totalSupply Current total supply of LP tokens.
     * @param lastK Last stored K value (reserveA_last * reserveB_last).
     * @param vaultFee Vault's fee share (e.g., 30000 for 30%, denominator 1e6).
     * @return feeAmount LP tokens to mint as vault fees.
     * @return newK Current K value for state updates.
     */
    function _calculateVaultFee(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 vaultFee,
        uint256 feeDenominator
    ) internal pure returns (uint256 feeAmount, uint256 newK) {
        // Calculate current K
        newK = reserveA * reserveB;

        // No fees if no liquidity or K hasn't grown
        if (lastK == 0 || newK <= lastK || totalSupply == 0 || vaultFee == 0) {
            return (0, newK);
        }

        // Calculate fee based on growth in sqrt(K)
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(lastK);

        if (rootK <= rootKLast) {
            return (0, newK);
        }

        // Calculate LP tokens to mint (Uniswap V2 formula)
        // uint256 FEE_DENOMINATOR = 1e6; // Matches vaultFee denominator
        uint256 d = (feeDenominator * 100 / vaultFee) - 100;
        uint256 numerator = totalSupply * (rootK - rootKLast) * 100;
        uint256 denominator = rootK * d + rootKLast * 100;

        feeAmount = numerator / denominator;

        return (feeAmount, newK);
    }

    function _calculateLpOfYiedAndNewK(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 vaultFee,
        uint256 feeDenominator
    ) internal pure returns (uint256 lpOfYield, uint256 newK) {
        // Calculate current K
        newK = reserveA * reserveB;

        // No fees if no liquidity or K hasn't grown
        if (lastK == 0 || newK <= lastK || totalSupply == 0 || vaultFee == 0) {
            return (0, newK);
        }

        // Calculate fee based on growth in sqrt(K)
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(lastK);

        if (rootK <= rootKLast) {
            return (0, newK);
        }

        // Calculate LP tokens to mint (Uniswap V2 formula)
        // uint256 FEE_DENOMINATOR = 1e6; // Matches vaultFee denominator
        uint256 d = (feeDenominator * 100 / vaultFee) - 100;
        uint256 numerator = totalSupply * (rootK - rootKLast) * 100;
        uint256 denominator = rootK * d + rootKLast * 100;

        lpOfYield = numerator / denominator;

        return (lpOfYield, newK);
    }

    function _calculateVaultFeeNoNewK(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 vaultFee,
        uint256 feeDenominator
    ) internal pure returns (uint256 lpOfYield) {
        // Calculate current K
        uint256 newK = reserveA * reserveB;

        // No fees if no liquidity or K hasn't grown
        if (lastK == 0 || newK <= lastK || totalSupply == 0 || vaultFee == 0) {
            return (0);
        }

        // Calculate fee based on growth in sqrt(K)
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(lastK);

        if (rootK <= rootKLast) {
            return (0);
        }

        // Calculate LP tokens to mint (Uniswap V2 formula)
        // uint256 FEE_DENOMINATOR = 1e6; // Matches vaultFee denominator
        uint256 d = (feeDenominator * 100 / vaultFee) - 100;
        uint256 numerator = totalSupply * (rootK - rootKLast) * 100;
        uint256 denominator = rootK * d + rootKLast * 100;

        lpOfYield = numerator / denominator;

        return lpOfYield;
    }

    /**
     * @dev Calculates LP tokens to mint as vault fees based on market maker fee accrual.
     * @param reserveA Current reserve of token A.
     * @param reserveB Current reserve of token B.
     * @param totalSupply Current total supply of LP tokens.
     * @param lastK Last stored K value (reserveA_last * reserveB_last).
     * @param vaultFee Vault's fee share (e.g., 30000 for 30%, denominator 1e6).
     * @return lpOfYield LP tokens to mint as vault fees.
     */
    function _calculateLPOfYield(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 vaultFee,
        uint256 feeDenominator
    ) internal pure returns (uint256 lpOfYield) {
        // Calculate current K
        uint256 newK = reserveA * reserveB;

        // No fees if no liquidity or K hasn't grown
        if (lastK == 0 || newK <= lastK || totalSupply == 0 || vaultFee == 0) {
            return (0);
        }

        // Calculate fee based on growth in sqrt(K)
        uint256 rootK = BetterMath.sqrt(newK);
        uint256 rootKLast = BetterMath.sqrt(lastK);

        if (rootK <= rootKLast) {
            return (0);
        }

        // Calculate LP tokens to mint (Uniswap V2 formula)
        // uint256 FEE_DENOMINATOR = 1e6; // Matches vaultFee denominator
        uint256 d = (feeDenominator * 100 / vaultFee) - 100;
        uint256 numerator = totalSupply * (rootK - rootKLast) * 100;
        uint256 denominator = rootK * d + rootKLast * 100;

        lpOfYield = numerator / denominator;

        return lpOfYield;
    }

    function _calculateYieldForOwnedLP(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 ownedLP
    ) internal pure returns (uint256 lpOfYield, uint256 newK) {
        // Calculate current K
        newK = _k(reserveA, reserveB);
        return (
            _calculateYieldForOwnedLP(
                reserveA,
                reserveB,
                totalSupply,
                lastK,
                newK,
                ownedLP
            ),
            newK
        );
    }
    
    /**
     * @dev Calculates the equivalent LP tokens representing the yield for owned LP tokens.
     * @param reserveA Current reserve of token A.
     * @param reserveB Current reserve of token B.
     * @param totalSupply Current total supply of LP tokens.
     * @param lastK Last stored K value (reserveA_last * reserveB_last).
     * @param ownedLP Amount of LP tokens owned by the holder.
     * @return lpOfYield LP tokens representing the yield for ownedLP.
     */
    function _calculateYieldForOwnedLP(
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalSupply,
        uint256 lastK,
        uint256 newK,
        uint256 ownedLP
    ) internal pure returns (uint256 lpOfYield) {
        // No yield if no liquidity, no owned LP, or no growth
        if (totalSupply == 0 || ownedLP == 0 || newK <= lastK) {
            return (0);
        }
        // Calculate sqrt(K) and sqrt(K_last)
        uint256 rootK = newK.sqrt();
        uint256 rootKLast = lastK.sqrt();
        if (rootK <= rootKLast) {
            return (0);
        }
        // Calculate yield in LP tokens: ownedLP * (sqrt(K) - sqrt(K_last)) / sqrt(K_last)
        uint256 numerator = ownedLP * (rootK - rootKLast);
        uint256 denominator = rootKLast;
        lpOfYield = numerator / denominator;
        // Handle remainder to avoid truncation
        if (numerator % denominator != 0) {
            lpOfYield += 1;
        }
        return (lpOfYield);
    }
    
}