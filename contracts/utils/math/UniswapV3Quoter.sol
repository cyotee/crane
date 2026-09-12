// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SwapMath.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {BitMath} from "@crane/contracts/protocols/dexes/uniswap/libraries/BitMath.sol";
import {LiquidityMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/LiquidityMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/libraries/FullMath.sol";

/// @title UniswapV3Quoter
/// @notice View-based Uniswap V3 swap quoting that can cross initialized ticks.
/// @dev Mirrors the `UniswapV3Pool.swap` loop, but only reads pool state.
library UniswapV3Quoter {
    struct SwapQuoteParams {
        IUniswapV3Pool pool;
        bool zeroForOne;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
        uint32 maxSteps; // 0 == unlimited
    }

    struct LiquidityChange {
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
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

    struct PoolState {
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
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

    struct _QuoteContext {
        IUniswapV3Pool pool;
        bool zeroForOne;
        bool exactInput;
        int24 tickSpacing;
        uint24 fee;
        uint160 limit;
        LiquidityChange change;
        uint8 protocolFee;
        bool trackInsideFees;
    }

    struct _SwapState {
        int256 amountSpecifiedRemaining;
        int256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
        uint256 feeAmountTotal;
        uint32 steps;
        uint256 feeGrowthInsideX128;
    }

    function quoteExactInput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, true, LiquidityChange(0, 0, 0));
    }

    function quoteExactOutput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, false, LiquidityChange(0, 0, 0));
    }

    function quoteExactInputAfterLiquidityChange(SwapQuoteParams memory p, LiquidityChange memory change)
        internal view returns (SwapQuoteResult memory r)
    {
        return _quote(p, true, change);
    }

    function quoteExactOutputAfterLiquidityChange(SwapQuoteParams memory p, LiquidityChange memory change)
        internal view returns (SwapQuoteResult memory r)
    {
        return _quote(p, false, change);
    }

    function _quote(SwapQuoteParams memory p, bool exactInput, LiquidityChange memory change)
        private view returns (SwapQuoteResult memory r)
    {
        (r,) = quoteFromState(p, exactInput, change, PoolState(0, 0, 0), false);
    }

    /// @dev A nonzero starting price supplies the projected active liquidity;
    /// change remains the cumulative position change relative to onchain ticks.
    function quoteFromState(
        SwapQuoteParams memory p, bool exactInput, LiquidityChange memory change,
        PoolState memory starting, bool trackInsideFees
    ) internal view returns (SwapQuoteResult memory r, uint256 feeGrowthInsideX128) {
        (uint160 price, int24 tick,,,, uint8 protocolFee,) = p.pool.slot0();
        uint128 liquidity;
        if (starting.sqrtPriceX96 == 0) {
            liquidity = _changedLiquidity(p.pool.liquidity(), tick, change);
        } else {
            price = starting.sqrtPriceX96;
            tick = starting.tick;
            liquidity = starting.liquidity;
        }
        if (p.amount == 0) {
            r.fullyFilled = true;
            r.sqrtPriceAfterX96 = price;
            r.tickAfter = tick;
            r.liquidityAfter = liquidity;
            return (r, 0);
        }
        require(price != 0, "UNIV3:UNINIT");
        require(p.amount <= uint256(type(int256).max), "UNIV3:AMOUNT");
        _requireValidSqrtPriceLimit(p.zeroForOne, p.sqrtPriceLimitX96, price);
        _QuoteContext memory ctx = _QuoteContext({
            pool: p.pool, zeroForOne: p.zeroForOne, exactInput: exactInput,
            tickSpacing: p.pool.tickSpacing(), fee: p.pool.fee(), limit: p.sqrtPriceLimitX96, change: change,
            protocolFee: p.zeroForOne ? protocolFee & 0x0f : protocolFee >> 4,
            trackInsideFees: trackInsideFees
        });
        _SwapState memory state;
        state.amountSpecifiedRemaining = exactInput ? int256(p.amount) : -int256(p.amount);
        state.sqrtPriceX96 = price;
        state.tick = tick;
        state.liquidity = liquidity;
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != p.sqrtPriceLimitX96) {
            if (p.maxSteps != 0 && state.steps >= p.maxSteps) break;
            _processStep(ctx, state);
        }
        r.steps = state.steps;
        r.feeAmount = state.feeAmountTotal;
        r.sqrtPriceAfterX96 = state.sqrtPriceX96;
        r.tickAfter = state.tick;
        r.liquidityAfter = state.liquidity;
        r.fullyFilled = state.amountSpecifiedRemaining == 0;
        feeGrowthInsideX128 = state.feeGrowthInsideX128;
        if (exactInput) {
            r.amountIn = uint256(int256(p.amount) - state.amountSpecifiedRemaining);
            r.amountOut = uint256(-state.amountCalculated);
        } else {
            r.amountOut = uint256(int256(p.amount) + state.amountSpecifiedRemaining);
            r.amountIn = uint256(state.amountCalculated);
        }
    }

    function _processStep(_QuoteContext memory ctx, _SwapState memory state) private view {
        state.steps++;
        _StepComputations memory step;
        step.sqrtPriceStartX96 = state.sqrtPriceX96;
        (step.tickNext, step.initialized) = _nextInitializedTickWithinOneWordView(
            ctx.pool, state.tick, ctx.tickSpacing, ctx.zeroForOne, ctx.change
        );
        if (step.tickNext < TickMath.MIN_TICK) step.tickNext = TickMath.MIN_TICK;
        else if (step.tickNext > TickMath.MAX_TICK) step.tickNext = TickMath.MAX_TICK;
        step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);
        uint160 target = ctx.zeroForOne
            ? (step.sqrtPriceNextX96 < ctx.limit ? ctx.limit : step.sqrtPriceNextX96)
            : (step.sqrtPriceNextX96 > ctx.limit ? ctx.limit : step.sqrtPriceNextX96);
        (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
            state.sqrtPriceX96, target, state.liquidity, state.amountSpecifiedRemaining, ctx.fee
        );
        state.feeAmountTotal += step.feeAmount;
        if (ctx.trackInsideFees && state.liquidity != 0
            && state.tick >= ctx.change.tickLower && state.tick < ctx.change.tickUpper) {
            uint256 lpFee = step.feeAmount;
            if (ctx.protocolFee != 0) lpFee -= lpFee / ctx.protocolFee;
            unchecked {
                state.feeGrowthInsideX128 += FullMath.mulDiv(lpFee, uint256(1) << 128, state.liquidity);
            }
        }
        if (ctx.exactInput) {
            state.amountSpecifiedRemaining -= int256(step.amountIn + step.feeAmount);
            state.amountCalculated -= int256(step.amountOut);
        } else {
            state.amountSpecifiedRemaining += int256(step.amountOut);
            state.amountCalculated += int256(step.amountIn + step.feeAmount);
        }
        if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
            if (step.initialized) {
                (, int128 net,,,,,,) = ctx.pool.ticks(step.tickNext);
                if (step.tickNext == ctx.change.tickLower) net += ctx.change.liquidityDelta;
                if (step.tickNext == ctx.change.tickUpper) net -= ctx.change.liquidityDelta;
                if (ctx.zeroForOne) net = -net;
                state.liquidity = LiquidityMath.addDelta(state.liquidity, net);
            }
            state.tick = ctx.zeroForOne ? step.tickNext - 1 : step.tickNext;
        } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
            state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
        }
    }

    function _requireValidSqrtPriceLimit(bool zeroForOne, uint160 sqrtPriceLimitX96, uint160 sqrtPriceX96)
        private
        pure
    {
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "UNIV3:SPL"
        );
    }

    function _nextInitializedTickWithinOneWordView(IUniswapV3Pool pool, int24 tick, int24 tickSpacing, bool lte, LiquidityChange memory change)
        private
        view
        returns (int24 next, bool initialized)
    {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = _position(compressed);
            uint256 word = _changedBitmap(pool, wordPos, tickSpacing, change);

            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = word & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            (int16 wordPos, uint8 bitPos) = _position(compressed + 1);
            uint256 word = _changedBitmap(pool, wordPos, tickSpacing, change);

            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = word & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
        }
    }

    function _changedLiquidity(uint128 liquidity, int24 tick, LiquidityChange memory change) private pure returns (uint128) {
        if (tick >= change.tickLower && tick < change.tickUpper) return LiquidityMath.addDelta(liquidity, change.liquidityDelta);
        return liquidity;
    }

    function _changedBitmap(IUniswapV3Pool pool, int16 wordPos, int24 spacing, LiquidityChange memory change)
        private view returns (uint256 word)
    {
        word = pool.tickBitmap(wordPos);
        if (change.liquidityDelta == 0) return word;
        for (uint256 i; i < 2; ++i) {
            int24 tick = i == 0 ? change.tickLower : change.tickUpper;
            (int16 changedWord, uint8 bit) = _position(tick / spacing);
            if (changedWord != wordPos) continue;
            (uint128 gross,,,,,,,) = pool.ticks(tick);
            uint128 nextGross = LiquidityMath.addDelta(gross, change.liquidityDelta);
            if ((gross == 0) != (nextGross == 0)) word ^= uint256(1) << bit;
        }
    }

    function _position(int24 tickCompressed) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tickCompressed >> 8);
        bitPos = uint8(uint24(tickCompressed % 256));
    }
}
