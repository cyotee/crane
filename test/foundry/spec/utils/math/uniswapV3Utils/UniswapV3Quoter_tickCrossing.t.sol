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
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 0
        });

        UniswapV3Quoter.SwapQuoteResult memory q = UniswapV3Quoter.quoteExactInput(p);

        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        assertTrue(q.fullyFilled, "quote should fully fill");
        assertEq(q.amountIn, amountIn, "quoted input mismatch");
        assertApproxEqAbs(q.amountOut, actualOut, 1, "quoted output mismatch");
    }

    function test_quoteExactInput_maxSteps_stopsEarly() public {
        uint256 amountIn = 100e18;

        UniswapV3Quoter.SwapQuoteParams memory p = UniswapV3Quoter.SwapQuoteParams({
            pool: pool,
            zeroForOne: true,
            amount: amountIn,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1,
            maxSteps: 1
        });

        UniswapV3Quoter.SwapQuoteResult memory q = UniswapV3Quoter.quoteExactInput(p);

        assertEq(q.steps, 1, "expected 1 step");
        assertTrue(!q.fullyFilled, "should not fully fill with maxSteps=1");
    }
}
