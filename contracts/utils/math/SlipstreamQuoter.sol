// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SwapMath.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {BitMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/BitMath.sol";
import {LiquidityMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/LiquidityMath.sol";

/// @title SlipstreamQuoter
/// @notice View-based Aerodrome Slipstream (CL) swap quoting that can cross initialized ticks
/// @dev Mirrors the `CLPool.swap` loop, but only reads pool state
/// @dev Slipstream is a Uniswap V3 fork, so the core swap math is identical
library SlipstreamQuoter {
    struct SwapQuoteParams {
        ICLPool pool;
        bool zeroForOne;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
        uint32 maxSteps; // 0 == unlimited
    }

    struct SwapQuoteResult {
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
        uint160 sqrtPriceAfterX96;
        int24 tickAfter;
        uint128 liquidityAfter;
        bool fullyFilled;
        uint32 steps;
    }

    struct _StepComputations {
        uint160 sqrtPriceStartX96;
        int24 tickNext;
        bool initialized;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
    }

    struct _SwapState {
        int256 amountSpecifiedRemaining;
        int256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
    }

    function quoteExactInput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, true);
    }

    function quoteExactOutput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, false);
    }

    function _quote(SwapQuoteParams memory p, bool exactInput) private view returns (SwapQuoteResult memory r) {
        ICLPool pool = p.pool;

        if (p.amount == 0) {
            r.fullyFilled = true;
            (r.sqrtPriceAfterX96, r.tickAfter, , , , ) = pool.slot0();
            r.liquidityAfter = pool.liquidity();
            return r;
        }

        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();
        require(sqrtPriceX96 != 0, "SL:UNINIT");

        _requireValidSqrtPriceLimit(p.zeroForOne, p.sqrtPriceLimitX96, sqrtPriceX96);

        int24 tickSpacing = pool.tickSpacing();
        uint24 fee = pool.fee();

        _SwapState memory state = _SwapState({
            amountSpecifiedRemaining: exactInput ? int256(p.amount) : -int256(p.amount),
            amountCalculated: 0,
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            liquidity: pool.liquidity()
        });

        uint256 feeAmountTotal = 0;
        uint32 steps = 0;

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != p.sqrtPriceLimitX96) {
            if (p.maxSteps != 0 && steps >= p.maxSteps) break;
            steps++;

            _StepComputations memory step;
            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = _nextInitializedTickWithinOneWordView(
                pool,
                state.tick,
                tickSpacing,
                p.zeroForOne
            );

            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            uint160 sqrtPriceTargetX96;
            if (p.zeroForOne) {
                sqrtPriceTargetX96 = step.sqrtPriceNextX96 < p.sqrtPriceLimitX96 ? p.sqrtPriceLimitX96 : step.sqrtPriceNextX96;
            } else {
                sqrtPriceTargetX96 = step.sqrtPriceNextX96 > p.sqrtPriceLimitX96 ? p.sqrtPriceLimitX96 : step.sqrtPriceNextX96;
            }

            (sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                sqrtPriceTargetX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );

            state.sqrtPriceX96 = sqrtPriceX96;

            feeAmountTotal += step.feeAmount;

            if (exactInput) {
                state.amountSpecifiedRemaining -= int256(step.amountIn + step.feeAmount);
                state.amountCalculated -= int256(step.amountOut);
            } else {
                state.amountSpecifiedRemaining += int256(step.amountOut);
                state.amountCalculated += int256(step.amountIn + step.feeAmount);
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    // Slipstream ticks() returns different struct than Uniswap V3
                    // We only need liquidityNet for swap calculations
                    (, int128 liquidityNet, , , , , , , , ) = pool.ticks(step.tickNext);
                    if (p.zeroForOne) liquidityNet = -liquidityNet;
                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
                }

                state.tick = p.zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        r.steps = steps;
        r.feeAmount = feeAmountTotal;
        r.sqrtPriceAfterX96 = state.sqrtPriceX96;
        r.tickAfter = state.tick;
        r.liquidityAfter = state.liquidity;
        r.fullyFilled = state.amountSpecifiedRemaining == 0;

        if (exactInput) {
            r.amountIn = uint256(int256(p.amount) - state.amountSpecifiedRemaining);
            r.amountOut = uint256(-state.amountCalculated);
        } else {
            // amountSpecifiedRemaining starts at -amountOut and increases toward 0 as output is filled
            r.amountOut = uint256(int256(p.amount) + state.amountSpecifiedRemaining);
            r.amountIn = uint256(state.amountCalculated);
        }
    }

    function _requireValidSqrtPriceLimit(
        bool zeroForOne,
        uint160 sqrtPriceLimitX96,
        uint160 sqrtPriceX96
    ) private pure {
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "SL:SPL"
        );
    }

    function _nextInitializedTickWithinOneWordView(
        ICLPool pool,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) private view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = _position(compressed);
            uint256 word = pool.tickBitmap(wordPos);

            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = word & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            (int16 wordPos, uint8 bitPos) = _position(compressed + 1);
            uint256 word = pool.tickBitmap(wordPos);

            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = word & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
        }
    }

    function _position(int24 tickCompressed) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tickCompressed >> 8);
        bitPos = uint8(uint24(tickCompressed % 256));
    }
}
