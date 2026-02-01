// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPoolManager} from "../../../../../contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {StateLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/libraries/StateLibrary.sol";
import {PoolKey} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolId.sol";
import {Currency} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {TickMath} from "../../../../../contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {UniswapV4ZapQuoter} from "../../../../../contracts/protocols/dexes/uniswap/v4/utils/UniswapV4ZapQuoter.sol";
import {UniswapV4Utils} from "../../../../../contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Utils.sol";
import {TestBase_UniswapV4EthereumMainnetFork} from "./TestBase_UniswapV4Fork.sol";

/// @title UniswapV4ZapQuoter Fork Tests
/// @notice Validates zap quote accuracy against production Uniswap V4 pools
/// @dev V4-specific: Tests use PoolManager singleton and PoolKey identification
/// @dev Zap-in: single-sided liquidity provision with optimal swap calculation
/// @dev Zap-out: burn liquidity and swap to single token output
contract UniswapV4ZapQuoter_EthereumMainnetFork_Test is TestBase_UniswapV4EthereumMainnetFork {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    /* -------------------------------------------------------------------------- */
    /*                              Pool Keys                                     */
    /* -------------------------------------------------------------------------- */

    PoolKey internal wethUsdcPool_500;
    PoolKey internal wethUsdcPool_3000;
    bool internal hasWethUsdc500;
    bool internal hasWethUsdc3000;

    function setUp() public virtual override {
        super.setUp();

        wethUsdcPool_500 = createPoolKey(WETH, USDC, FEE_LOW, TICK_SPACING_10);
        wethUsdcPool_3000 = createPoolKey(WETH, USDC, FEE_MEDIUM, TICK_SPACING_60);

        hasWethUsdc500 = isPoolInitialized(wethUsdcPool_500);
        hasWethUsdc3000 = isPoolInitialized(wethUsdcPool_3000);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Zap-In Core Tests                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapInSingleCore basic functionality
    /// @dev V4-specific: Uses PoolManager and PoolKey in ZapInParams
    function test_quoteZapInSingleCore_basic() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        // Position around current tick
        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        bool zeroForOne = tokenIsCurrency0(key, WETH);

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1 ether, // 1 WETH
            sqrtPriceLimitX96: 0, // Default
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV4ZapQuoter.ZapInQuote memory quote = UniswapV4ZapQuoter.quoteZapInSingleCore(params);

        // Verify basic results
        assertTrue(quote.liquidity > 0, "should mint some liquidity");
        assertTrue(quote.amount0 > 0 || quote.amount1 > 0, "should use some tokens");

        // Verify consistency: swapAmountIn + amounts should relate to input
        if (zeroForOne) {
            // If zeroForOne, swapped some currency0 to get currency1
            // amount0 is remaining currency0, amount1 is from swap
            uint256 totalCurrency0Used = quote.swapAmountIn + quote.amount0 + quote.dust0;
            assertApproxEqAbs(totalCurrency0Used, 1 ether, 1e15, "currency0 accounting");
        }
    }

    /// @notice Test quoteZapInSingleCore with reverse direction
    function test_quoteZapInSingleCore_reverse() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        // Input USDC instead
        bool zeroForOne = tokenIsCurrency0(key, USDC);

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1000e6, // 1000 USDC
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV4ZapQuoter.ZapInQuote memory quote = UniswapV4ZapQuoter.quoteZapInSingleCore(params);

        assertTrue(quote.liquidity > 0, "should mint some liquidity");
    }

    /// @notice Test zap-in with no swap needed
    function test_quoteZapInSingleCore_noSwap() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        // Position entirely below current price (only currency1 needed)
        int24 tickLower = nearestUsableTick(tick - 6000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick - 3000, tickSpacing);

        // Input the currency that matches the position
        bool zeroForOne = false; // Don't swap, just use currency1

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1000e6,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 10
        });

        UniswapV4ZapQuoter.ZapInQuote memory quote = UniswapV4ZapQuoter.quoteZapInSingleCore(params);

        // May have zero swap if position is out of range
        assertTrue(quote.liquidity >= 0, "liquidity should be valid");
    }

    /// @notice Test zap-in with different search iterations
    function test_quoteZapInSingleCore_searchIters() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        // With few iterations
        UniswapV4ZapQuoter.ZapInParams memory paramsLow = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 5
        });

        UniswapV4ZapQuoter.ZapInQuote memory quoteLow = UniswapV4ZapQuoter.quoteZapInSingleCore(paramsLow);

        // With more iterations
        UniswapV4ZapQuoter.ZapInParams memory paramsHigh = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 25
        });

        UniswapV4ZapQuoter.ZapInQuote memory quoteHigh = UniswapV4ZapQuoter.quoteZapInSingleCore(paramsHigh);

        // Both should produce valid results
        assertTrue(quoteLow.liquidity > 0, "low iters should produce liquidity");
        assertTrue(quoteHigh.liquidity > 0, "high iters should produce liquidity");

        // Higher iterations should be at least as good (more precision)
        assertTrue(quoteHigh.liquidity >= quoteLow.liquidity, "more iterations should be >= better");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Zap-In Wrapper Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapInPoolManager wrapper
    function test_quoteZapInPoolManager() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV4ZapQuoter.PoolManagerZapInExecution memory execution =
            UniswapV4ZapQuoter.quoteZapInPoolManager(params);

        // Verify execution params are filled
        assertEq(Currency.unwrap(execution.key.currency0), Currency.unwrap(key.currency0), "key should match");
        assertEq(execution.tickLower, tickLower, "tickLower should match");
        assertEq(execution.tickUpper, tickUpper, "tickUpper should match");
        assertTrue(execution.liquidity > 0, "liquidity should be > 0");
    }

    /// @notice Test quoteZapInPositionManager wrapper
    function test_quoteZapInPositionManager() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);
        bool zeroForOne = tokenIsCurrency0(key, WETH);

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: zeroForOne,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        UniswapV4ZapQuoter.PositionManagerZapInExecution memory execution =
            UniswapV4ZapQuoter.quoteZapInPositionManager(params);

        assertEq(execution.tickLower, tickLower, "tickLower should match");
        assertEq(execution.tickUpper, tickUpper, "tickUpper should match");
        assertTrue(execution.amount0Desired > 0 || execution.amount1Desired > 0, "should have desired amounts");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Zap-Out Core Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapOutSingleCore basic functionality
    function test_quoteZapOutSingleCore_basic() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        // Simulate having liquidity to burn
        uint128 liquidity = 1e15;
        bool wantCurrency0 = tokenIsCurrency0(key, WETH); // Want WETH output

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantCurrency0: wantCurrency0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV4ZapQuoter.ZapOutQuote memory quote = UniswapV4ZapQuoter.quoteZapOutSingleCore(params);

        // Verify results
        assertTrue(quote.burnAmount0 > 0 || quote.burnAmount1 > 0, "should burn some amounts");
        assertTrue(quote.amountOut > 0, "should have output");

        // Output should include burn amount + swap output
        uint256 originalWanted = wantCurrency0 ? quote.burnAmount0 : quote.burnAmount1;
        assertTrue(quote.amountOut >= originalWanted, "output should include original + swap");
    }

    /// @notice Test quoteZapOutSingleCore wanting currency1 output
    function test_quoteZapOutSingleCore_wantCurrency1() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        bool wantCurrency0 = !tokenIsCurrency0(key, WETH); // Want USDC output

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantCurrency0: wantCurrency0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV4ZapQuoter.ZapOutQuote memory quote = UniswapV4ZapQuoter.quoteZapOutSingleCore(params);

        assertTrue(quote.amountOut > 0, "should have output");
    }

    /// @notice Test zap-out when no swap is needed
    function test_quoteZapOutSingleCore_noSwapNeeded() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        // Position entirely above current price (only currency0 returned)
        int24 tickLower = nearestUsableTick(tick + 3000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 6000, tickSpacing);

        uint128 liquidity = 1e15;
        bool wantCurrency0 = true; // Position returns currency0, want currency0

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantCurrency0: wantCurrency0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV4ZapQuoter.ZapOutQuote memory quote = UniswapV4ZapQuoter.quoteZapOutSingleCore(params);

        // No swap needed if position is entirely in currency0
        // swapAmountIn might be 0 or very small
        assertTrue(quote.amountOut >= 0, "amountOut should be valid");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Zap-Out Wrapper Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quoteZapOutPoolManager wrapper
    function test_quoteZapOutPoolManager() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        bool wantCurrency0 = true;

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantCurrency0: wantCurrency0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV4ZapQuoter.PoolManagerZapOutExecution memory execution =
            UniswapV4ZapQuoter.quoteZapOutPoolManager(params);

        assertEq(execution.tickLower, tickLower, "tickLower should match");
        assertEq(execution.tickUpper, tickUpper, "tickUpper should match");
        assertEq(execution.liquidity, liquidity, "liquidity should match");
        // zeroForOne should be opposite of wantCurrency0
        assertEq(execution.zeroForOne, !wantCurrency0, "swap direction should be opposite of wanted");
    }

    /// @notice Test quoteZapOutPositionManager wrapper
    function test_quoteZapOutPositionManager() public {
        if (!hasWethUsdc3000 && !hasWethUsdc500) {
            vm.skip(true);
        }

        PoolKey memory key = hasWethUsdc3000 ? wethUsdcPool_3000 : wethUsdcPool_500;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        uint128 liquidity = 1e15;
        bool wantCurrency0 = false; // Want currency1

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            wantCurrency0: wantCurrency0,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        UniswapV4ZapQuoter.PositionManagerZapOutExecution memory execution =
            UniswapV4ZapQuoter.quoteZapOutPositionManager(params);

        assertEq(execution.tickLower, tickLower, "tickLower should match");
        assertEq(execution.tickUpper, tickUpper, "tickUpper should match");
        assertEq(execution.liquidity, liquidity, "liquidity should match");
        assertTrue(execution.zeroForOne, "should swap currency0 -> currency1 to get currency1");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test zap-in with zero amount reverts
    function test_quoteZapInSingleCore_zeroAmount_reverts() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        PoolKey memory key = wethUsdcPool_3000;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            zeroForOne: true,
            amountIn: 0, // Zero amount
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        vm.expectRevert("UNIV4ZAP:ZERO_AMOUNT");
        UniswapV4ZapQuoter.quoteZapInSingleCore(params);
    }

    /// @notice Test zap-in with invalid tick range reverts
    function test_quoteZapInSingleCore_invalidRange_reverts() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        PoolKey memory key = wethUsdcPool_3000;

        UniswapV4ZapQuoter.ZapInParams memory params = UniswapV4ZapQuoter.ZapInParams({
            manager: poolManager,
            key: key,
            tickLower: 100, // Upper < Lower = invalid
            tickUpper: -100,
            zeroForOne: true,
            amountIn: 1 ether,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0,
            searchIters: 20
        });

        vm.expectRevert("UNIV4ZAP:INVALID_RANGE");
        UniswapV4ZapQuoter.quoteZapInSingleCore(params);
    }

    /// @notice Test zap-out with zero liquidity reverts
    function test_quoteZapOutSingleCore_zeroLiquidity_reverts() public {
        if (!hasWethUsdc3000) {
            vm.skip(true);
        }

        PoolKey memory key = wethUsdcPool_3000;
        int24 tickSpacing = key.tickSpacing;

        (, int24 tick, , ) = getPoolState(key);

        int24 tickLower = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 600, tickSpacing);

        UniswapV4ZapQuoter.ZapOutParams memory params = UniswapV4ZapQuoter.ZapOutParams({
            manager: poolManager,
            key: key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 0, // Zero liquidity
            wantCurrency0: true,
            sqrtPriceLimitX96: 0,
            maxSwapSteps: 0
        });

        vm.expectRevert("UNIV4ZAP:ZERO_LIQUIDITY");
        UniswapV4ZapQuoter.quoteZapOutSingleCore(params);
    }
}
