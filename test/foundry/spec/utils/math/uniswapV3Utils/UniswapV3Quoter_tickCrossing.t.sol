// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {UniswapV3Quoter} from "@crane/contracts/utils/math/UniswapV3Quoter.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {MockERC20} from "./UniswapV3Utils_quoteExactInput.t.sol";

/// @title Tick-crossing quote tests for UniswapV3Quoter
/// @notice Validates view-based tick-crossing quotes against actual pool swap execution.
contract UniswapV3Quoter_tickCrossing_Test is TestBase_UniswapV3 {
    using UniswapV3Quoter for UniswapV3Quoter.SwapQuoteParams;

    IUniswapV3Pool pool;

    function setUp() public override {
        super.setUp();

        address tokenA = address(new MockERC20("Token A", "TKNA", 18));
        address tokenB = address(new MockERC20("Token B", "TKNB", 18));

        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);

        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Wide baseline liquidity
        mintPosition(
            pool,
            address(this),
            nearestUsableTick(-60000, tickSpacing),
            nearestUsableTick(60000, tickSpacing),
            uint128(5_000e18)
        );

        // Narrow position that initializes tick 0; crossing it should change liquidity
        mintPosition(pool, address(this), 0, 600, uint128(2_500e18));
    }

    function test_quoteExactInput_tickCrossing_matchesActualSwap() public {
        uint256 amountIn = 100e18;

        UniswapV3Quoter.SwapQuoteParams memory p = UniswapV3Quoter.SwapQuoteParams({
            pool: pool, zeroForOne: true, amount: amountIn, sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1, maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory q = UniswapV3Quoter.quoteExactInput(p);

        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(q.fullyFilled, "quote should fully fill");
        assertEq(q.amountIn, amountIn, "quoted input mismatch");
        assertApproxEqAbs(q.amountOut, actualOut, 1, "quoted output mismatch");
    }

    function test_quoteExactInput_maxSteps_stopsEarly() public view {
        uint256 amountIn = 100e18;

        UniswapV3Quoter.SwapQuoteParams memory p = UniswapV3Quoter.SwapQuoteParams({
            pool: pool, zeroForOne: true, amount: amountIn, sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1, maxSteps: 1
        });

        UniswapV3Quoter.SwapQuoteResult memory q = UniswapV3Quoter.quoteExactInput(p);

        assertEq(q.steps, 1, "expected 1 step");
        assertTrue(!q.fullyFilled, "should not fully fill with maxSteps=1");
    }

    function testFuzz_quoteAfterLiquidityRemoval_matchesPool(bool zeroForOne, bool fullRemoval, bool exactOutput)
        public
    {
        uint128 removed = fullRemoval ? uint128(2_500e18) : uint128(1_250e18);
        UniswapV3Quoter.SwapQuoteParams memory p = UniswapV3Quoter.SwapQuoteParams({
            pool: pool, zeroForOne: zeroForOne, amount: 400e18,
            sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            maxSteps: 0
        });
        UniswapV3Quoter.LiquidityChange memory change = UniswapV3Quoter.LiquidityChange({
            tickLower: 0, tickUpper: 600, liquidityDelta: -int128(removed)
        });
        UniswapV3Quoter.SwapQuoteResult memory q = exactOutput
            ? UniswapV3Quoter.quoteExactOutputAfterLiquidityChange(p, change)
            : UniswapV3Quoter.quoteExactInputAfterLiquidityChange(p, change);
        pool.burn(0, 600, removed);
        _mintOrDeal(zeroForOne ? pool.token0() : pool.token1(), address(this), 1_000_000e18);
        (int256 amount0, int256 amount1) = pool.swap(
            address(this), zeroForOne, exactOutput ? -int256(p.amount) : int256(p.amount),
            p.sqrtPriceLimitX96, abi.encode(address(this))
        );
        assertTrue(q.fullyFilled);
        assertEq(q.amountIn, uint256(zeroForOne ? amount0 : amount1));
        assertEq(q.amountOut, uint256(-(zeroForOne ? amount1 : amount0)));
        (uint160 price, int24 tick,,,,,) = pool.slot0();
        assertEq(q.sqrtPriceAfterX96, price);
        assertEq(q.tickAfter, tick);
        assertEq(q.liquidityAfter, pool.liquidity());
    }
    function test_projectedSequence_crossesBothPositionBounds_andAccountsForProtocolFees() public {
        pool.setFeeProtocol(4, 5);
        UniswapV3Quoter.LiquidityChange memory change = UniswapV3Quoter.LiquidityChange(0, 600, -int128(1_250e18));
        UniswapV3Quoter.SwapQuoteParams memory p = UniswapV3Quoter.SwapQuoteParams({
            pool: pool, zeroForOne: false, amount: 400e18,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1, maxSteps: 0
        });
        (UniswapV3Quoter.SwapQuoteResult memory first, uint256 growth1) = UniswapV3Quoter.quoteFromState(
            p, true, change, UniswapV3Quoter.PoolState(0, 0, 0), true
        );
        p.zeroForOne = true;
        p.sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (UniswapV3Quoter.SwapQuoteResult memory second, uint256 growth0) = UniswapV3Quoter.quoteFromState(
            p, true, change,
            UniswapV3Quoter.PoolState(first.sqrtPriceAfterX96, first.tickAfter, first.liquidityAfter), true
        );
        assertGt(first.tickAfter, 600);
        assertLt(second.tickAfter, 0);
        pool.burn(0, 600, 1_250e18);
        assertEq(swapExactInput(pool, false, 400e18, address(this)), first.amountOut);
        assertEq(swapExactInput(pool, true, 400e18, address(this)), second.amountOut);
        (uint160 price, int24 tick,,,,,) = pool.slot0();
        assertEq(price, second.sqrtPriceAfterX96);
        assertEq(tick, second.tickAfter);
        assertEq(pool.liquidity(), second.liquidityAfter);
        pool.burn(0, 600, 0);
        (, uint256 actualGrowth0, uint256 actualGrowth1,,) = pool.positions(keccak256(abi.encodePacked(address(this), int24(0), int24(600))));
        assertEq(growth0, actualGrowth0);
        assertEq(growth1, actualGrowth1);
    }
}
