// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {SlipstreamQuoter} from "./SlipstreamQuoter.sol";
import {SlipstreamUtils} from "./SlipstreamUtils.sol";

/// @title SlipstreamZapQuoter
/// @notice Quoting library for Aerodrome Slipstream (CL) zap operations (zap-in and zap-out)
/// @dev Zap-in: single-sided liquidity provision with binary search optimization
/// @dev Zap-out: burn liquidity and optionally swap to single token output
/// @dev Supports unstaked fee: set `includeUnstakedFee` to true when quoting for unstaked positions.
library SlipstreamZapQuoter {
    using SlipstreamQuoter for SlipstreamQuoter.SwapQuoteParams;
    using SlipstreamUtils for *;

    /* -------------------------------------------------------------------------- */
    /*                              Zap-In Structs                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for zap-in quote
    struct ZapInParams {
        ICLPool pool;
        int24 tickLower;
        int24 tickUpper;
        bool zeroForOne;       // true if input is token0, false if token1
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
        uint32 maxSwapSteps;   // 0 == unlimited
        uint16 searchIters;    // binary search iterations (e.g., 16-24)
        bool includeUnstakedFee; // When true, adds pool.unstakedFee() to the swap fee
    }

    /// @notice Result of zap-in quote
    struct ZapInQuote {
        uint256 swapAmountIn;  // Amount of input token to swap
        uint256 amount0;       // Amount of token0 for minting (after swap)
        uint256 amount1;       // Amount of token1 for minting (after swap)
        uint128 liquidity;     // Liquidity that can be minted
        uint256 dust0;         // Leftover token0 after mint
        uint256 dust1;         // Leftover token1 after mint
        SlipstreamQuoter.SwapQuoteResult swap;  // Swap quote details
    }

    /// @notice Execution params for pool-native zap (swap + mint directly on pool)
    struct PoolZapInExecution {
        bool zeroForOne;
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    /// @notice Execution params for position manager zap (via NFT position manager)
    struct PositionManagerZapInExecution {
        bool zeroForOne;
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zap-Out Structs                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for zap-out quote
    struct ZapOutParams {
        ICLPool pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bool wantToken0;           // true if output is token0, false if token1
        uint160 sqrtPriceLimitX96;
        uint32 maxSwapSteps;       // 0 == unlimited
        bool includeUnstakedFee;   // When true, adds pool.unstakedFee() to the swap fee
    }

    /// @notice Result of zap-out quote
    struct ZapOutQuote {
        uint256 burnAmount0;       // Amount of token0 received from burn
        uint256 burnAmount1;       // Amount of token1 received from burn
        uint256 swapAmountIn;      // Amount to swap (of unwanted token)
        uint256 amountOut;         // Total output amount (wanted token)
        uint256 dust;              // Leftover of unwanted token (if swap not fully filled)
        SlipstreamQuoter.SwapQuoteResult swap;  // Swap quote details
    }

    /// @notice Execution params for pool-native zap-out (burn + swap directly on pool)
    struct PoolZapOutExecution {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bool zeroForOne;           // Direction of swap (after burn)
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Execution params for position manager zap-out (via NFT position manager)
    struct PositionManagerZapOutExecution {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bool zeroForOne;           // Direction of swap (after burn)
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zap-In Core                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote a zap-in operation (single-sided liquidity provision)
    /// @dev Uses binary search to find optimal swap amount that maximizes liquidity
    /// @param p Zap-in parameters
    /// @return q Zap-in quote result
    function quoteZapInSingleCore(ZapInParams memory p) internal view returns (ZapInQuote memory q) {
        require(p.amountIn > 0, "SLZQ:ZERO_AMOUNT");
        require(p.tickLower < p.tickUpper, "SLZQ:INVALID_RANGE");

        // Get current pool state
        (uint160 sqrtPriceX96, , , , , ) = p.pool.slot0();

        // Set default price limit if not specified
        if (p.sqrtPriceLimitX96 == 0) {
            p.sqrtPriceLimitX96 = p.zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1;
        }

        // Binary search for optimal swap amount
        uint256 low = 0;
        uint256 high = p.amountIn;
        uint16 iterations = p.searchIters > 0 ? p.searchIters : 20;  // Default 20 iterations

        uint128 bestLiquidity = 0;
        uint256 bestSwapAmount = 0;
        ZapInQuote memory bestQuote;

        for (uint16 i = 0; i < iterations; i++) {
            uint256 mid = (low + high) / 2;

            ZapInQuote memory candidate = _evaluateSwapAmount(p, sqrtPriceX96, mid);

            if (candidate.liquidity > bestLiquidity) {
                bestLiquidity = candidate.liquidity;
                bestSwapAmount = mid;
                bestQuote = candidate;
            }

            // Determine search direction based on which token is limiting
            // If we have excess of the swapped-to token, swap less; if excess of input, swap more
            if (p.zeroForOne) {
                // Swapping token0 -> token1
                // After swap: have (amountIn - swapAmount) of token0, and swapOut of token1
                if (candidate.dust0 > candidate.dust1) {
                    // More token0 dust -> swap more token0
                    low = mid + 1;
                } else {
                    // More token1 dust -> swap less
                    high = mid > 0 ? mid - 1 : 0;
                }
            } else {
                // Swapping token1 -> token0
                // After swap: have swapOut of token0, and (amountIn - swapAmount) of token1
                if (candidate.dust1 > candidate.dust0) {
                    // More token1 dust -> swap more token1
                    low = mid + 1;
                } else {
                    // More token0 dust -> swap less
                    high = mid > 0 ? mid - 1 : 0;
                }
            }

            if (low > high) break;
        }

        // Refine around best found value
        // Check neighbors to ensure we have the true optimum
        if (bestSwapAmount > 0) {
            ZapInQuote memory lower = _evaluateSwapAmount(p, sqrtPriceX96, bestSwapAmount - 1);
            if (lower.liquidity > bestLiquidity) {
                bestLiquidity = lower.liquidity;
                bestSwapAmount = bestSwapAmount - 1;
                bestQuote = lower;
            }
        }
        if (bestSwapAmount < p.amountIn) {
            ZapInQuote memory upper = _evaluateSwapAmount(p, sqrtPriceX96, bestSwapAmount + 1);
            if (upper.liquidity > bestLiquidity) {
                bestQuote = upper;
            }
        }

        return bestQuote;
    }

    /// @notice Evaluate liquidity for a given swap amount
    function _evaluateSwapAmount(
        ZapInParams memory p,
        uint160 sqrtPriceX96,
        uint256 swapAmount
    ) private view returns (ZapInQuote memory q) {
        q.swapAmountIn = swapAmount;

        if (swapAmount == 0) {
            // No swap - use all input as single token
            if (p.zeroForOne) {
                q.amount0 = p.amountIn;
                q.amount1 = 0;
            } else {
                q.amount0 = 0;
                q.amount1 = p.amountIn;
            }
            q.swap = SlipstreamQuoter.SwapQuoteResult({
                amountIn: 0,
                amountOut: 0,
                feeAmount: 0,
                sqrtPriceAfterX96: sqrtPriceX96,
                tickAfter: 0,
                liquidityAfter: 0,
                fullyFilled: true,
                steps: 0
            });
        } else {
            // Quote the swap
            SlipstreamQuoter.SwapQuoteParams memory swapParams = SlipstreamQuoter.SwapQuoteParams({
                pool: p.pool,
                zeroForOne: p.zeroForOne,
                amount: swapAmount,
                sqrtPriceLimitX96: p.sqrtPriceLimitX96,
                maxSteps: p.maxSwapSteps,
                includeUnstakedFee: p.includeUnstakedFee
            });

            q.swap = SlipstreamQuoter.quoteExactInput(swapParams);

            // Calculate token amounts after swap
            uint256 remainingInput = p.amountIn - q.swap.amountIn;
            uint256 swapOutput = q.swap.amountOut;

            if (p.zeroForOne) {
                // Input is token0, swapped some to get token1
                q.amount0 = remainingInput;
                q.amount1 = swapOutput;
            } else {
                // Input is token1, swapped some to get token0
                q.amount0 = swapOutput;
                q.amount1 = remainingInput;
            }
        }

        // Use the post-swap price for liquidity calculation
        uint160 priceForMint = swapAmount > 0 ? q.swap.sqrtPriceAfterX96 : sqrtPriceX96;

        // Calculate max liquidity from available amounts
        q.liquidity = SlipstreamUtils._quoteLiquidityForAmounts(
            priceForMint,
            p.tickLower,
            p.tickUpper,
            q.amount0,
            q.amount1
        );

        // Calculate amounts actually used for minting
        (uint256 used0, uint256 used1) = SlipstreamUtils._quoteAmountsForLiquidity(
            priceForMint,
            p.tickLower,
            p.tickUpper,
            q.liquidity
        );

        // Calculate dust (leftover tokens)
        q.dust0 = q.amount0 > used0 ? q.amount0 - used0 : 0;
        q.dust1 = q.amount1 > used1 ? q.amount1 - used1 : 0;

        // Update amounts to reflect what's actually used
        q.amount0 = used0;
        q.amount1 = used1;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zap-In Wrappers                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote zap-in and return pool-native execution params
    /// @param p Zap-in parameters
    /// @return e Execution params for direct pool swap + mint
    function quoteZapInPool(ZapInParams memory p) internal view returns (PoolZapInExecution memory e) {
        ZapInQuote memory q = quoteZapInSingleCore(p);

        e.zeroForOne = p.zeroForOne;
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96;
        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.liquidity = q.liquidity;
        e.amount0 = q.amount0;
        e.amount1 = q.amount1;
    }

    /// @notice Quote zap-in and return position manager execution params
    /// @param p Zap-in parameters
    /// @return e Execution params for NFT position manager
    function quoteZapInPositionManager(ZapInParams memory p) internal view returns (PositionManagerZapInExecution memory e) {
        ZapInQuote memory q = quoteZapInSingleCore(p);

        e.zeroForOne = p.zeroForOne;
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96;
        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.amount0Desired = q.amount0;
        e.amount1Desired = q.amount1;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Helper: Create ZapInParams                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Create ZapInParams from token address
    /// @dev Determines zeroForOne based on whether tokenIn is token0 or token1
    /// @dev For backwards compatibility, this overload defaults includeUnstakedFee to false
    function createZapInParams(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        address tokenIn,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        uint32 maxSwapSteps,
        uint16 searchIters
    ) internal view returns (ZapInParams memory p) {
        return createZapInParams(pool, tickLower, tickUpper, tokenIn, amountIn, sqrtPriceLimitX96, maxSwapSteps, searchIters, false);
    }

    /// @notice Create ZapInParams from token address with unstaked fee support
    /// @dev Determines zeroForOne based on whether tokenIn is token0 or token1
    /// @param pool The Slipstream pool
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param tokenIn Input token address
    /// @param amountIn Amount of input token
    /// @param sqrtPriceLimitX96 Price limit for the swap
    /// @param maxSwapSteps Maximum swap steps
    /// @param searchIters Binary search iterations
    /// @param includeUnstakedFee When true, adds pool.unstakedFee() to the swap fee
    function createZapInParams(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        address tokenIn,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        uint32 maxSwapSteps,
        uint16 searchIters,
        bool includeUnstakedFee
    ) internal view returns (ZapInParams memory p) {
        address token0 = pool.token0();
        address token1 = pool.token1();

        require(tokenIn == token0 || tokenIn == token1, "SLZQ:INVALID_TOKEN");

        p.pool = pool;
        p.tickLower = tickLower;
        p.tickUpper = tickUpper;
        p.zeroForOne = tokenIn == token0;
        p.amountIn = amountIn;
        p.sqrtPriceLimitX96 = sqrtPriceLimitX96;
        p.maxSwapSteps = maxSwapSteps;
        p.searchIters = searchIters;
        p.includeUnstakedFee = includeUnstakedFee;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zap-Out Core                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote a zap-out operation (burn liquidity -> single token output)
    /// @dev Burns liquidity to get token0 and token1, then swaps unwanted token to wanted token
    /// @param p Zap-out parameters
    /// @return q Zap-out quote result
    function quoteZapOutSingleCore(ZapOutParams memory p) internal view returns (ZapOutQuote memory q) {
        require(p.liquidity > 0, "SLZQ:ZERO_LIQUIDITY");
        require(p.tickLower < p.tickUpper, "SLZQ:INVALID_RANGE");

        // Get current pool state
        (uint160 sqrtPriceX96, , , , , ) = p.pool.slot0();

        // Calculate amounts received from burning liquidity
        (q.burnAmount0, q.burnAmount1) = SlipstreamUtils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            p.tickLower,
            p.tickUpper,
            p.liquidity
        );

        // Determine swap direction: swap the unwanted token to get more of the wanted token
        // If wantToken0: swap token1 -> token0 (zeroForOne = false)
        // If wantToken1: swap token0 -> token1 (zeroForOne = true)
        bool zeroForOne = !p.wantToken0;

        // Amount to swap (all of the unwanted token)
        q.swapAmountIn = p.wantToken0 ? q.burnAmount1 : q.burnAmount0;

        if (q.swapAmountIn == 0) {
            // No swap needed - all output is already in the wanted token
            q.amountOut = p.wantToken0 ? q.burnAmount0 : q.burnAmount1;
            q.dust = 0;
            q.swap = SlipstreamQuoter.SwapQuoteResult({
                amountIn: 0,
                amountOut: 0,
                feeAmount: 0,
                sqrtPriceAfterX96: sqrtPriceX96,
                tickAfter: 0,
                liquidityAfter: 0,
                fullyFilled: true,
                steps: 0
            });
            return q;
        }

        // Set default price limit if not specified
        uint160 sqrtPriceLimitX96 = p.sqrtPriceLimitX96;
        if (sqrtPriceLimitX96 == 0) {
            sqrtPriceLimitX96 = zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1;
        }

        // Quote the swap
        SlipstreamQuoter.SwapQuoteParams memory swapParams = SlipstreamQuoter.SwapQuoteParams({
            pool: p.pool,
            zeroForOne: zeroForOne,
            amount: q.swapAmountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: p.maxSwapSteps,
            includeUnstakedFee: p.includeUnstakedFee
        });

        q.swap = SlipstreamQuoter.quoteExactInput(swapParams);

        // Calculate total output: original wanted amount + swap output
        uint256 originalWantedAmount = p.wantToken0 ? q.burnAmount0 : q.burnAmount1;
        q.amountOut = originalWantedAmount + q.swap.amountOut;

        // Dust is any unwanted token that couldn't be swapped (if swap wasn't fully filled)
        q.dust = q.swapAmountIn > q.swap.amountIn ? q.swapAmountIn - q.swap.amountIn : 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zap-Out Wrappers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote zap-out and return pool-native execution params
    /// @param p Zap-out parameters
    /// @return e Execution params for direct pool burn + swap
    function quoteZapOutPool(ZapOutParams memory p) internal view returns (PoolZapOutExecution memory e) {
        ZapOutQuote memory q = quoteZapOutSingleCore(p);

        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.liquidity = p.liquidity;
        e.zeroForOne = !p.wantToken0;  // Swap direction: opposite of wanted token
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96 != 0
            ? p.sqrtPriceLimitX96
            : (e.zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1);
    }

    /// @notice Quote zap-out and return position manager execution params
    /// @param p Zap-out parameters
    /// @return e Execution params for NFT position manager
    function quoteZapOutPositionManager(ZapOutParams memory p) internal view returns (PositionManagerZapOutExecution memory e) {
        ZapOutQuote memory q = quoteZapOutSingleCore(p);

        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.liquidity = p.liquidity;
        e.zeroForOne = !p.wantToken0;  // Swap direction: opposite of wanted token
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96 != 0
            ? p.sqrtPriceLimitX96
            : (e.zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Helper: Create ZapOutParams                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Create ZapOutParams from token address
    /// @dev Determines wantToken0 based on whether tokenOut is token0 or token1
    /// @dev For backwards compatibility, this overload defaults includeUnstakedFee to false
    function createZapOutParams(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address tokenOut,
        uint160 sqrtPriceLimitX96,
        uint32 maxSwapSteps
    ) internal view returns (ZapOutParams memory p) {
        return createZapOutParams(pool, tickLower, tickUpper, liquidity, tokenOut, sqrtPriceLimitX96, maxSwapSteps, false);
    }

    /// @notice Create ZapOutParams from token address with unstaked fee support
    /// @dev Determines wantToken0 based on whether tokenOut is token0 or token1
    /// @param pool The Slipstream pool
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity Amount of liquidity to burn
    /// @param tokenOut Desired output token address
    /// @param sqrtPriceLimitX96 Price limit for the swap
    /// @param maxSwapSteps Maximum swap steps
    /// @param includeUnstakedFee When true, adds pool.unstakedFee() to the swap fee
    function createZapOutParams(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address tokenOut,
        uint160 sqrtPriceLimitX96,
        uint32 maxSwapSteps,
        bool includeUnstakedFee
    ) internal view returns (ZapOutParams memory p) {
        address token0 = pool.token0();
        address token1 = pool.token1();

        require(tokenOut == token0 || tokenOut == token1, "SLZQ:INVALID_TOKEN");

        p.pool = pool;
        p.tickLower = tickLower;
        p.tickUpper = tickUpper;
        p.liquidity = liquidity;
        p.wantToken0 = tokenOut == token0;
        p.sqrtPriceLimitX96 = sqrtPriceLimitX96;
        p.maxSwapSteps = maxSwapSteps;
        p.includeUnstakedFee = includeUnstakedFee;
    }
}
