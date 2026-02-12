// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {MockERC20} from "./UniswapV3Utils_quoteExactInput.t.sol";

/// @title Test UniswapV3Utils liquidity/amount helpers (Phase 2)
/// @notice Validates _quoteAmountsForLiquidity and _quoteLiquidityForAmounts
contract UniswapV3Utils_LiquidityAmounts_Test is TestBase_UniswapV3 {
    using UniswapV3Utils for *;

    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 1_000e18;

    function setUp() public override {
        super.setUp();

        // Create test tokens
        tokenA = address(new MockERC20("Token A", "TKNA", 18));
        tokenB = address(new MockERC20("Token B", "TKNB", 18));

        vm.label(tokenA, "TokenA");
        vm.label(tokenB, "TokenB");

        // Create pool with 0.3% fee at 1:1 price
        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);
    }

    /* -------------------------------------------------------------------------- */
    /*                      quoteAmountsForLiquidity Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test amounts when price is within the range (both tokens needed)
    function test_quoteAmountsForLiquidity_priceInRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        // Get current pool state (1:1 price, tick ~0)
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();

        // Current tick should be within the range
        assertTrue(currentTick >= tickLower && currentTick < tickUpper, "Price should be in range");

        uint128 liquidity = 1000e18;

        (uint256 amount0, uint256 amount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Both amounts should be non-zero when price is in range
        assertTrue(amount0 > 0, "amount0 should be > 0 when in range");
        assertTrue(amount1 > 0, "amount1 should be > 0 when in range");
    }

    /// @notice Test amounts when price is below the range (only token0 needed)
    function test_quoteAmountsForLiquidity_priceBelowRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        // Range well above current price (tick ~0)
        int24 tickLower = nearestUsableTick(6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(12000, tickSpacing);

        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();

        // Verify price is below range
        assertTrue(currentTick < tickLower, "Price should be below range");

        uint128 liquidity = 1000e18;

        (uint256 amount0, uint256 amount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Only token0 needed when price is below range
        assertTrue(amount0 > 0, "amount0 should be > 0 when below range");
        assertEq(amount1, 0, "amount1 should be 0 when below range");
    }

    /// @notice Test amounts when price is above the range (only token1 needed)
    function test_quoteAmountsForLiquidity_priceAboveRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        // Range well below current price (tick ~0)
        int24 tickLower = nearestUsableTick(-12000, tickSpacing);
        int24 tickUpper = nearestUsableTick(-6000, tickSpacing);

        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();

        // Verify price is above range
        assertTrue(currentTick >= tickUpper, "Price should be above range");

        uint128 liquidity = 1000e18;

        (uint256 amount0, uint256 amount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Only token1 needed when price is above range
        assertEq(amount0, 0, "amount0 should be 0 when above range");
        assertTrue(amount1 > 0, "amount1 should be > 0 when above range");
    }

    /// @notice Test tick overload produces same result as sqrtPrice version
    function test_quoteAmountsForLiquidity_tickOverload() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();
        uint128 liquidity = 1000e18;

        (uint256 amount0_sqrtPrice, uint256 amount1_sqrtPrice) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        (uint256 amount0_tick, uint256 amount1_tick) = UniswapV3Utils._quoteAmountsForLiquidity(
            currentTick,
            tickLower,
            tickUpper,
            liquidity
        );

        // Both should produce same result
        assertEq(amount0_sqrtPrice, amount0_tick, "amount0 mismatch");
        assertEq(amount1_sqrtPrice, amount1_tick, "amount1 mismatch");
    }

    /// @notice Test zero liquidity returns zero amounts
    function test_quoteAmountsForLiquidity_zeroLiquidity() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        (uint256 amount0, uint256 amount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0
        );

        assertEq(amount0, 0, "amount0 should be 0 for zero liquidity");
        assertEq(amount1, 0, "amount1 should be 0 for zero liquidity");
    }

    /* -------------------------------------------------------------------------- */
    /*                      quoteLiquidityForAmounts Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test liquidity calculation when price is within range
    function test_quoteLiquidityForAmounts_priceInRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;

        uint128 liquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Should return non-zero liquidity
        assertTrue(liquidity > 0, "liquidity should be > 0");
    }

    /// @notice Test liquidity calculation when price is below range (only token0 matters)
    function test_quoteLiquidityForAmounts_priceBelowRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(12000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;

        uint128 liquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Liquidity only from token0 when below range
        uint128 liquidityFromZeroOnly = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            0  // No token1
        );

        // Should be the same since token1 is ignored
        assertEq(liquidity, liquidityFromZeroOnly, "liquidity should only depend on token0");
    }

    /// @notice Test liquidity calculation when price is above range (only token1 matters)
    function test_quoteLiquidityForAmounts_priceAboveRange() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-12000, tickSpacing);
        int24 tickUpper = nearestUsableTick(-6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;

        uint128 liquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Liquidity only from token1 when above range
        uint128 liquidityFromOneOnly = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0,  // No token0
            amount1
        );

        // Should be the same since token0 is ignored
        assertEq(liquidity, liquidityFromOneOnly, "liquidity should only depend on token1");
    }

    /// @notice Test tick overload produces same result
    function test_quoteLiquidityForAmounts_tickOverload() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = pool.slot0();

        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;

        uint128 liquidity_sqrtPrice = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        uint128 liquidity_tick = UniswapV3Utils._quoteLiquidityForAmounts(
            currentTick,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        assertEq(liquidity_sqrtPrice, liquidity_tick, "liquidity mismatch");
    }

    /// @notice Test zero amounts returns zero liquidity
    function test_quoteLiquidityForAmounts_zeroAmounts() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint128 liquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            0,
            0
        );

        assertEq(liquidity, 0, "liquidity should be 0 for zero amounts");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Round-Trip Consistency Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that amounts → liquidity → amounts round-trips correctly
    function test_roundTrip_amountsToLiquidityToAmounts() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        // Start with amounts
        uint256 inputAmount0 = 1000e18;
        uint256 inputAmount1 = 1000e18;

        // Convert to liquidity
        uint128 liquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            inputAmount0,
            inputAmount1
        );

        // Convert back to amounts
        (uint256 outputAmount0, uint256 outputAmount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Output amounts should be <= input amounts (liquidity is limited by minimum)
        assertTrue(outputAmount0 <= inputAmount0, "output amount0 should be <= input");
        assertTrue(outputAmount1 <= inputAmount1, "output amount1 should be <= input");

        // At least one should be close to the input (the limiting factor)
        bool amount0IsLimiting = outputAmount0 >= inputAmount0 * 99 / 100;
        bool amount1IsLimiting = outputAmount1 >= inputAmount1 * 99 / 100;
        assertTrue(amount0IsLimiting || amount1IsLimiting, "one amount should be ~100% of input");
    }

    /// @notice Test that liquidity → amounts → liquidity round-trips correctly
    function test_roundTrip_liquidityToAmountsToLiquidity() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        // Start with liquidity
        uint128 inputLiquidity = 1000e18;

        // Convert to amounts
        (uint256 amount0, uint256 amount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            inputLiquidity
        );

        // Convert back to liquidity
        uint128 outputLiquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Should match within rounding tolerance (fixed-point math can lose a few wei)
        assertApproxEqAbs(outputLiquidity, inputLiquidity, 10, "liquidity should round-trip");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Actual Mint Comparison Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoted amounts match actual pool mint
    function test_quoteAmountsForLiquidity_matchesActualMint() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint128 liquidity = 1000e18;

        // Get quoted amounts
        (uint256 quotedAmount0, uint256 quotedAmount1) = UniswapV3Utils._quoteAmountsForLiquidity(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            liquidity
        );

        // Mint actual position and compare
        (uint256 actualAmount0, uint256 actualAmount1) = mintPosition(
            pool,
            address(this),
            tickLower,
            tickUpper,
            liquidity
        );

        // Quoted amounts should match actual within rounding tolerance
        assertApproxEqAbs(quotedAmount0, actualAmount0, 1, "amount0 mismatch vs actual mint");
        assertApproxEqAbs(quotedAmount1, actualAmount1, 1, "amount1 mismatch vs actual mint");
    }

    /// @notice Test quoted liquidity matches actual mintable liquidity
    function test_quoteLiquidityForAmounts_matchesActualMint() public {
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(6000, tickSpacing);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        // Choose amounts
        uint256 amount0 = 500e18;
        uint256 amount1 = 500e18;

        // Get quoted liquidity
        uint128 quotedLiquidity = UniswapV3Utils._quoteLiquidityForAmounts(
            sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );

        // Mint with quoted liquidity and check we don't exceed the amounts
        (uint256 usedAmount0, uint256 usedAmount1) = mintPosition(
            pool,
            address(this),
            tickLower,
            tickUpper,
            quotedLiquidity
        );

        // Used amounts should be <= provided amounts
        assertTrue(usedAmount0 <= amount0, "used amount0 should be <= provided");
        assertTrue(usedAmount1 <= amount1, "used amount1 should be <= provided");
    }
}
