// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {MockERC20} from "./UniswapV3Utils_quoteExactInput.t.sol";

/// @title Test UniswapV3Utils._quoteExactOutputSingle
/// @notice Validates exact output swap quotes against actual V3 pool execution
contract UniswapV3Utils_quoteExactOutput_Test is TestBase_UniswapV3 {
    using UniswapV3Utils for *;

    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 1_000e18;
    uint256 constant TEST_AMOUNT = 1e18;

    function setUp() public override {
        super.setUp();

        // Create test tokens
        tokenA = address(new MockERC20("Token A", "TKNA", 18));
        tokenB = address(new MockERC20("Token B", "TKNB", 18));

        vm.label(tokenA, "TokenA");
        vm.label(tokenB, "TokenB");

        // Create pool with 0.3% fee at 1:1 price
        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);

        // Add liquidity in wide range
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        mintPosition(
            pool,
            address(this),
            nearestUsableTick(-60000, tickSpacing),
            nearestUsableTick(60000, tickSpacing),
            uint128(INITIAL_LIQUIDITY)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Quote vs Actual Swap Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test exact output quote matches actual swap (token0 -> token1)
    function test_quoteExactOutput_zeroForOne_matchesActualSwap() public {
        uint256 amountOut = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from UniswapV3Utils
        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // token0 -> token1
        );

        // Execute actual swap
        uint256 actualIn = swapExactOutput(pool, true, amountOut, address(this));

        // Quote should match actual within rounding tolerance (±1 wei)
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for zeroForOne");
    }

    /// @notice Test exact output quote matches actual swap (token1 -> token0)
    function test_quoteExactOutput_oneForZero_matchesActualSwap() public {
        uint256 amountOut = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from UniswapV3Utils
        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // token1 -> token0
        );

        // Execute actual swap
        uint256 actualIn = swapExactOutput(pool, false, amountOut, address(this));

        // Quote should match actual within rounding tolerance
        assertApproxEqAbs(quotedIn, actualIn, 1, "Quote mismatch for oneForZero");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Tick Overload Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test tick overload produces same result as sqrtPrice version
    function test_quoteExactOutput_tickOverload_matchesSqrtPriceVersion() public {
        uint256 amountOut = TEST_AMOUNT;

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Quote using tick
        uint256 quotedWithTick = UniswapV3Utils._quoteExactOutputSingle(
            amountOut,
            tick,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Should be identical
        assertEq(quotedWithSqrtPrice, quotedWithTick, "Tick overload mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Fee Tier Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote correctness across different fee tiers
    function test_quoteExactOutput_differentFeeTiers() public {
        uint256 amountOut = TEST_AMOUNT;

        // Test each standard fee tier
        uint24[3] memory feeTiers = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];

        for (uint256 i = 0; i < feeTiers.length; i++) {
            uint24 fee = feeTiers[i];

            // Create pool for this fee tier
            IUniswapV3Pool testPool = createPoolOneToOne(
                address(new MockERC20("A", "A", 18)),
                address(new MockERC20("B", "B", 18)),
                fee
            );

            // Add liquidity
            int24 tickSpacing = getTickSpacing(fee);
            mintPosition(
                testPool,
                address(this),
                nearestUsableTick(-60000, tickSpacing),
                nearestUsableTick(60000, tickSpacing),
                uint128(INITIAL_LIQUIDITY)
            );

            // Get quote
            (uint160 sqrtPriceX96, , , , , , ) = testPool.slot0();
            uint128 liquidity = testPool.liquidity();

            uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
                amountOut,
                sqrtPriceX96,
                liquidity,
                fee,
                true
            );

            // Execute actual swap
            uint256 actualIn = swapExactOutput(testPool, true, amountOut, address(this));

            // Validate
            assertApproxEqAbs(quotedIn, actualIn, 1, string(abi.encodePacked("Fee tier ", vm.toString(fee))));
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with zero amount returns zero
    function test_quoteExactOutput_zeroAmount() public {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedIn = UniswapV3Utils._quoteExactOutputSingle(
            0,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedIn, 0, "Zero output should require zero input");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Helper Functions                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute exact output swap on V3 pool
    function swapExactOutput(
        IUniswapV3Pool _pool,
        bool zeroForOne,
        uint256 amountOut,
        address recipient
    ) internal returns (uint256 amountIn) {
        address tokenIn = zeroForOne ? _pool.token0() : _pool.token1();

        // Ensure we can pay in the swap callback.
        // Prefer mint() if available, otherwise fall back to Foundry deal().
        (bool ok, ) = tokenIn.call(abi.encodeWithSignature("mint(address,uint256)", address(this), type(uint128).max));
        if (!ok) {
            deal(tokenIn, address(this), type(uint128).max, true);
        }

        // Set price limit
        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Execute swap (negative amount for exact output)
        (int256 amount0, int256 amount1) = _pool.swap(
            recipient,
            zeroForOne,
            -int256(amountOut),  // Negative for exact output
            sqrtPriceLimitX96,
            abi.encode(address(this))
        );

        // Return input amount (positive because it's being sent in)
        amountIn = uint256(zeroForOne ? amount0 : amount1);
    }
}
