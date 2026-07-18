// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/contracts/constants/Constants.sol";
import "@crane/contracts/GeneralErrors.sol";
import {Uint512, BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";
import {Math as UniV2Math} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol";
import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol";

// tag::ConstProdUtils[]
/**
 * @title ConstProdUtils
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Core constant-product (xy = k) AMM math utilities for sale/purchase quotes, liquidity add/remove (including protocol fees), zap-in/out quoting, fee portions, and yield calcs.
 * @dev Internal-only API (all _-prefixed functions). Consumed via `using ConstProdUtils for uint256;` (and for Uint512) inside *Service libs (CamelotV2Service, AerodromeService*, UniswapV2Utils etc), targets, and tests.
 * @dev Pure math utility library (no storage, LR-6 n/a). Provides integer-arithmetic parity with UniswapV2 / Camelot / Aerodrome (volatile) pair math for exact quotes and LP accounting.
 * @dev Models gold *Service / *Utils / InitDevService / Access*FactoryService NatSpec + AsciiDoc include-tag style per AGENTS.md and PRD LR-1. No @custom:selector/interfaceid (pure util; none in CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
 * @dev See AGENTS.md (utility libs highlighted as ConstProdUtils gold example), PRD LR-1 (tags + rich NatSpec), LR-2 (math utils coverage).
 */
library ConstProdUtils {
    using Math for uint256;
    using Math for Uint512;
    using ConstProdUtils for uint256;

    uint256 constant _MINIMUM_LIQUIDITY = 10 ** 3;

    /* -------------------------------------------------------------------------- */
    /*                                  Reserves                                  */
    /* -------------------------------------------------------------------------- */

    // tag::_sortReserves(address-address-uint256-uint256)[]
    /**
     * @notice Sorts reserves based on the known token and token0.
     * @dev Internal helper for reserve/fee ordering used by quote and liquidity flows.
     * @param knownToken The token that is known (determines which side is "in").
     * @param token0 The token that is token0 in the pair.
     * @param reserve0 The reserve of token0.
     * @param reserve1 The reserve of the other token.
     * @return knownReserve The reserve of the known token.
     * @return unknownReserve The reserve of the unknown/opposing token.
     */
    function _sortReserves(address knownToken, address token0, uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint256 knownReserve, uint256 unknownReserve)
    {
        return knownToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // end::_sortReserves(address-address-uint256-uint256)[]

    // tag::_sortReserves(address-address-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Sorts reserves and fees based on the known token and token0.
     * @dev Overload that also sorts per-side fees (e.g. Camelot token0feePercent / token1feePercent).
     * @param knownToken The token that is known (determines which side is "in").
     * @param token0 The token that is token0 in the pair.
     * @param reserve0 The reserve of token0.
     * @param reserve0Fee The fee of token0 side.
     * @param reserve1 The reserve of the other token.
     * @param reserve1Fee The fee of the other side.
     * @return knownReserve The reserve of the known token.
     * @return knownReserveFee The fee of the known token side.
     * @return unknownReserve The reserve of the unknown/opposing token.
     * @return unknownReserveFee The fee of the unknown side.
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

    // end::_sortReserves(address-address-uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                   Deposit                                  */
    /* -------------------------------------------------------------------------- */

    // tag::_depositQuote(uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Provides the LP token mint amount for a given deposit, reserve, and total supply.
     * @dev Handles first-mint case (sqrt product minus min liquidity) and proportional case (min of ratios).
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

    // end::_depositQuote(uint256-uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                 Withdrawal                                 */
    /* -------------------------------------------------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                    Swaps                                   */
    /* -------------------------------------------------------------------------- */

    // tag::_saleQuote(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the proceeds of a swap (sale quote / amount out for amount in).
     * @dev Default overload using FEE_DENOMINATOR (100000). Delegates to 5-param version.
     * @param amountIn The amount of token to be sold.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param saleFeePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @return saleProceeds The proceeds of the swap (amount out).
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

    // end::_saleQuote(uint256-uint256-uint256-uint256)[]

    // tag::_saleQuote(uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the proceeds of a swap (sale quote / amount out for amount in).
     * @dev Core constant product formula with fee: amountOut = (amountInWithFee * reserveOut) / (reserveIn * feeDen + amountInWithFee)
     * @param amountIn The amount of token to be sold.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param saleFeePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @param feeDenominator The fee denominator used by the pool (e.g. 100000 or 1000).
     * @return saleProceeds The proceeds of the swap (amount out).
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

    // end::_saleQuote(uint256-uint256-uint256-uint256-uint256)[]

    // tag::_purchaseQuote(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the amount of token to sell to effect a purchase of a desired amount of the other token (exact-out).
     * @dev Default overload using FEE_DENOMINATOR. Delegates to 5-param version.
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

    // end::_purchaseQuote(uint256-uint256-uint256-uint256)[]

    // tag::_purchaseQuote(uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the amount of token to sell to effect a purchase of a desired amount of the other token (exact-out).
     * @dev Core inversion of constant product with fee +1 for rounding safety. Reverts on invalid inputs.
     * @param amountOut The amount of the token to purchase.
     * @param reserveIn The reserve of the input token in the pool (e.g., token A).
     * @param reserveOut The reserve of the output token in the pool (e.g., token B).
     * @param feePercent The swap fee in PPHK, i.e 0.5% == 500.
     * @param feeDenominator The fee denominator used by the pool (e.g., 100,000).
     * @return amountIn The amount of the token to sell.
     * @custom:throws ArgumentMustNotBeZero if amountOut==0 or reserveIn==0 (from GeneralErrors)
     * @custom:throws ArgumentMustBeGreaterThan for insufficient liquidity or bad fee ratio (from GeneralErrors)
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

    // end::_purchaseQuote(uint256-uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                            Swap/Deposit (ZapIn)                            */
    /* -------------------------------------------------------------------------- */

    // tag::_quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Calculates the expected LP tokens from a swap deposit operation (ZapIn), accounting for protocol fees.
     * @dev Convenience overload that infers feeDenominator via heuristic (fee<=10 -> 1000 else 100000). See overload for explicit.
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

    // end::_quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    // tag::_quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Calculates the expected LP tokens from a swap deposit operation (ZapIn) with explicit fee denominator.
     * @dev Overload that accepts explicit feeDenom to avoid heuristic misclassification of low modern fees.
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

    // end::_quoteSwapDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    // tag::SwapDepositArgs[]
    /**
     * @dev Internal param struct bundling inputs for _quoteSwapDepositWithFee (and related).
     * Avoids stack-too-deep in complex zap/fee calcs.
     */
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

    // end::SwapDepositArgs[]

    // tag::_quoteSwapDepositWithFee(SwapDepositArgs)[]
    /**
     * @notice Internal implementation of swap-deposit quote using SwapDepositArgs struct.
     * @dev The feeDenominator field in args determines how feePercent is interpreted.
     *      Callers should set args.feeDenominator explicitly, or use the convenience overloads.
     * @param args Bundled inputs.
     * @return lpAmt Expected LP after the simulated swap+deposit (with fee logic).
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

    // end::_quoteSwapDepositWithFee(SwapDepositArgs)[]

    // tag::_swapDepositSaleAmt(uint256-uint256-uint256)[]
    /**
     * @notice Computes the amount of input to sell (during zap deposit) to balance the deposit of remaining.
     * @dev Default overload using FEE_DENOMINATOR. Solves quadratic for optimal split.
     * @param amountIn Total input amount.
     * @param saleReserve Reserve of the input side.
     * @param feePercent Fee percent.
     * @return saleAmt Amount of input to route through sale (swap) vs direct deposit.
     */
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

    // end::_swapDepositSaleAmt(uint256-uint256-uint256)[]

    // tag::_swapDepositSaleAmt(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Computes the amount of input to sell (during zap deposit) to balance the deposit of remaining.
     * @dev Uses quadratic formula derived from constant product invariant to find split point.
     * @param amountIn Total input amount.
     * @param saleReserve Reserve of the input side.
     * @param feePercent Fee percent.
     * @param feeDenominator Fee denominator.
     * @return saleAmt Amount of input to route through sale (swap) vs direct deposit.
     */
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

    // end::_swapDepositSaleAmt(uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                  WITHDRAW                                  */
    /* -------------------------------------------------------------------------- */

    // tag::_quoteWithdrawWithFee(uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Quotes withdrawal amounts (pro-rata of reserves) with optional protocol fee adjustment on K growth.
     * @dev Adjusts lpTotalSupply upward for fee mint before computing shares if feeOn.
     * @param ownedLPAmount Owned amount of LP token.
     * @param lpTotalSupply LP token total supply.
     * @param totalReserveA LP reserve of Token A.
     * @param totalReserveB LP reserve of Token B.
     * @param kLast Last K value.
     * @param ownerFeeShare Protocol owner fee share.
     * @param feeOn Whether fees are on.
     * @return ownedReserveA Owned share of Token A.
     * @return ownedReserveB Owned share of Token B.
     */
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

    // end::_quoteWithdrawWithFee(uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    // tag::_withdrawQuote(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Provides the owned balances of a given liquidity pool reserve.
     * @dev Uses A/B nomenclature to indicate order DOES NOT matter, simply correlate variables to the same tokens.
     *      Pure pro-rata share (no fees here).
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

    // end::_withdrawQuote(uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                            ZapIn to Target Quote                           */
    /* -------------------------------------------------------------------------- */

    // tag::_quoteZapInToTargetLPWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Quotes the amount of `tokenIn` required to ZapIn and mint at least `targetLP` LP tokens.
     * @dev The ZapIn flow is: split `amountIn` into sale portion + deposit portion then add proportionally.
     *      Inverts via binary search + safety steps. See body for bounds/strategy.
     * @param targetLP    Desired LP token amount (must be < lpTotalSupply).
     * @param lpTotalSupply  Current LP total supply.
     * @param reserveIn   Reserve of the ZapIn token.
     * @param reserveOut  Reserve of the opposing token.
     * @param feePercent  Swap fee numerator.
     * @param feeDenominator  Swap fee denominator.
     * @param kLast       Last stored K value (0 if protocol fees disabled).
     * @param ownerFeeShare  Protocol fee share denominator (e.g. 16667 for 1/6).
     * @param feeOn       Whether protocol fees are enabled.
     * @return amountIn   Minimum `tokenIn` required to obtain at least `targetLP`.
     */
    function _quoteZapInToTargetLPWithFee(
        uint256 targetLP,
        uint256 lpTotalSupply,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feePercent,
        uint256 feeDenominator,
        uint256 kLast,
        uint256 ownerFeeShare,
        bool feeOn
    ) internal pure returns (uint256 amountIn) {
        if (targetLP == 0 || lpTotalSupply == 0 || reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        if (targetLP >= lpTotalSupply) {
            return 0; // Cannot mint 100% of existing supply via ZapIn
        }

        // Protocol-fee-adjusted supply (same adjustment as in _quoteSwapDepositWithFee)
        uint256 adjSupply = lpTotalSupply;
        if (feeOn && kLast != 0 && ownerFeeShare != 0) {
            uint256 newK = reserveIn * reserveOut;
            if (newK > kLast) {
                uint256 pFee = _calculateProtocolFee(adjSupply, newK, kLast, ownerFeeShare);
                adjSupply += pFee;
            }
        }

        // Conservative upper bound: ZapIn produces at most ~amountIn * lpSupply / (2 * reserveIn)
        // LP when the price is 1:1. Multiply by 4 for safety margin and round up.
        // high = 4 * targetLP * reserveIn / lpTotalSupply, but clamp to prevent huge inputs.
        uint256 high;
        {
            // targetLP * reserveIn / lpTotalSupply  ≈ LP-proportional share of reserveIn
            // Multiply by 4 as generous headroom.
            uint256 tmp = (targetLP * reserveIn) / adjSupply;
            high = tmp * 4 + 1;
            if (high < 2) high = 2;
        }

        // Verify high is sufficient; if not, double until it is.
        // (In degenerate pools the 4x may still be too low; bound by 128 doublings.)
        for (uint256 i = 0; i < 128; i++) {
            uint256 candidate = _quoteSwapDepositWithFee(
                high, lpTotalSupply, reserveIn, reserveOut, feePercent, feeDenominator, kLast, ownerFeeShare, feeOn
            );
            if (candidate >= targetLP) break;
            high = high * 2;
        }

        // Binary search: find minimal amountIn such that forward quote >= targetLP
        uint256 low = 1;
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            uint256 out = _quoteSwapDepositWithFee(
                mid, lpTotalSupply, reserveIn, reserveOut, feePercent, feeDenominator, kLast, ownerFeeShare, feeOn
            );
            if (out >= targetLP) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        amountIn = low;

        // Safety: step up until we actually get at least targetLP (guards against rounding at boundary)
        for (uint256 i = 0; i < 4; i++) {
            uint256 check = _quoteSwapDepositWithFee(
                amountIn, lpTotalSupply, reserveIn, reserveOut, feePercent, feeDenominator, kLast, ownerFeeShare, feeOn
            );
            if (check >= targetLP) break;
            amountIn++;
        }

        return amountIn;
    }

    // end::_quoteZapInToTargetLPWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    /* -------------------------------------------------------------------------- */
    /*                           ZapOut to Target Quote                           */
    /* -------------------------------------------------------------------------- */

    // tag::ZapOutToTargetWithFeeArgs[]
    /**
     * @dev Internal param struct for _quoteZapOutToTargetWithFee (quadratic + binary search impl).
     */
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

    // end::ZapOutToTargetWithFeeArgs[]

    // tag::_quoteZapOutToTargetWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Quotes the amount of LP tokens needed for a ZapOut to receive at least a desired amount of output token in a Uniswap V2-like pool.
     * @dev Accounts for swap fees and protocol fee mints that dilute lpTotalSupply.
     *      Overestimates lpNeeded by applying a bounded buffer on desiredOut to ensure >= desiredOut.
     * @param desiredOut Desired amount of output token.
     * @param lpTotalSupply Current LP total supply (includes past protocol fee mints).
     * @param reserveDesired Reserve of the output token.
     * @param reserveOther Reserve of the token to be swapped to the output token.
     * @param feePercent Swap fee (e.g., 3000 for 0.3% with feeDenominator=100000).
     * @param feeDenominator Fee denominator (e.g., 100000).
     * @param kLast Last K value before the operation.
     * @param ownerFeeShare Protocol fee share (e.g., 16667 for 1/6).
     * @param feeOn Whether protocol fees are enabled.
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
    ) internal pure returns (uint256 lpNeeded) {
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

    // end::_quoteZapOutToTargetWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    // tag::_quoteZapOutToTargetWithFee(ZapOutToTargetWithFeeArgs)[]
    /**
     * @notice Quotes the amount of LP tokens needed for a ZapOut to receive at least a desired amount of output token.
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

    // end::_quoteZapOutToTargetWithFee(ZapOutToTargetWithFeeArgs)[]

    // tag::_computeZapOut(uint256-uint256-ZapOutToTargetWithFeeArgs)[]
    /**
     * @notice Computes the exact output for a given LP burn amount using integer math (simulates ZapOut).
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

    // end::_computeZapOut(uint256-uint256-ZapOutToTargetWithFeeArgs)[]

    /* -------------------------------------------------------------------------- */
    /*                             Yield Calculations                             */
    /* -------------------------------------------------------------------------- */

    // tag::_calculateFeePortionForPosition(uint256-uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the portion of reserves attributable to market maker fees for a specific LP position
     * in a Uniswap V2-like pool, ensuring non-negative yields for vault fee calculations.
     * @dev Returns unsigned integers, clamping negatives to 0 (ignoring IL effects).
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

    // end::_calculateFeePortionForPosition(uint256-uint256-uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                Protocol Fees                               */
    /* -------------------------------------------------------------------------- */

    // tag::_calculateProtocolFee(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the protocol fee amount based on the growth of K value (sqrtK delta).
     * @dev Branches for Uniswap (1/6) vs generic ownerFeeShare formulas; uses protocol-specific sqrt impls.
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

    // end::_calculateProtocolFee(uint256-uint256-uint256-uint256)[]

    // tag::_calculateProtocolFeeMint(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Exact Uniswap V2 fee mint calculation to mirror pair._mintFee.
     * @dev Uses the specific 5*rootK + rootKLast denominator for Uniswap 1/6 share.
     * @param lpTotalSupply Current total supply.
     * @param reserve0 Current reserve0.
     * @param reserve1 Current reserve1.
     * @param kLast Prior kLast.
     * @return liquidity LP to mint as fee.
     */
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

    // end::_calculateProtocolFeeMint(uint256-uint256-uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                             Additional Deposit                             */
    /* -------------------------------------------------------------------------- */

    // tag::_equivLiquidity(uint256-uint256-uint256)[]
    /**
     * @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset (x * resB / resA).
     * @dev Simple constant-product equivalent calc; used for balanced deposit math.
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
        if (amountA == 0 || reserveA == 0 || reserveB == 0) {
            return 0;
        }
        amountB = (amountA * reserveB) / reserveA;
    }

    // end::_equivLiquidity(uint256-uint256-uint256)[]

    // tag::_quoteDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Quotes LP for a direct deposit, optionally adding protocol fee to supply first.
     * @param amountADeposit Desired deposit of A.
     * @param amountBDeposit Desired deposit of B.
     * @param lpTotalSupply Current supply (may be adjusted).
     * @param lpReserveA Current reserve A.
     * @param lpReserveB Current reserve B.
     * @param kLast Prior kLast for fee calc.
     * @param ownerFeeShare Fee share.
     * @param feeOn Fees enabled.
     * @return lpAmt LP to mint.
     */
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

    // end::_quoteDepositWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]

    // tag::_quoteWithdrawSwapWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    /**
     * @notice Quotes the amount of tokens received from a withdrawal followed by a swap (A out total).
     * @dev Burns LP for pro-rata, then sells the B side into A using saleQuote on post-withdraw reserves.
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
    // end::_quoteWithdrawSwapWithFee(uint256-uint256-uint256-uint256-uint256-uint256-uint256-uint256-bool)[]
    // end::ConstProdUtils[]
}
