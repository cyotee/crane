// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {SwapMath} from "../libraries/SwapMath.sol";
import {SqrtPriceMath} from "../libraries/SqrtPriceMath.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {FullMath} from "../libraries/FullMath.sol";
import {FixedPoint96} from "../libraries/FixedPoint96.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";

/// @title UniswapV4Utils
/// @notice Math utilities for quoting Uniswap V4 swaps within a single tick
/// @dev V4 Architecture Key Points:
///      - PoolManager is a singleton that holds all pool state
///      - Pools are identified by PoolKey (currency0, currency1, fee, tickSpacing, hooks)
///      - Uses same concentrated liquidity math as V3 (tick-based pricing)
///      - Fee structure: lpFee (LP fee) + protocolFee (protocol takes from lpFee)
///      - Assumes swaps stay within current tick (no tick crossing)
/// @dev This library provides the same functionality as UniswapV3Utils, adapted for V4's architecture
library UniswapV4Utils {
    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev V4 fee denominator (1,000,000 for pips precision)
    uint256 internal constant FEE_DENOMINATOR = 1e6;

    /* -------------------------------------------------------------------------- */
    /*                            ExactIn Swap Quote                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote swap output for exact input (sale quote)
    /// @dev Assumes swap stays within current tick (no tick boundary crossing)
    /// @dev Uses SwapMath.computeSwapStep with target price at tick boundary
    /// @param amountIn Amount of input currency to swap
    /// @param sqrtPriceX96 Current pool sqrt price (Q64.96 format)
    /// @param liquidity Available liquidity in current tick
    /// @param lpFeePips LP fee in pips (e.g., 3000 = 0.3%, 500 = 0.05%, 10000 = 1%)
    /// @param zeroForOne Swap direction: true = currency0→currency1, false = currency1→currency0
    /// @return amountOut Output amount after fees
    function _quoteExactInputSingle(
        uint256 amountIn,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint24 lpFeePips,
        bool zeroForOne
    ) internal pure returns (uint256 amountOut) {
        // Set target price to tick boundary (swap won't cross tick in single-tick quote)
        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1  // Swap currency0 for currency1 (price decreases)
            : TickMath.MAX_SQRT_PRICE - 1; // Swap currency1 for currency0 (price increases)

        // Delegate to SwapMath.computeSwapStep
        // In V4, amountSpecified is negative for exact input
        // Returns: (sqrtRatioNextX96, amountIn, amountOut, feeAmount)
        (,, amountOut,) = SwapMath.computeSwapStep(
            sqrtPriceX96,
            sqrtPriceTargetX96,
            liquidity,
            -int256(amountIn),  // Negative for exact input
            lpFeePips
        );
    }

    /// @notice Quote swap output for exact input using current tick
    /// @dev Overload that accepts tick instead of sqrtPriceX96
    /// @param amountIn Amount of input currency to swap
    /// @param tick Current pool tick
    /// @param liquidity Available liquidity in current tick
    /// @param lpFeePips LP fee in pips
    /// @param zeroForOne Swap direction
    /// @return amountOut Output amount after fees
    function _quoteExactInputSingle(
        uint256 amountIn,
        int24 tick,
        uint128 liquidity,
        uint24 lpFeePips,
        bool zeroForOne
    ) internal pure returns (uint256 amountOut) {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);
        return _quoteExactInputSingle(amountIn, sqrtPriceX96, liquidity, lpFeePips, zeroForOne);
    }

    /* -------------------------------------------------------------------------- */
    /*                           ExactOut Swap Quote                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote input required for exact output (purchase quote)
    /// @dev Assumes swap stays within current tick (no tick boundary crossing)
    /// @dev Uses SwapMath.computeSwapStep with positive amountRemaining
    /// @param amountOut Desired output amount
    /// @param sqrtPriceX96 Current pool sqrt price (Q64.96 format)
    /// @param liquidity Available liquidity in current tick
    /// @param lpFeePips LP fee in pips
    /// @param zeroForOne Swap direction: true = currency0→currency1, false = currency1→currency0
    /// @return amountIn Required input amount (includes fees)
    function _quoteExactOutputSingle(
        uint256 amountOut,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint24 lpFeePips,
        bool zeroForOne
    ) internal pure returns (uint256 amountIn) {
        // Set target price to tick boundary
        uint160 sqrtPriceTargetX96 = zeroForOne
            ? TickMath.MIN_SQRT_PRICE + 1
            : TickMath.MAX_SQRT_PRICE - 1;

        // Delegate to SwapMath.computeSwapStep with positive amount (exact output)
        // Returns: (sqrtRatioNextX96, amountIn, amountOut, feeAmount)
        // Note: For exact output, feeAmount is calculated separately and must be added to amountIn
        uint256 feeAmount;
        (, amountIn,, feeAmount) = SwapMath.computeSwapStep(
            sqrtPriceX96,
            sqrtPriceTargetX96,
            liquidity,
            int256(amountOut),  // Positive for exact output
            lpFeePips
        );
        // Total required input includes the swap amount plus the fee
        amountIn = amountIn + feeAmount;
    }

    /// @notice Quote input required for exact output using current tick
    /// @dev Overload that accepts tick instead of sqrtPriceX96
    /// @param amountOut Desired output amount
    /// @param tick Current pool tick
    /// @param liquidity Available liquidity in current tick
    /// @param lpFeePips LP fee in pips
    /// @param zeroForOne Swap direction
    /// @return amountIn Required input amount (includes fees)
    function _quoteExactOutputSingle(
        uint256 amountOut,
        int24 tick,
        uint128 liquidity,
        uint24 lpFeePips,
        bool zeroForOne
    ) internal pure returns (uint256 amountIn) {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);
        return _quoteExactOutputSingle(amountOut, sqrtPriceX96, liquidity, lpFeePips, zeroForOne);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Helper Functions                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Convert currency reserves to sqrt price in Q64.96 format
    /// @dev Calculates sqrt(reserve1/reserve0) * 2^96
    /// @dev Useful for converting V2-style reserves to V4 sqrt price format
    /// @param reserve0 Reserve of currency0
    /// @param reserve1 Reserve of currency1
    /// @return sqrtPriceX96 Sqrt price in Q64.96 fixed-point format
    function _getSqrtPriceFromReserves(
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns (uint160 sqrtPriceX96) {
        require(reserve0 > 0, "Invalid reserve0");

        // Calculate sqrt(reserve1/reserve0) * 2^96
        // We can't do (reserve1 / reserve0) * 2^192 directly due to overflow
        // Instead: sqrtPrice = sqrt(reserve1 / reserve0) * 2^96
        //                     = sqrt(reserve1 * 2^96) / sqrt(reserve0)
        // Or equivalently: sqrt(reserve1) * 2^96 / sqrt(reserve0)
        uint256 sqrtReserve0 = BetterMath._sqrt(reserve0);
        uint256 sqrtReserve1 = BetterMath._sqrt(reserve1);

        // sqrtPrice = (sqrtReserve1 / sqrtReserve0) * 2^96
        sqrtPriceX96 = uint160(FullMath.mulDiv(sqrtReserve1, FixedPoint96.Q96, sqrtReserve0));
    }

    /* -------------------------------------------------------------------------- */
    /*                          Price/Amount Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Get currency0 amount between two sqrt prices
    /// @dev Wrapper around SqrtPriceMath.getAmount0Delta
    /// @param sqrtPriceAX96 First sqrt price (Q64.96)
    /// @param sqrtPriceBX96 Second sqrt price (Q64.96)
    /// @param liquidity Liquidity amount
    /// @param roundUp Whether to round up (true for amounts to pay, false for amounts to receive)
    /// @return amount0 Currency0 amount
    function _getAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        return SqrtPriceMath.getAmount0Delta(sqrtPriceAX96, sqrtPriceBX96, liquidity, roundUp);
    }

    /// @notice Get currency1 amount between two sqrt prices
    /// @dev Wrapper around SqrtPriceMath.getAmount1Delta
    /// @param sqrtPriceAX96 First sqrt price (Q64.96)
    /// @param sqrtPriceBX96 Second sqrt price (Q64.96)
    /// @param liquidity Liquidity amount
    /// @param roundUp Whether to round up (true for amounts to pay, false for amounts to receive)
    /// @return amount1 Currency1 amount
    function _getAmount1Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        return SqrtPriceMath.getAmount1Delta(sqrtPriceAX96, sqrtPriceBX96, liquidity, roundUp);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Liquidity/Amount Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Compute the currency amounts required for a given liquidity position
    /// @dev Amounts depend on whether current price is below, within, or above the tick range
    /// @param sqrtPriceX96 Current pool sqrt price (Q64.96)
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity Amount of liquidity
    /// @return amount0 Amount of currency0 required
    /// @return amount1 Amount of currency1 required
    function _quoteAmountsForLiquidity(
        uint160 sqrtPriceX96,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        uint160 sqrtRatioLowerX96 = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtRatioUpperX96 = TickMath.getSqrtPriceAtTick(tickUpper);

        if (sqrtPriceX96 <= sqrtRatioLowerX96) {
            // Current price is below the range: only currency0 is needed
            amount0 = _getAmount0ForLiquidity(sqrtRatioLowerX96, sqrtRatioUpperX96, liquidity);
            amount1 = 0;
        } else if (sqrtPriceX96 >= sqrtRatioUpperX96) {
            // Current price is above the range: only currency1 is needed
            amount0 = 0;
            amount1 = _getAmount1ForLiquidity(sqrtRatioLowerX96, sqrtRatioUpperX96, liquidity);
        } else {
            // Current price is within the range: both currencies needed
            amount0 = _getAmount0ForLiquidity(sqrtPriceX96, sqrtRatioUpperX96, liquidity);
            amount1 = _getAmount1ForLiquidity(sqrtRatioLowerX96, sqrtPriceX96, liquidity);
        }
    }

    /// @notice Compute the currency amounts required for a given liquidity position (tick overload)
    /// @param tick Current pool tick
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity Amount of liquidity
    /// @return amount0 Amount of currency0 required
    /// @return amount1 Amount of currency1 required
    function _quoteAmountsForLiquidity(
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);
        return _quoteAmountsForLiquidity(sqrtPriceX96, tickLower, tickUpper, liquidity);
    }

    /// @notice Compute maximum liquidity from given currency amounts for a position
    /// @dev Returns the maximum liquidity mintable given the provided amounts
    /// @dev The limiting factor (smaller liquidity contribution) determines the result
    /// @param sqrtPriceX96 Current pool sqrt price (Q64.96)
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param amount0 Amount of currency0 available
    /// @param amount1 Amount of currency1 available
    /// @return liquidity Maximum liquidity that can be minted
    function _quoteLiquidityForAmounts(
        uint160 sqrtPriceX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        uint160 sqrtRatioLowerX96 = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtRatioUpperX96 = TickMath.getSqrtPriceAtTick(tickUpper);

        if (sqrtPriceX96 <= sqrtRatioLowerX96) {
            // Current price is below the range: liquidity determined by currency0 only
            liquidity = _getLiquidityForAmount0(sqrtRatioLowerX96, sqrtRatioUpperX96, amount0);
        } else if (sqrtPriceX96 >= sqrtRatioUpperX96) {
            // Current price is above the range: liquidity determined by currency1 only
            liquidity = _getLiquidityForAmount1(sqrtRatioLowerX96, sqrtRatioUpperX96, amount1);
        } else {
            // Current price is within the range: take minimum of both
            uint128 liquidity0 = _getLiquidityForAmount0(sqrtPriceX96, sqrtRatioUpperX96, amount0);
            uint128 liquidity1 = _getLiquidityForAmount1(sqrtRatioLowerX96, sqrtPriceX96, amount1);
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }
    }

    /// @notice Compute maximum liquidity from given currency amounts (tick overload)
    /// @param tick Current pool tick
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param amount0 Amount of currency0 available
    /// @param amount1 Amount of currency1 available
    /// @return liquidity Maximum liquidity that can be minted
    function _quoteLiquidityForAmounts(
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(tick);
        return _quoteLiquidityForAmounts(sqrtPriceX96, tickLower, tickUpper, amount0, amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Internal Amount Calculations                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Get amount0 for given liquidity between two sqrt prices (no rounding)
    /// @dev Used for computing amounts needed to provide liquidity
    /// @param sqrtRatioAX96 First sqrt price (Q64.96)
    /// @param sqrtRatioBX96 Second sqrt price (Q64.96)
    /// @param liquidity Liquidity amount
    /// @return amount0 Currency0 amount
    function _getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        // amount0 = liquidity * (sqrtRatioBX96 - sqrtRatioAX96) / (sqrtRatioBX96 * sqrtRatioAX96) * 2^96
        // Rearranged to avoid overflow: liquidity * 2^96 * (sqrtRatioB - sqrtRatioA) / sqrtRatioB / sqrtRatioA
        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 priceDelta = sqrtRatioBX96 - sqrtRatioAX96;

        amount0 = FullMath.mulDiv(numerator, priceDelta, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Get amount1 for given liquidity between two sqrt prices (no rounding)
    /// @dev Used for computing amounts needed to provide liquidity
    /// @param sqrtRatioAX96 First sqrt price (Q64.96)
    /// @param sqrtRatioBX96 Second sqrt price (Q64.96)
    /// @param liquidity Liquidity amount
    /// @return amount1 Currency1 amount
    function _getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        // amount1 = liquidity * (sqrtRatioBX96 - sqrtRatioAX96) / 2^96
        amount1 = FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Compute liquidity from currency0 amount
    /// @dev Inverse of _getAmount0ForLiquidity
    /// @param sqrtRatioAX96 Lower sqrt price (Q64.96)
    /// @param sqrtRatioBX96 Upper sqrt price (Q64.96)
    /// @param amount0 Currency0 amount
    /// @return liquidity Computed liquidity
    function _getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        // liquidity = amount0 * sqrtRatioA * sqrtRatioB / (sqrtRatioB - sqrtRatioA) / 2^96
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        liquidity = uint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Compute liquidity from currency1 amount
    /// @dev Inverse of _getAmount1ForLiquidity
    /// @param sqrtRatioAX96 Lower sqrt price (Q64.96)
    /// @param sqrtRatioBX96 Upper sqrt price (Q64.96)
    /// @param amount1 Currency1 amount
    /// @return liquidity Computed liquidity
    function _getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        // liquidity = amount1 * 2^96 / (sqrtRatioB - sqrtRatioA)
        liquidity = uint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }
}
