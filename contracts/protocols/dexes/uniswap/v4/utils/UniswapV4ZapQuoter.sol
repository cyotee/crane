// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager, StateLibrary} from "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {UniswapV4Quoter} from "./UniswapV4Quoter.sol";
import {UniswapV4Utils} from "./UniswapV4Utils.sol";

/// @title UniswapV4ZapQuoter
/// @notice Quoting library for Uniswap V4 zap operations (zap-in and zap-out)
/// @dev V4 Architecture Key Points:
///      - PoolManager is a singleton - pool state is read via extsload
///      - Pools are identified by PoolKey (currency0, currency1, fee, tickSpacing, hooks)
///      - Uses StateLibrary to read pool state without requiring unlock
///      - Zap-in: single-sided liquidity provision with binary search optimization
///      - Zap-out: burn liquidity and optionally swap to single token output
/// @dev This library provides equivalent functionality to UniswapV3ZapQuoter, adapted for V4's PoolManager architecture
library UniswapV4ZapQuoter {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using UniswapV4Quoter for UniswapV4Quoter.SwapQuoteParams;

    /* -------------------------------------------------------------------------- */
    /*                              Zap-In Structs                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for zap-in quote
    /// @dev V4-specific: Uses IPoolManager and PoolKey instead of pool address
    struct ZapInParams {
        IPoolManager manager;
        PoolKey key;
        int24 tickLower;
        int24 tickUpper;
        bool zeroForOne;       // true if input is currency0, false if currency1
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
        uint32 maxSwapSteps;   // 0 == unlimited
        uint16 searchIters;    // binary search iterations (e.g., 16-24)
    }

    /// @notice Result of zap-in quote
    struct ZapInQuote {
        uint256 swapAmountIn;  // Amount of input currency to swap
        uint256 amount0;       // Amount of currency0 for minting (after swap)
        uint256 amount1;       // Amount of currency1 for minting (after swap)
        uint128 liquidity;     // Liquidity that can be minted
        uint256 dust0;         // Leftover currency0 after mint
        uint256 dust1;         // Leftover currency1 after mint
        UniswapV4Quoter.SwapQuoteResult swap;  // Swap quote details
    }

    /// @notice Execution params for V4 zap (swap + modifyLiquidity on PoolManager)
    /// @dev V4: Uses modifyLiquidity instead of mint, requires unlock callback
    struct PoolManagerZapInExecution {
        PoolKey key;
        bool zeroForOne;
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    /// @notice Execution params for position manager zap (via V4 PositionManager)
    /// @dev V4: Uses PositionManager for NFT-based positions
    struct PositionManagerZapInExecution {
        PoolKey key;
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
    /// @dev V4-specific: Uses IPoolManager and PoolKey instead of pool address
    struct ZapOutParams {
        IPoolManager manager;
        PoolKey key;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bool wantCurrency0;        // true if output is currency0, false if currency1
        uint160 sqrtPriceLimitX96;
        uint32 maxSwapSteps;       // 0 == unlimited
    }

    /// @notice Result of zap-out quote
    struct ZapOutQuote {
        uint256 burnAmount0;       // Amount of currency0 received from burn
        uint256 burnAmount1;       // Amount of currency1 received from burn
        uint256 swapAmountIn;      // Amount to swap (of unwanted currency)
        uint256 amountOut;         // Total output amount (wanted currency)
        uint256 dust;              // Leftover of unwanted currency (if swap not fully filled)
        UniswapV4Quoter.SwapQuoteResult swap;  // Swap quote details
    }

    /// @notice Execution params for V4 zap-out (modifyLiquidity + swap on PoolManager)
    /// @dev V4: Uses modifyLiquidity with negative liquidityDelta instead of burn
    struct PoolManagerZapOutExecution {
        PoolKey key;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bool zeroForOne;           // Direction of swap (after burn)
        uint256 swapAmountIn;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Execution params for position manager zap-out (via V4 PositionManager)
    /// @dev V4: Uses PositionManager for NFT-based position burns
    struct PositionManagerZapOutExecution {
        PoolKey key;
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
    /// @dev V4-specific: Reads pool state via StateLibrary.getSlot0()
    /// @param p Zap-in parameters
    /// @return q Zap-in quote result
    function quoteZapInSingleCore(ZapInParams memory p) internal view returns (ZapInQuote memory q) {
        require(p.amountIn > 0, "UNIV4ZAP:ZERO_AMOUNT");
        require(p.tickLower < p.tickUpper, "UNIV4ZAP:INVALID_RANGE");

        PoolId poolId = p.key.toId();

        // Get current pool state via StateLibrary (V4-specific: uses extsload)
        (uint160 sqrtPriceX96, , , ) = p.manager.getSlot0(poolId);
        require(sqrtPriceX96 != 0, "UNIV4ZAP:UNINIT");

        // Set default price limit if not specified
        if (p.sqrtPriceLimitX96 == 0) {
            p.sqrtPriceLimitX96 = p.zeroForOne
                ? TickMath.MIN_SQRT_PRICE + 1
                : TickMath.MAX_SQRT_PRICE - 1;
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

            // Determine search direction based on which currency is limiting
            // If we have excess of the swapped-to currency, swap less; if excess of input, swap more
            if (p.zeroForOne) {
                // Swapping currency0 → currency1
                // After swap: have (amountIn - swapAmount) of currency0, and swapOut of currency1
                if (candidate.dust0 > candidate.dust1) {
                    // More currency0 dust → swap more currency0
                    low = mid + 1;
                } else {
                    // More currency1 dust → swap less
                    high = mid > 0 ? mid - 1 : 0;
                }
            } else {
                // Swapping currency1 → currency0
                // After swap: have swapOut of currency0, and (amountIn - swapAmount) of currency1
                if (candidate.dust1 > candidate.dust0) {
                    // More currency1 dust → swap more currency1
                    low = mid + 1;
                } else {
                    // More currency0 dust → swap less
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
    /// @dev V4-specific: Uses UniswapV4Quoter and UniswapV4Utils
    function _evaluateSwapAmount(
        ZapInParams memory p,
        uint160 sqrtPriceX96,
        uint256 swapAmount
    ) private view returns (ZapInQuote memory q) {
        q.swapAmountIn = swapAmount;

        if (swapAmount == 0) {
            // No swap - use all input as single currency
            if (p.zeroForOne) {
                q.amount0 = p.amountIn;
                q.amount1 = 0;
            } else {
                q.amount0 = 0;
                q.amount1 = p.amountIn;
            }
            q.swap = UniswapV4Quoter.SwapQuoteResult({
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
            // Quote the swap using V4 quoter
            UniswapV4Quoter.SwapQuoteParams memory swapParams = UniswapV4Quoter.SwapQuoteParams({
                manager: p.manager,
                key: p.key,
                zeroForOne: p.zeroForOne,
                amount: swapAmount,
                sqrtPriceLimitX96: p.sqrtPriceLimitX96,
                maxSteps: p.maxSwapSteps
            });

            q.swap = UniswapV4Quoter.quoteExactInput(swapParams);

            // Calculate currency amounts after swap
            uint256 remainingInput = p.amountIn - q.swap.amountIn;
            uint256 swapOutput = q.swap.amountOut;

            if (p.zeroForOne) {
                // Input is currency0, swapped some to get currency1
                q.amount0 = remainingInput;
                q.amount1 = swapOutput;
            } else {
                // Input is currency1, swapped some to get currency0
                q.amount0 = swapOutput;
                q.amount1 = remainingInput;
            }
        }

        // Use the post-swap price for liquidity calculation
        uint160 priceForMint = swapAmount > 0 ? q.swap.sqrtPriceAfterX96 : sqrtPriceX96;

        // Calculate max liquidity from available amounts using V4 utils
        q.liquidity = UniswapV4Utils._quoteLiquidityForAmounts(
            priceForMint,
            p.tickLower,
            p.tickUpper,
            q.amount0,
            q.amount1
        );

        // Calculate amounts actually used for minting
        (uint256 used0, uint256 used1) = UniswapV4Utils._quoteAmountsForLiquidity(
            priceForMint,
            p.tickLower,
            p.tickUpper,
            q.liquidity
        );

        // Calculate dust (leftover currencies)
        q.dust0 = q.amount0 > used0 ? q.amount0 - used0 : 0;
        q.dust1 = q.amount1 > used1 ? q.amount1 - used1 : 0;

        // Update amounts to reflect what's actually used
        q.amount0 = used0;
        q.amount1 = used1;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zap-In Wrappers                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote zap-in and return PoolManager execution params
    /// @dev V4: Returns params for direct PoolManager swap + modifyLiquidity
    /// @param p Zap-in parameters
    /// @return e Execution params for PoolManager operations
    function quoteZapInPoolManager(ZapInParams memory p) internal view returns (PoolManagerZapInExecution memory e) {
        ZapInQuote memory q = quoteZapInSingleCore(p);

        e.key = p.key;
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
    /// @dev V4: Returns params for PositionManager NFT-based operations
    /// @param p Zap-in parameters
    /// @return e Execution params for V4 PositionManager
    function quoteZapInPositionManager(ZapInParams memory p) internal view returns (PositionManagerZapInExecution memory e) {
        ZapInQuote memory q = quoteZapInSingleCore(p);

        e.key = p.key;
        e.zeroForOne = p.zeroForOne;
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96;
        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.amount0Desired = q.amount0;
        e.amount1Desired = q.amount1;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Zap-Out Core                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote a zap-out operation (burn liquidity → single currency output)
    /// @dev Burns liquidity to get currency0 and currency1, then swaps unwanted currency to wanted currency
    /// @dev V4-specific: Reads pool state via StateLibrary.getSlot0()
    /// @param p Zap-out parameters
    /// @return q Zap-out quote result
    function quoteZapOutSingleCore(ZapOutParams memory p) internal view returns (ZapOutQuote memory q) {
        require(p.liquidity > 0, "UNIV4ZAP:ZERO_LIQUIDITY");
        require(p.tickLower < p.tickUpper, "UNIV4ZAP:INVALID_RANGE");

        PoolId poolId = p.key.toId();

        // Get current pool state via StateLibrary (V4-specific: uses extsload)
        (uint160 sqrtPriceX96, , , ) = p.manager.getSlot0(poolId);
        require(sqrtPriceX96 != 0, "UNIV4ZAP:UNINIT");

        // Calculate amounts received from burning liquidity using V4 utils
        (q.burnAmount0, q.burnAmount1) = UniswapV4Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            p.tickLower,
            p.tickUpper,
            p.liquidity
        );

        // Determine swap direction: swap the unwanted currency to get more of the wanted currency
        // If wantCurrency0: swap currency1 → currency0 (zeroForOne = false)
        // If wantCurrency1: swap currency0 → currency1 (zeroForOne = true)
        bool zeroForOne = !p.wantCurrency0;

        // Amount to swap (all of the unwanted currency)
        q.swapAmountIn = p.wantCurrency0 ? q.burnAmount1 : q.burnAmount0;

        if (q.swapAmountIn == 0) {
            // No swap needed - all output is already in the wanted currency
            q.amountOut = p.wantCurrency0 ? q.burnAmount0 : q.burnAmount1;
            q.dust = 0;
            q.swap = UniswapV4Quoter.SwapQuoteResult({
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
                ? TickMath.MIN_SQRT_PRICE + 1
                : TickMath.MAX_SQRT_PRICE - 1;
        }

        // Quote the swap using V4 quoter
        UniswapV4Quoter.SwapQuoteParams memory swapParams = UniswapV4Quoter.SwapQuoteParams({
            manager: p.manager,
            key: p.key,
            zeroForOne: zeroForOne,
            amount: q.swapAmountIn,
            sqrtPriceLimitX96: sqrtPriceLimitX96,
            maxSteps: p.maxSwapSteps
        });

        q.swap = UniswapV4Quoter.quoteExactInput(swapParams);

        // Calculate total output: original wanted amount + swap output
        uint256 originalWantedAmount = p.wantCurrency0 ? q.burnAmount0 : q.burnAmount1;
        q.amountOut = originalWantedAmount + q.swap.amountOut;

        // Dust is any unwanted currency that couldn't be swapped (if swap wasn't fully filled)
        q.dust = q.swapAmountIn > q.swap.amountIn ? q.swapAmountIn - q.swap.amountIn : 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Zap-Out Wrappers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote zap-out and return PoolManager execution params
    /// @dev V4: Returns params for direct PoolManager modifyLiquidity + swap
    /// @param p Zap-out parameters
    /// @return e Execution params for PoolManager operations
    function quoteZapOutPoolManager(ZapOutParams memory p) internal view returns (PoolManagerZapOutExecution memory e) {
        ZapOutQuote memory q = quoteZapOutSingleCore(p);

        e.key = p.key;
        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.liquidity = p.liquidity;
        e.zeroForOne = !p.wantCurrency0;  // Swap direction: opposite of wanted currency
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96 != 0
            ? p.sqrtPriceLimitX96
            : (e.zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1);
    }

    /// @notice Quote zap-out and return position manager execution params
    /// @dev V4: Returns params for PositionManager NFT-based operations
    /// @param p Zap-out parameters
    /// @return e Execution params for V4 PositionManager
    function quoteZapOutPositionManager(ZapOutParams memory p) internal view returns (PositionManagerZapOutExecution memory e) {
        ZapOutQuote memory q = quoteZapOutSingleCore(p);

        e.key = p.key;
        e.tickLower = p.tickLower;
        e.tickUpper = p.tickUpper;
        e.liquidity = p.liquidity;
        e.zeroForOne = !p.wantCurrency0;  // Swap direction: opposite of wanted currency
        e.swapAmountIn = q.swapAmountIn;
        e.sqrtPriceLimitX96 = p.sqrtPriceLimitX96 != 0
            ? p.sqrtPriceLimitX96
            : (e.zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1);
    }
}
