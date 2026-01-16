// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/contracts/constants/Constants.sol";
import "@crane/contracts/GeneralErrors.sol";
import {Uint512, BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";
import {Math as UniV2Math} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol";
import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol";

library ConstProdUtils {
    using Math for uint256;
    using Math for Uint512;
    using ConstProdUtils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10 ** 3;

    /* -------------------------------------------------------------------------- */
    /*                                  Reserves                                  */
    /* -------------------------------------------------------------------------- */

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

    /**
     * @dev Sorts reserves and fees based on the known token and token0.
     * @param knownToken The token that is known.
     * @param token0 The token that is token0.
     * @param reserve0 The reserve of the known token.
     * @param reserve0Fee The fee of the known token.
     * @param reserve1 The reserve of the unknown token.
     * @param reserve1Fee The fee of the unknown token.
     * @return knownReserve The reserve of the known token.
     * @return knownReserveFee The fee of the known token.
     * @return unknownReserve The reserve of the unknown token.
     * @return unknownReserveFee The fee of the unknown token.
     */
    function _sortReserves(
        address knownToken,
        address token0,
        uint256 reserve0,
        uint256 reserve0Fee,
        uint256 reserve1,
        uint256 reserve1Fee
    )
        internal
        pure
        returns (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee)
    {
        return knownToken == token0
            ? (reserve0, reserve0Fee, reserve1, reserve1Fee)
            : (reserve1, reserve1Fee, reserve0, reserve0Fee);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Deposit                                  */
    /* -------------------------------------------------------------------------- */

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

            uint256 sqrtProduct = Math._sqrt(product);

            lpAmount = sqrtProduct - _MINIMUM_LIQUIDITY;
        } else {
            // Normal deposit case
            /// forge-lint: disable-next-line(mixed-case-variable)
            uint256 amountA_ratio = (amountADeposit * lpTotalSupply) / lpReserveA;

            /// forge-lint: disable-next-line(mixed-case-variable)
            uint256 amountB_ratio = (amountBDeposit * lpTotalSupply) / lpReserveB;

            lpAmount = Math._min(amountA_ratio, amountB_ratio);
        }
        return lpAmount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Withdrawal                                 */
    /* -------------------------------------------------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                    Swaps                                   */
    /* -------------------------------------------------------------------------- */

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
        uint256 amountInWithFee = amountIn * (feeDenominator - saleFeePercent);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * feeDenominator) + amountInWithFee;
        return numerator / denominator;
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
        // Ensure the effective fee multiplier is non-zero.
        // feeDenominator is arg #4, feePercent is arg #3
        if (feeDenominator <= feePercent) revert ArgumentMustBeGreaterThan(4, 3);

        // Standard Uniswap V2-style exact-out inversion:
        // amountIn = floor(reserveIn * amountOut * feeDen / ((reserveOut - amountOut) * (feeDen - fee))) + 1
        // The +1 makes the result safe under integer division rounding.
        uint256 numerator = (reserveIn * amountOut) * feeDenominator;
        uint256 denominator = (reserveOut - amountOut) * (feeDenominator - feePercent);
        amountIn = (numerator / denominator) + 1;
    }

    /* -------------------------------------------------------------------------- */
    /*                            Swap/Deposit (ZapIn)                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Calculates the expected LP tokens from a swap deposit operation, accounting for protocol fees.
     *
     * @notice This function uses a heuristic to infer the fee denominator from the fee percent value.
     * The heuristic assumes:
     * - feePercent <= 10: Legacy pool (denominator = 1000, e.g., 3/1000 = 0.3%)
     * - feePercent > 10: Modern pool (denominator = 100,000, e.g., 300/100000 = 0.3%)
     *
     * @custom:edge-case This heuristic can misclassify low modern fees. For example, a modern
     * pool with 0.01% fee uses feePercent=10 with denominator=100,000 (10/100000), but the
     * heuristic would incorrectly treat it as a legacy 1% fee (10/1000). If you know the exact
     * fee denominator, use the overload that accepts explicit `feeDenominator` parameter.
     *
     * @param amountIn The amount of token being deposited.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param reserveIn The reserve of the input token.
     * @param reserveOut The reserve of the output token.
     * @param feePercent The swap fee percentage.
     * @param kLast The last stored K value before the operation.
     * @param ownerFeeShare The fee share percentage for the protocol owner (e.g., 30000 for 30%).
     * @param feeOn Whether protocol fees are enabled.
     * @return lpAmt The expected amount of LP tokens after accounting for protocol fees.
     */
    function _quoteSwapDepositWithFee(
        uint256 amountIn,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 lpAmt) {
        SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = lpTotalSupply;
        args.reserveIn = reserveIn;
        args.reserveOut = reserveOut;
        args.feePercent = feePercent;
        // Heuristic: infer denominator from fee magnitude
        // See @custom:edge-case in NatSpec above for limitations
        args.feeDenominator = (feePercent <= 10) ? 1000 : FEE_DENOMINATOR;
        args.kLast = kLast;
        args.ownerFeeShare = ownerFeeShare;
        args.feeOn = feeOn;
        return _quoteSwapDepositWithFee(args);
    }

    /**
     * @dev Calculates the expected LP tokens from a swap deposit operation with explicit fee denominator.
     *
     * @notice This overload allows specifying the exact fee denominator, avoiding the heuristic
     * that can misclassify low modern fees (e.g., 10/100000 = 0.01%) as legacy fees (10/1000 = 1%).
     *
     * @param amountIn The amount of token being deposited.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param reserveIn The reserve of the input token.
     * @param reserveOut The reserve of the output token.
     * @param feePercent The swap fee percentage (numerator).
     * @param feeDenominator The fee denominator (e.g., 1000 for legacy, 100000 for modern pools).
     * @param kLast The last stored K value before the operation.
     * @param ownerFeeShare The fee share percentage for the protocol owner (e.g., 30000 for 30%).
     * @param feeOn Whether protocol fees are enabled.
     * @return lpAmt The expected amount of LP tokens after accounting for protocol fees.
     */
    function _quoteSwapDepositWithFee(
        uint256 amountIn,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 lpAmt) {
        SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = lpTotalSupply;
        args.reserveIn = reserveIn;
        args.reserveOut = reserveOut;
        args.feePercent = feePercent;
        args.feeDenominator = feeDenominator;
        args.kLast = kLast;
        args.ownerFeeShare = ownerFeeShare;
        args.feeOn = feeOn;
        return _quoteSwapDepositWithFee(args);
    }

    struct SwapDepositArgs {
        uint256 amountIn;
        uint256 lpTotalSupply;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 feeDenominator;
        uint256 kLast;
        uint256 ownerFeeShare;
        bool feeOn;
    }

    /**
     * @dev Internal implementation using SwapDepositArgs struct.
     * @notice The feeDenominator field in args determines how feePercent is interpreted.
     * Callers should set args.feeDenominator explicitly, or use the convenience overloads.
     */
    function _quoteSwapDepositWithFee(SwapDepositArgs memory args) internal pure returns (uint256 lpAmt) {
        // Use explicit denominator from args (set by caller or heuristic in overload)
        uint256 feeDenom = args.feeDenominator;
        uint256 amtInSaleAmt = _swapDepositSaleAmt(args.amountIn, args.reserveIn, args.feePercent, feeDenom);
        uint256 opTokenAmtIn = _saleQuote(amtInSaleAmt, args.reserveIn, args.reserveOut, args.feePercent, feeDenom);
        args.amountIn -= amtInSaleAmt;

        // Swap reserves reflect the full sold amount; fee is reflected in output math/invariant
        args.reserveIn += amtInSaleAmt;
        args.reserveOut -= opTokenAmtIn;
        uint256 protocolFee;
        // If protocol fees are enabled, calculate and account for them
        if (args.feeOn && args.kLast != 0) {
            // Calculate new K and mint protocol fee based on ownerFeeShare policy
            uint256 newK = args.reserveIn * args.reserveOut;
            protocolFee = _calculateProtocolFee(args.lpTotalSupply, newK, args.kLast, args.ownerFeeShare);
            args.lpTotalSupply += protocolFee;
        }
        uint256 amountADesired = args.amountIn;
        uint256 amountBDesired = opTokenAmtIn;
        uint256 amountA;
        uint256 amountB;

        // Defensive: reserves must be non-zero (they were updated above)
        if (args.reserveIn == 0 || args.reserveOut == 0) {
            return 0;
        }

        uint256 amountBOptimal = (amountADesired * args.reserveOut) / args.reserveIn;
        if (amountBOptimal <= amountBDesired) {
            amountA = amountADesired;
            amountB = amountBOptimal;
        } else {
            uint256 amountAOptimal = (amountBDesired * args.reserveIn) / args.reserveOut;
            amountA = amountAOptimal;
            amountB = amountBDesired;
        }

        // Calculate standard LP amount using selected integer pair
        lpAmt = _depositQuote(amountA, amountB, args.lpTotalSupply, args.reserveIn, args.reserveOut);
        return (lpAmt);
    }

    function _swapDepositSaleAmt(uint256 amountIn, uint256 saleReserve, uint256 feePercent)
        internal
        pure
        returns (uint256 saleAmt)
    {
        return _swapDepositSaleAmt(
            // uint256 amountIn,
            amountIn,
            // uint256 saleReserve,
            saleReserve,
            // uint256 feePercent,
            feePercent,
            // uint256 feeDenominator
            FEE_DENOMINATOR
        );
    }

    function _swapDepositSaleAmt(uint256 amountIn, uint256 saleReserve, uint256 feePercent, uint256 feeDenominator)
        internal
        pure
        returns (uint256 saleAmt)
    {
        uint256 oneMinusFee = feeDenominator - feePercent; // fee factor (e.g., 997/1000 style)
        uint256 twoMinusFee = (2 * feeDenominator) - feePercent; // corresponds to (2 - f) scaled by D
        uint256 term1 = twoMinusFee * twoMinusFee * saleReserve * saleReserve;
        uint256 term2 = 4 * oneMinusFee * feeDenominator * amountIn * saleReserve;
        uint256 sqrtTerm = Math._sqrt(term1 + term2);
        if (sqrtTerm <= twoMinusFee * saleReserve) {
            return amountIn / 2; // Fallback for small deposits
        }
        saleAmt = (sqrtTerm - (twoMinusFee * saleReserve)) / (2 * oneMinusFee);
        if (saleAmt > amountIn) {
            saleAmt = amountIn; // Cap at amountIn
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  WITHDRAW                                  */
    /* -------------------------------------------------------------------------- */

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
        return _withdrawQuote(ownedLPAmount, lpTotalSupply, totalReserveA, totalReserveB);
    }

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
        // Defensive: avoid division by zero if supply is zero or nothing owned
        if (lpTotalSupply == 0 || ownedLPAmount == 0) {
            return (0, 0);
        }

        // using balances ensures pro-rata distribution
        ownedReserveA = ((ownedLPAmount * totalReserveA) / lpTotalSupply);
        ownedReserveB = ((ownedLPAmount * totalReserveB) / lpTotalSupply);
    }

    /* -------------------------------------------------------------------------- */
    /*                           ZapOut to Target Quote                           */
    /* -------------------------------------------------------------------------- */

    struct ZapOutToTargetWithFeeArgs {
        uint256 desiredOut;
        uint256 lpTotalSupply;
        uint256 reserveDesired; // Reserve of the desired output token
        uint256 reserveOther; // Reserve of the token to be swapped
        uint256 feePercent;
        uint256 feeDenominator;
        uint256 kLast;
        uint256 ownerFeeShare;
        bool feeOn;
        uint256 protocolFeeDenominator; // Denominator for protocol fee share
    }

    /**
     * @dev Quotes the amount of LP tokens needed for a ZapOut to receive at least a desired amount of output token in a Uniswap V2-like pool.
     * @dev Accounts for swap fees and protocol fee mints that dilute lpTotalSupply.
     * @dev Overestimates lpNeeded by applying a bounded buffer on desiredOut to ensure >= desiredOut.
     * @param desiredOut Desired amount of output token.
     * @param lpTotalSupply Current LP total supply (includes past protocol fee mints).
     * @param reserveDesired Reserve of the output token.
     * @param reserveOther Reserve of the token to be swapped to the output token.
     * @param feePercent Swap fee (e.g., 3000 for 0.3% with feeDenominator=100000).
     * @param feeDenominator Fee denominator (e.g., 100000).
     * @param kLast Last K value before the operation.
     * @param ownerFeeShare Protocol fee share (e.g., 16667 for 1/6).
     * @param feeOn Whether protocol fees are enabled.
     * bufferPct Buffer percentage in basis points (e.g., 10 for 0.1%).
     * @return lpNeeded Amount of LP tokens to burn (overestimated).
     */
    function _quoteZapOutToTargetWithFee(
        uint256 desiredOut,
        uint256 lpTotalSupply,
        uint256 reserveDesired,
        uint256 reserveOther,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    )
        // uint256 bufferPct
        internal
        pure
        returns (uint256 lpNeeded)
    {
        // 10 Is too low
        // uint256 bufferPct = 100;
        ZapOutToTargetWithFeeArgs memory args = ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: lpTotalSupply,
            reserveDesired: reserveDesired,
            reserveOther: reserveOther,
            feePercent: feePercent,
            feeDenominator: feeDenominator,
            kLast: kLast,
            ownerFeeShare: ownerFeeShare,
            feeOn: feeOn,
            protocolFeeDenominator: 100000
        });
        return _quoteZapOutToTargetWithFee(args);
    }

    /**
     * @dev Quotes the amount of LP tokens needed for a ZapOut to receive at least a desired amount of output token.
     * @dev Uses quadratic initial guess + binary search for minimal LP ensuring >= desiredOut precisely and efficiently.
     * @param args The input arguments.
     * @return lpNeeded Amount of LP tokens to burn (minimal exact for precision).
     */
    function _quoteZapOutToTargetWithFee(ZapOutToTargetWithFeeArgs memory args)
        internal
        pure
        returns (uint256 lpNeeded)
    {
        if (
            args.desiredOut == 0 || args.lpTotalSupply == 0 || args.reserveDesired == 0 || args.reserveOther == 0
                || args.feePercent >= args.feeDenominator || args.ownerFeeShare > args.protocolFeeDenominator
                || args.protocolFeeDenominator == 0
        ) {
            return 0;
        }
        if (args.desiredOut > args.reserveDesired) {
            return 0;
        }
        // Adjust lpTotalSupply for protocol fee
        // uint256 lpTotalSupply = args.lpTotalSupply;
        // Guard: if ownerFeeShare == 0, treat as "fees disabled" to avoid division-by-zero
        // (consistent with _calculateProtocolFee behavior)
        if (args.feeOn && args.kLast != 0 && args.ownerFeeShare != 0) {
            uint256 rootK = Math._sqrt(args.reserveDesired * args.reserveOther);
            uint256 rootKLast = Math._sqrt(args.kLast);
            if (rootK > rootKLast) {
                uint256 feeFactor = (args.protocolFeeDenominator / args.ownerFeeShare) - 1;
                uint256 numerator = args.lpTotalSupply * (rootK - rootKLast);
                uint256 denominator = (rootK * feeFactor) + rootKLast;
                if (denominator == 0) return 0;
                uint256 protocolFee = numerator / denominator;
                args.lpTotalSupply += protocolFee;
            }
        }
        // Quadratic initial guess (exact in float, floored in int)
        // uint256 T = args.desiredOut;
        // uint256 S = args.lpTotalSupply;
        uint256 D = args.feeDenominator;
        uint256 gamma = D - args.feePercent;
        uint256 quadraticGuess = 0;
        // Compute b
        uint256 b;
        {
            uint256 b1 = (args.desiredOut * args.reserveOther) * D;
            uint256 b2 = (args.desiredOut * gamma) * args.reserveOther;
            uint256 b3 = (args.reserveOther * args.reserveDesired) * D;
            uint256 b4 = args.reserveOther * args.reserveDesired * gamma;
            uint256 bNum = b1 - b2 + b3 + b4;
            uint256 bDen = args.lpTotalSupply * D;
            // uint256
            b = bNum / bDen;
        }
        {
            // a1, a2, c
            uint256 a1 = (args.reserveOther * args.reserveDesired) / args.lpTotalSupply;
            uint256 a2 = args.lpTotalSupply;
            uint256 c = args.desiredOut * args.reserveOther;
            // Discriminant
            uint256 bb = b * b;
            Uint512 memory fourAC = Math._mul512ForUint512(a1, 4 * c);
            uint256 fourACDivA2 = Math._div512(fourAC, a2);
            if (bb < fourACDivA2) return 0; // Invalid; full search fallback
            uint256 disc = bb - fourACDivA2;
            uint256 sqrtDisc = Math._sqrt(disc);
            // LP from quadratic
            uint256 num = (b * a2) - (a2 * sqrtDisc);
            uint256 den = 2 * a1;
            quadraticGuess = num / den;
            if (num % den != 0) {
                quadraticGuess += 1;
            }
        }
        // Simulate quadratic output to tighten bounds
        uint256 quadOutput = _computeZapOut(quadraticGuess, args.lpTotalSupply, args);
        uint256 low;
        uint256 high;
        if (quadOutput >= args.desiredOut) {
            // Guess is good or high; search downward from it
            low = 0;
            high = quadraticGuess + 100; // Small buffer for overshoot
            high = high > args.lpTotalSupply ? args.lpTotalSupply : high;
        } else {
            // Guess is low; search upward
            low = quadraticGuess > 100 ? quadraticGuess - 100 : 0; // Small buffer for floor
            high = args.lpTotalSupply;
            // if (low > high) low = 0;
        }
        // Binary search in tightened range
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            uint256 output = _computeZapOut(mid, args.lpTotalSupply, args);
            if (output >= args.desiredOut) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        lpNeeded = low;
        // Verify (safety)
        uint256 finalOutput = _computeZapOut(low, args.lpTotalSupply, args);
        while (finalOutput < args.desiredOut && lpNeeded < args.lpTotalSupply) {
            lpNeeded++;
            finalOutput = _computeZapOut(lpNeeded, args.lpTotalSupply, args);
        }
        return lpNeeded;
    }

    /**
     * @dev Computes the exact output for a given LP burn amount using integer math (simulates ZapOut).
     * @param lp Amount of LP to burn.
     * @param lpTotalSupply Adjusted total LP supply.
     * @param args The zap out parameters (reserves, fees, etc).
     * @return totalOut The total output in the desired token.
     */
    function _computeZapOut(uint256 lp, uint256 lpTotalSupply, ZapOutToTargetWithFeeArgs memory args)
        internal
        pure
        returns (uint256 totalOut)
    {
        if (lp == 0) return 0;
        uint256 amountDesiredDirect = lp * args.reserveDesired / lpTotalSupply;
        uint256 amountOther = lp * args.reserveOther / lpTotalSupply;
        uint256 reserveDesiredPrime = args.reserveDesired - amountDesiredDirect;
        uint256 reserveOtherPrime = args.reserveOther - amountOther;
        if (reserveOtherPrime == 0 || reserveDesiredPrime == 0) {
            return amountDesiredDirect;
        }
        uint256 feeMultiplier = args.feeDenominator - args.feePercent;
        uint256 numerator = amountOther * feeMultiplier * reserveDesiredPrime;
        uint256 denominator = reserveOtherPrime * args.feeDenominator + amountOther * feeMultiplier;
        uint256 amountDesiredSwap = numerator / denominator;
        return amountDesiredDirect + amountDesiredSwap;
    }

    /* -------------------------------------------------------------------------- */
    /*                             Yield Calculations                             */
    /* -------------------------------------------------------------------------- */

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
        uint256 claimableA = Math._mulDiv(ownedLP, reserveA, totalSupply);
        uint256 claimableB = Math._mulDiv(ownedLP, reserveB, totalSupply);
        // Hypothetical no-fee claimable amounts (adjusted for current price ratio)
        // Arrange mul/div to reduce overflow risk by dividing early
        // noFeeA^2 ≈ initialA * initialB * reserveA / reserveB (match test order)
        uint256 sA = (initialA * initialB * reserveA) / reserveB;
        uint256 noFeeA = Math._sqrt(sA);
        // noFeeB^2 ≈ initialA * initialB * reserveB / reserveA (match test order)
        uint256 sB = (initialA * initialB * reserveB) / reserveA;
        uint256 noFeeB = Math._sqrt(sB);
        // Fee portions, clamped to 0
        feeA = claimableA > noFeeA ? claimableA - noFeeA : 0;
        feeB = claimableB > noFeeB ? claimableB - noFeeB : 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                                Protocol Fees                               */
    /* -------------------------------------------------------------------------- */

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
            return 0;
        }
        if (ownerFeeShare == 0) {
            return 0;
        }

        // Compute sqrt(K) using protocol-specific rounding
        // Uniswap path will override below; generic (Camelot-like) uses Camelot's Math.sqrt
        uint256 rootK = CamMath.sqrt(newK);
        uint256 rootKLast = CamMath.sqrt(kLast);

        if (rootK <= rootKLast) {
            return 0;
        }
        // Exact Uniswap V2 mint (feeTo) path corresponds to ownerFeeShare ~= 1/6
        // Uni formula: liquidity = totalSupply * (rootK - rootKLast) / (5*rootK + rootKLast)
        if (ownerFeeShare >= 16666 && ownerFeeShare <= 16667) {
            uint256 uniRootK = UniV2Math._sqrt(newK);
            uint256 uniRootKLast = UniV2Math._sqrt(kLast);
            if (uniRootK <= uniRootKLast) return 0;
            uint256 uniDen = (uniRootK * 5) + uniRootKLast;
            if (uniDen == 0) return 0;
            return (lpTotalSupply * (uniRootK - uniRootKLast)) / uniDen;
        }

        // Generic ownerFeeShare-based formula (Camelot-like)
        uint256 d = (FEE_DENOMINATOR * 100) / ownerFeeShare;
        if (d <= 100) return 0;
        d = d - 100;
        uint256 numerator = lpTotalSupply * (rootK - rootKLast) * 100;
        uint256 denominator = rootK * d + rootKLast * 100;
        if (denominator == 0) return 0;
        return numerator / denominator;
    }

    // Exact Uniswap V2 fee mint calculation to mirror pair._mintFee
    function _calculateProtocolFeeMint(uint256 lpTotalSupply, uint256 reserve0, uint256 reserve1, uint256 kLast)
        internal
        pure
        returns (uint256 liquidity)
    {
        if (kLast == 0) return 0;
        uint256 rootK = UniV2Math._sqrt(uint256(reserve0) * (reserve1));
        uint256 rootKLast = UniV2Math._sqrt(kLast);
        if (rootK <= rootKLast) return 0;
        uint256 numerator = lpTotalSupply * (rootK - (rootKLast));
        uint256 denominator = (rootK * 5) + (rootKLast);
        liquidity = numerator / denominator;
    }

    /* -------------------------------------------------------------------------- */
    /*                             Additional Deposit                             */
    /* -------------------------------------------------------------------------- */

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
        if (
            amountA == 0 || reserveA == 0 || reserveB == 0
        ) {
            return 0;
        }
        amountB = (amountA * reserveB) / reserveA;
    }

    // end::_equivLiquidity[]

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
        if (feeOn && kLast != 0) {
            // Protocol fee is minted based on growth in K since last liquidity event,
            // using current reserves (before this deposit), matching pair.mint behavior.
            uint256 currentK = lpReserveA * lpReserveB;
            protocolFee = _calculateProtocolFee(lpTotalSupply, currentK, kLast, ownerFeeShare);
            lpTotalSupply += protocolFee;
        }
        lpAmt = _depositQuote(amountADeposit, amountBDeposit, lpTotalSupply, lpReserveA, lpReserveB);
        return (lpAmt);
    }

    /**
     * @dev Quotes the amount of tokens received from a withdrawal followed by a swap.
     * @param ownedLPAmount The amount of LP tokens to burn.
     * @param lpTotalSupply The current total supply of LP tokens.
     * @param reserveA The reserve of Token A.
     * @param reserveB The reserve of Token B.
     * @param feePercent The swap fee percentage.
     * @param feeDenominator The fee denominator.
     * @param kLast The last stored K value.
     * @param ownerFeeShare The protocol fee share.
     * @param feeOn Whether protocol fees are enabled.
     * @return totalAmountA The total amount of Token A received.
     */
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
        if (ownedLPAmount == 0 || lpTotalSupply == 0 || reserveA == 0 || reserveB == 0 || feePercent >= feeDenominator)
        {
            return (0);
        }
        if (ownedLPAmount > lpTotalSupply) {
            return (0);
        }
        if (feeOn && kLast != 0) {
            if (ownerFeeShare >= 16666 && ownerFeeShare <= 16667) {
                uint256 protocolFee = _calculateProtocolFeeMint(lpTotalSupply, reserveA, reserveB, kLast);
                lpTotalSupply += protocolFee;
            } else {
                uint256 newK = reserveA * reserveB;
                uint256 protocolFee = _calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
                lpTotalSupply += protocolFee;
            }
        }
        (uint256 amountAWD, uint256 amountBWD) = _withdrawQuote(ownedLPAmount, lpTotalSupply, reserveA, reserveB);
        uint256 newReserveB = reserveB - amountBWD;
        uint256 newReserveA = reserveA - amountAWD;
        uint256 swapOut = _saleQuote(amountBWD, newReserveB, newReserveA, feePercent, feeDenominator);
        totalAmountA = amountAWD + swapOut;
        return (totalAmountA);
    }
}
