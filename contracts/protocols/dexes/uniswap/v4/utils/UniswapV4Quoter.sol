// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {StateLibrary} from "../libraries/StateLibrary.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {SwapMath} from "../libraries/SwapMath.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {BitMath} from "@crane/contracts/protocols/dexes/uniswap/libraries/BitMath.sol";
import {ProtocolFeeLibrary} from "../libraries/ProtocolFeeLibrary.sol";
import {LiquidityMath} from "../libraries/LiquidityMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/libraries/FullMath.sol";

/// @title UniswapV4Quoter
/// @notice View-based Uniswap V4 swap quoting that can cross initialized ticks. IMPORTANT: For pools
///         with dynamic fees (FEE_DYNAMIC flag = 0x800000), quotes may differ from actual swap results
///         because hooks can modify fees at execution time. Use quotes from dynamic-fee pools as
///         estimates only.
/// @dev V4 Architecture Key Points:
///      - PoolManager is a singleton - pool state is read via extsload
///      - Pools are identified by PoolKey (currency0, currency1, fee, tickSpacing, hooks)
///      - Uses StateLibrary to read pool state without requiring unlock
///      - Mirrors the Pool.swap loop, but only reads pool state
/// @dev Dynamic Fee Pools: Pools can set the FEE_DYNAMIC flag (0x800000 in the fee field) to indicate
///      that hooks may override the LP fee during beforeSwap(). Since this library reads state without
///      executing hooks, the quoted fee may not match the actual fee charged at execution time.
/// @dev This library provides equivalent functionality to UniswapV3Quoter, adapted for V4's PoolManager architecture
library UniswapV4Quoter {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    /* -------------------------------------------------------------------------- */
    /*                              Structs                                       */
    /* -------------------------------------------------------------------------- */

    struct SwapQuoteParams {
        IPoolManager manager;
        PoolKey key;
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

    /// @dev Internal state for quote loop - includes context to reduce stack depth
    struct _QuoteContext {
        IPoolManager manager;
        PoolId poolId;
        bool zeroForOne;
        uint160 sqrtPriceLimitX96;
        int24 tickSpacing;
        uint24 lpFee;
        bool exactInput;
        uint32 maxSteps;
        LiquidityChange change;
        uint16 protocolFee;
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

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Quote an exact input swap. For dynamic fee pools (fee & 0x800000 != 0), treat results
    ///         as estimates since hooks can modify fees at execution time.
    /// @dev Dynamic fee pools: the actual fee charged during execution may differ from the quote
    ///      because hooks can override fees in beforeSwap().
    /// @param p Swap quote parameters
    /// @return r Swap quote result
    function quoteExactInput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, true, LiquidityChange(0, 0, 0));
    }

    /// @notice Quote an exact output swap. For dynamic fee pools (fee & 0x800000 != 0), treat results
    ///         as estimates since hooks can modify fees at execution time.
    /// @dev Dynamic fee pools: the actual fee charged during execution may differ from the quote
    ///      because hooks can override fees in beforeSwap().
    /// @param p Swap quote parameters
    /// @return r Swap quote result
    function quoteExactOutput(SwapQuoteParams memory p) internal view returns (SwapQuoteResult memory r) {
        return _quote(p, false, LiquidityChange(0, 0, 0));
    }

    /* -------------------------------------------------------------------------- */
    /*                              Core Quote Logic                              */
    /* -------------------------------------------------------------------------- */

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

    /// @dev Starting liquidity already includes the projected position change.
    /// The change overlay updates tick storage relative to the onchain book.
    function quoteFromState(
        SwapQuoteParams memory p, bool exactInput, LiquidityChange memory change,
        PoolState memory starting, bool trackInsideFees
    ) internal view returns (SwapQuoteResult memory r, uint256 feeGrowthInsideX128) {
        require(p.amount <= uint256(type(int256).max), "UNIV4:AMOUNT");
        _QuoteContext memory ctx;
        _SwapState memory state;
        _loadQuotePool(p, ctx, state);
        ctx.exactInput = exactInput;
        ctx.change = change;
        ctx.trackInsideFees = trackInsideFees;
        if (starting.sqrtPriceX96 != 0) {
            state.sqrtPriceX96 = starting.sqrtPriceX96;
            state.tick = starting.tick;
            state.liquidity = starting.liquidity;
        } else {
            state.liquidity = _changedLiquidity(state.liquidity, state.tick, change);
        }
        if (p.amount == 0) {
            r.fullyFilled = true;
            r.sqrtPriceAfterX96 = state.sqrtPriceX96;
            r.tickAfter = state.tick;
            r.liquidityAfter = state.liquidity;
            return (r, 0);
        }
        require(state.sqrtPriceX96 != 0, "UNIV4:UNINIT");
        _requireValidSqrtPriceLimit(p.zeroForOne, p.sqrtPriceLimitX96, state.sqrtPriceX96);
        state.amountSpecifiedRemaining = exactInput ? -int256(p.amount) : int256(p.amount);

        // Main quote loop
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != ctx.sqrtPriceLimitX96) {
            if (ctx.maxSteps != 0 && state.steps >= ctx.maxSteps) break;
            _processStep(ctx, state);
        }

        // Build result
        r.steps = state.steps;
        r.feeAmount = state.feeAmountTotal;
        r.sqrtPriceAfterX96 = state.sqrtPriceX96;
        r.tickAfter = state.tick;
        r.liquidityAfter = state.liquidity;
        r.fullyFilled = state.amountSpecifiedRemaining == 0;
        feeGrowthInsideX128 = state.feeGrowthInsideX128;

        if (exactInput) {
            r.amountIn = uint256(-(-int256(p.amount) - state.amountSpecifiedRemaining));
            r.amountOut = uint256(-state.amountCalculated);
        } else {
            r.amountOut = uint256(int256(p.amount) - state.amountSpecifiedRemaining);
            r.amountIn = uint256(state.amountCalculated);
        }
    }

    function _loadQuotePool(SwapQuoteParams memory p, _QuoteContext memory ctx, _SwapState memory state)
        private view
    {
        ctx.manager = p.manager;
        ctx.poolId = p.key.toId();
        ctx.zeroForOne = p.zeroForOne;
        ctx.sqrtPriceLimitX96 = p.sqrtPriceLimitX96;
        ctx.tickSpacing = p.key.tickSpacing;
        ctx.maxSteps = p.maxSteps;
        uint24 protocolFees;
        uint24 lpFee;
        (state.sqrtPriceX96, state.tick, protocolFees, lpFee) = p.manager.getSlot0(ctx.poolId);
        state.liquidity = p.manager.getLiquidity(ctx.poolId);
        ctx.protocolFee = p.zeroForOne
            ? ProtocolFeeLibrary.getZeroForOneFee(protocolFees) : ProtocolFeeLibrary.getOneForZeroFee(protocolFees);
        ctx.lpFee = ProtocolFeeLibrary.calculateSwapFee(ctx.protocolFee, lpFee);
    }

    function _creditInsideFees(_QuoteContext memory ctx, _SwapState memory state, uint256 amountIn, uint256 feeAmount)
        private pure
    {
        if (!ctx.trackInsideFees || state.liquidity == 0
            || state.tick < ctx.change.tickLower || state.tick >= ctx.change.tickUpper) return;
        if (ctx.protocolFee != 0) {
            feeAmount -= ctx.lpFee == ctx.protocolFee ? feeAmount
                : FullMath.mulDiv(amountIn + feeAmount, ctx.protocolFee, 1_000_000);
        }
        unchecked {
            state.feeGrowthInsideX128 += FullMath.mulDiv(feeAmount, uint256(1) << 128, state.liquidity);
        }
    }

    /// @dev Process a single step of the quote loop
    function _processStep(_QuoteContext memory ctx, _SwapState memory state) private view {
        state.steps++;
        uint160 sqrtPriceStartX96 = state.sqrtPriceX96;

        // Find next tick
        int24 tickNext;
        bool initialized;
        {
            (tickNext, initialized) = _nextInitializedTickWithinOneWordView(
                ctx.manager, ctx.poolId, state.tick, ctx.tickSpacing, ctx.zeroForOne, ctx.change
            );

            if (tickNext < TickMath.MIN_TICK) {
                tickNext = TickMath.MIN_TICK;
            } else if (tickNext > TickMath.MAX_TICK) {
                tickNext = TickMath.MAX_TICK;
            }
        }

        // Compute swap step
        uint160 sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(tickNext);
        uint160 sqrtPriceTargetX96 =
            SwapMath.getSqrtPriceTarget(ctx.zeroForOne, sqrtPriceNextX96, ctx.sqrtPriceLimitX96);

        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
        {
            uint160 newSqrtPriceX96;
            (newSqrtPriceX96, amountIn, amountOut, feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96, sqrtPriceTargetX96, state.liquidity, state.amountSpecifiedRemaining, ctx.lpFee
            );
            state.sqrtPriceX96 = newSqrtPriceX96;
        }

        state.feeAmountTotal += feeAmount;
        _creditInsideFees(ctx, state, amountIn, feeAmount);

        if (ctx.exactInput) {
            unchecked {
                state.amountSpecifiedRemaining += int256(amountIn + feeAmount);
                state.amountCalculated -= int256(amountOut);
            }
        } else {
            unchecked {
                state.amountSpecifiedRemaining -= int256(amountOut);
                state.amountCalculated += int256(amountIn + feeAmount);
            }
        }

        // Update tick if we reached next price
        if (state.sqrtPriceX96 == sqrtPriceNextX96) {
            if (initialized) {
                (, int128 liquidityNet,,) = ctx.manager.getTickInfo(ctx.poolId, tickNext);
                if (tickNext == ctx.change.tickLower) liquidityNet += ctx.change.liquidityDelta;
                if (tickNext == ctx.change.tickUpper) liquidityNet -= ctx.change.liquidityDelta;
                if (ctx.zeroForOne) liquidityNet = -liquidityNet;
                state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
            }
            state.tick = ctx.zeroForOne ? tickNext - 1 : tickNext;
        } else if (state.sqrtPriceX96 != sqrtPriceStartX96) {
            state.tick = TickMath.getTickAtSqrtPrice(state.sqrtPriceX96);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    function _requireValidSqrtPriceLimit(bool zeroForOne, uint160 sqrtPriceLimitX96, uint160 sqrtPriceX96)
        private
        pure
    {
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_PRICE
                : sqrtPriceLimitX96 > sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_PRICE,
            "UNIV4:SPL"
        );
    }

    /// @notice Find next initialized tick within one word using view functions
    /// @dev V4-specific: Uses StateLibrary to read tick bitmap via extsload
    function _nextInitializedTickWithinOneWordView(
        IPoolManager manager,
        PoolId poolId,
        int24 tick,
        int24 tickSpacing,
        bool lte,
        LiquidityChange memory change
    ) private view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;

        if (lte) {
            (int16 wordPos, uint8 bitPos) = _position(compressed);
            uint256 word = _changedBitmap(manager, poolId, wordPos, tickSpacing, change);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = word & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            (int16 wordPos, uint8 bitPos) = _position(compressed + 1);
            uint256 word = _changedBitmap(manager, poolId, wordPos, tickSpacing, change);
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

    function _changedBitmap(IPoolManager manager, PoolId poolId, int16 wordPos, int24 spacing, LiquidityChange memory change)
        private view returns (uint256 word)
    {
        word = manager.getTickBitmap(poolId, wordPos);
        if (change.liquidityDelta == 0) return word;
        for (uint256 i; i < 2; ++i) {
            int24 tick = i == 0 ? change.tickLower : change.tickUpper;
            (int16 changedWord, uint8 bit) = _position(tick / spacing);
            if (changedWord != wordPos) continue;
            (uint128 gross,,,) = manager.getTickInfo(poolId, tick);
            uint128 nextGross = LiquidityMath.addDelta(gross, change.liquidityDelta);
            if ((gross == 0) != (nextGross == 0)) word ^= uint256(1) << bit;
        }
    }

    function _position(int24 tickCompressed) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tickCompressed >> 8);
        bitPos = uint8(uint24(tickCompressed % 256));
    }
}
