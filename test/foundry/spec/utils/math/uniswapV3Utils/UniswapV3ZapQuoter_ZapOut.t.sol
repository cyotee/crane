// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3ZapQuoter} from "@crane/contracts/utils/math/UniswapV3ZapQuoter.sol";
import {UniswapV3Quoter} from "@crane/contracts/utils/math/UniswapV3Quoter.sol";
import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {MockERC20} from "./UniswapV3Utils_quoteExactInput.t.sol";

/// @title Test UniswapV3ZapQuoter zap-out functionality (Phase 4)
/// @notice Validates burn + swap to single token quoting
contract UniswapV3ZapQuoter_ZapOut_Test is TestBase_UniswapV3 {
    using UniswapV3ZapQuoter for *;
    using UniswapV3Utils for *;

    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;
    address token0;  // Actual token0 from pool (sorted)
    address token1;  // Actual token1 from pool (sorted)

    uint256 constant INITIAL_LIQUIDITY = 10_000e18;
    int24 tickLower;
    int24 tickUpper;

    function setUp() public override {
        super.setUp();

        // Create test tokens
        tokenA = address(new MockERC20("Token A", "TKNA", 18));
        tokenB = address(new MockERC20("Token B", "TKNB", 18));

        vm.label(tokenA, "TokenA");
        vm.label(tokenB, "TokenB");

        // Create pool with 0.3% fee at 1:1 price
        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);

        // Get actual token ordering from pool (pools sort by address)
        token0 = pool.token0();
        token1 = pool.token1();

        // Define tick range
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        tickLower = nearestUsableTick(-6000, tickSpacing);
        tickUpper = nearestUsableTick(6000, tickSpacing);

        // Add initial liquidity in a range around current price
        mintPosition(
            pool,
            address(this),
            tickLower,
            tickUpper,
            uint128(INITIAL_LIQUIDITY)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Core Function Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-out wanting token0
    function test_quoteZapOutSingleCore_wantToken0() public {
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Should have burn amounts
        assertTrue(quote.burnAmount0 > 0, "burnAmount0 should be > 0");
        assertTrue(quote.burnAmount1 > 0, "burnAmount1 should be > 0");

        // Should swap token1 to get token0
        assertEq(quote.swapAmountIn, quote.burnAmount1, "swapAmountIn should equal burnAmount1");

        // Total output should be burnAmount0 + swap output
        assertTrue(quote.amountOut > quote.burnAmount0, "amountOut should be > burnAmount0");

        console.log("burnAmount0:", quote.burnAmount0);
        console.log("burnAmount1:", quote.burnAmount1);
        console.log("swapAmountIn:", quote.swapAmountIn);
        console.log("amountOut:", quote.amountOut);
    }

    /// @notice Test zap-out wanting token1
    function test_quoteZapOutSingleCore_wantToken1() public {
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: false,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Should have burn amounts
        assertTrue(quote.burnAmount0 > 0, "burnAmount0 should be > 0");
        assertTrue(quote.burnAmount1 > 0, "burnAmount1 should be > 0");

        // Should swap token0 to get token1
        assertEq(quote.swapAmountIn, quote.burnAmount0, "swapAmountIn should equal burnAmount0");

        // Total output should be burnAmount1 + swap output
        assertTrue(quote.amountOut > quote.burnAmount1, "amountOut should be > burnAmount1");
    }

    /// @notice Test zap-out when price is below range (only token0 from burn)
    function test_quoteZapOutSingleCore_priceBelowRange() public {
        // Move price below the range by doing a large swap (token0 -> token1)
        MockERC20(token0).mint(address(this), 5000e18);
        MockERC20(token0).approve(address(pool), type(uint256).max);

        // Get current state
        (uint160 sqrtPriceBefore, int24 tickBefore, , , , , ) = pool.slot0();
        console.log("Tick before:", uint24(tickBefore >= 0 ? tickBefore : -tickBefore));

        // Do a swap to move price (zeroForOne = true means token0 -> token1)
        // Pass payer address in callback data
        pool.swap(address(this), true, int256(4000e18), TickMath.MIN_SQRT_RATIO + 1, abi.encode(address(this)));

        (uint160 sqrtPriceAfter, int24 tickAfter, , , , , ) = pool.slot0();
        console.log("Tick after:", uint24(tickAfter >= 0 ? tickAfter : -tickAfter));

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: true,  // Want token0
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // When price is below range, burn gives only token0 (no token1)
        assertTrue(quote.burnAmount0 > 0, "burnAmount0 should be > 0");
        assertEq(quote.burnAmount1, 0, "burnAmount1 should be 0 when price below range");

        // No swap needed - already have only token0
        assertEq(quote.swapAmountIn, 0, "No swap needed");
        assertEq(quote.amountOut, quote.burnAmount0, "amountOut should equal burnAmount0");
    }

    /// @notice Test zap-out when price is above range (only token1 from burn)
    function test_quoteZapOutSingleCore_priceAboveRange() public {
        // Move price above the range by doing a large swap (token1 -> token0)
        MockERC20(token1).mint(address(this), 5000e18);
        MockERC20(token1).approve(address(pool), type(uint256).max);

        // Do a swap to move price (zeroForOne = false means token1 -> token0)
        // Pass payer address in callback data
        pool.swap(address(this), false, int256(4000e18), TickMath.MAX_SQRT_RATIO - 1, abi.encode(address(this)));

        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: false,  // Want token1
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // When price is above range, burn gives only token1 (no token0)
        assertEq(quote.burnAmount0, 0, "burnAmount0 should be 0 when price above range");
        assertTrue(quote.burnAmount1 > 0, "burnAmount1 should be > 0");

        // No swap needed - already have only token1
        assertEq(quote.swapAmountIn, 0, "No swap needed");
        assertEq(quote.amountOut, quote.burnAmount1, "amountOut should equal burnAmount1");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Wrapper Tests                                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Test pool-native wrapper
    function test_quoteZapOutPool() public {
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.PoolZapOutExecution memory exec = UniswapV3ZapQuoter.quoteZapOutPool(params);

        assertEq(exec.tickLower, tickLower, "tickLower mismatch");
        assertEq(exec.tickUpper, tickUpper, "tickUpper mismatch");
        assertEq(exec.liquidity, 100e18, "liquidity mismatch");
        assertFalse(exec.zeroForOne, "zeroForOne should be false (swapping token1 -> token0)");
        assertTrue(exec.swapAmountIn > 0, "swapAmountIn should be > 0");
    }

    /// @notice Test position manager wrapper
    function test_quoteZapOutPositionManager() public {
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: false,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.PositionManagerZapOutExecution memory exec = UniswapV3ZapQuoter.quoteZapOutPositionManager(params);

        assertEq(exec.tickLower, tickLower, "tickLower mismatch");
        assertEq(exec.tickUpper, tickUpper, "tickUpper mismatch");
        assertEq(exec.liquidity, 100e18, "liquidity mismatch");
        assertTrue(exec.zeroForOne, "zeroForOne should be true (swapping token0 -> token1)");
        assertTrue(exec.swapAmountIn > 0, "swapAmountIn should be > 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Helper Function Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test helper to create ZapOutParams from token address
    function test_createZapOutParams() public {
        // Use actual pool tokens (sorted by address)
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.createZapOutParams(
            pool,
            tickLower,
            tickUpper,
            100e18,
            token0,  // tokenOut = token0
            0,
            0
        );

        assertEq(address(params.pool), address(pool), "pool mismatch");
        assertEq(params.tickLower, tickLower, "tickLower mismatch");
        assertEq(params.tickUpper, tickUpper, "tickUpper mismatch");
        assertEq(params.liquidity, 100e18, "liquidity mismatch");
        assertTrue(params.wantToken0, "wantToken0 should be true");

        // Test with token1
        params = UniswapV3ZapQuoter.createZapOutParams(
            pool,
            tickLower,
            tickUpper,
            50e18,
            token1,  // tokenOut = token1
            0,
            0
        );

        assertFalse(params.wantToken0, "wantToken0 should be false for token1");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Cases                                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test with small liquidity
    function test_quoteZapOutSingleCore_smallLiquidity() public {
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 1e15,  // Very small liquidity
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Should still work with small liquidity
        assertTrue(quote.burnAmount0 >= 0, "burnAmount0 should be >= 0");
        assertTrue(quote.burnAmount1 >= 0, "burnAmount1 should be >= 0");
    }

    /// @notice Test execution matches quote
    function test_quoteZapOutSingleCore_execution() public {
        // Get quote
        UniswapV3ZapQuoter.ZapOutParams memory params = UniswapV3ZapQuoter.ZapOutParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 100e18,
            wantToken0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV3ZapQuoter.ZapOutQuote memory quote = UniswapV3ZapQuoter.quoteZapOutSingleCore(params);

        // Get initial balances
        uint256 initialBalance0 = MockERC20(token0).balanceOf(address(this));

        // Execute burn
        (uint256 burned0, uint256 burned1) = pool.burn(tickLower, tickUpper, 100e18);

        // Collect
        pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);

        // Verify burn amounts match quote
        assertEq(burned0, quote.burnAmount0, "burned0 should match quote");
        assertEq(burned1, quote.burnAmount1, "burned1 should match quote");

        // Execute swap (token1 -> token0, zeroForOne = false)
        if (quote.swapAmountIn > 0) {
            MockERC20(token1).approve(address(pool), type(uint256).max);
            pool.swap(address(this), false, int256(quote.swapAmountIn), TickMath.MAX_SQRT_RATIO - 1, abi.encode(address(this)));
        }

        // Check final balance
        uint256 finalBalance0 = MockERC20(token0).balanceOf(address(this));

        // Final token0 should be approximately equal to quoted amountOut
        // Allow some tolerance for price impact during swap
        uint256 received0 = finalBalance0 - initialBalance0;
        assertApproxEqRel(received0, quote.amountOut, 0.02e18, "received0 should be ~amountOut");

        console.log("Quote amountOut:", quote.amountOut);
        console.log("Actual received:", received0);
    }
}
