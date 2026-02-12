// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Factory} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {UniswapV3Factory} from "@crane/contracts/protocols/dexes/uniswap/v3/UniswapV3Factory.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {TestBase_UniswapV3Fork} from "./TestBase_UniswapV3Fork.sol";

import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";

/// @title UniswapV3 Ported Swap Parity Fork Tests
/// @notice Validates that our ported Uniswap V3 stack produces identical swap outputs to mainnet V3
/// @dev Compares swap results between locally deployed V3 stack and mainnet V3 factory
///
/// Test Strategy:
/// 1. Fork Ethereum mainnet at a fixed block
/// 2. Deploy test ERC20 tokens
/// 3. Deploy our local V3 factory (ported contracts)
/// 4. Create identical pools on BOTH mainnet V3 factory AND our local factory
/// 5. Initialize pools to same sqrtPriceX96
/// 6. Add identical liquidity positions to both pools
/// 7. Execute same swaps on both pools
/// 8. Assert outputs match exactly (or within dust tolerance)
contract UniswapV3PortedSwapParity_Fork_Test is TestBase_UniswapV3Fork {
    /* -------------------------------------------------------------------------- */
    /*                              Local Stack                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Our locally deployed V3 factory (ported contracts)
    UniswapV3Factory internal localFactory;

    /* -------------------------------------------------------------------------- */
    /*                              Test Tokens                                   */
    /* -------------------------------------------------------------------------- */

    MockERC20 internal tokenA; // 18 decimals (like WETH)
    MockERC20 internal tokenB; // 6 decimals (like USDC)
    MockERC20 internal tokenC; // 8 decimals (like WBTC)
    MockERC20 internal tokenD; // 18 decimals (another standard token)

    /* -------------------------------------------------------------------------- */
    /*                              Test Parameters                               */
    /* -------------------------------------------------------------------------- */

    /// @dev Starting price: 1 tokenA = 2000 tokenB (like ETH/USDC)
    /// sqrtPriceX96 = sqrt(2000 * 10^6 / 10^18) * 2^96 ≈ sqrt(2e-12) * 2^96
    /// For token0 < token1, price = token1/token0
    uint160 internal constant INITIAL_SQRT_PRICE_X96 = 3543191142285914205922034323; // ~2000 USDC per ETH

    /// @dev Liquidity amount for test positions
    uint128 internal constant TEST_LIQUIDITY = 1e18;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public override {
        // Call parent setup (creates fork, sets up mainnet factory reference)
        super.setUp();

        // Deploy our local V3 factory (ported contracts)
        localFactory = new UniswapV3Factory();
        vm.label(address(localFactory), "LocalV3Factory");

        // Deploy test tokens
        tokenA = new MockERC20("TokenA", "TKA", 18);
        tokenA.mint(address(this), 1e30);
        vm.label(address(tokenA), "TokenA_18dec");

        tokenB = new MockERC20("TokenB", "TKB", 6);
        tokenB.mint(address(this), 1e30);
        vm.label(address(tokenB), "TokenB_6dec");

        tokenC = new MockERC20("TokenC", "TKC", 8);
        tokenC.mint(address(this), 1e30);
        vm.label(address(tokenC), "TokenC_8dec");

        tokenD = new MockERC20("TokenD", "TKD", 18);
        tokenD.mint(address(this), 1e30);
        vm.label(address(tokenD), "TokenD_18dec");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool Creation Helpers                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a pool on both mainnet and local factory with same parameters
    /// @param token0 The token0 address (must be < token1)
    /// @param token1 The token1 address
    /// @param fee The fee tier
    /// @param sqrtPriceX96 Initial sqrt price
    /// @return mainnetPool The pool from mainnet factory
    /// @return localPool The pool from local factory
    function createMatchingPools(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) internal returns (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) {
        require(token0 < token1, "token0 must be < token1");

        // Create pool on mainnet factory
        address mainnetPoolAddr = uniswapV3Factory.createPool(token0, token1, fee);
        mainnetPool = IUniswapV3Pool(mainnetPoolAddr);
        mainnetPool.initialize(sqrtPriceX96);

        // Create pool on local factory
        address localPoolAddr = localFactory.createPool(token0, token1, fee);
        localPool = IUniswapV3Pool(localPoolAddr);
        localPool.initialize(sqrtPriceX96);

        // Note: Pool addresses will differ due to different init code hashes
        // This is expected and documented in TASK.md
    }

    /// @notice Add identical liquidity to both pools
    /// @param mainnetPool Pool from mainnet factory
    /// @param localPool Pool from local factory
    /// @param tickLower Lower tick bound
    /// @param tickUpper Upper tick bound
    /// @param liquidity Liquidity amount
    function addMatchingLiquidity(
        IUniswapV3Pool mainnetPool,
        IUniswapV3Pool localPool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal {
        // Add liquidity to mainnet pool
        mintPosition(mainnetPool, address(this), tickLower, tickUpper, liquidity);

        // Add liquidity to local pool
        mintPosition(localPool, address(this), tickLower, tickUpper, liquidity);
    }

    /// @notice Execute same swap on both pools and return outputs
    /// @param mainnetPool Pool from mainnet factory
    /// @param localPool Pool from local factory
    /// @param zeroForOne Swap direction
    /// @param amountIn Amount to swap
    /// @return mainnetOut Output from mainnet pool
    /// @return localOut Output from local pool
    function executeMatchingSwaps(
        IUniswapV3Pool mainnetPool,
        IUniswapV3Pool localPool,
        bool zeroForOne,
        uint256 amountIn
    ) internal returns (uint256 mainnetOut, uint256 localOut) {
        // Execute on mainnet pool
        mainnetOut = swapExactInput(mainnetPool, zeroForOne, amountIn, address(this));

        // Execute on local pool
        localOut = swapExactInput(localPool, zeroForOne, amountIn, address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                     US-CRANE-204.2: Core Pool Swap Parity                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test swap parity for 0.05% fee tier (tick spacing 10)
    /// @dev Compares swap outputs between mainnet and local V3 pools
    function test_swapParity_feeTier500_zeroForOne() public {
        // Sort tokens for proper ordering
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        // Create matching pools
        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_LOW,
            INITIAL_SQRT_PRICE_X96
        );

        // Get tick for liquidity range
        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_LOW);
        int24 tickLower = nearestUsableTick(tick - 1000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1000, tickSpacing);

        // Add identical liquidity to both pools
        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        // Test small swap
        uint256 amountIn = 1e15; // 0.001 token (small to stay in tick)
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true, // zeroForOne
            amountIn
        );

        assertEq(localOut, mainnetOut, "500 fee zeroForOne: outputs must match exactly");
    }

    /// @notice Test swap parity for 0.05% fee tier (reverse direction)
    function test_swapParity_feeTier500_oneForZero() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_LOW,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_LOW);
        int24 tickLower = nearestUsableTick(tick - 1000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1000, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e15;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            false, // oneForZero
            amountIn
        );

        assertEq(localOut, mainnetOut, "500 fee oneForZero: outputs must match exactly");
    }

    /// @notice Test swap parity for 0.3% fee tier (tick spacing 60)
    function test_swapParity_feeTier3000_zeroForOne() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        // Test multiple trade sizes
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1e14;  // 0.0001 token (tiny)
        amounts[1] = 1e15;  // 0.001 token (small)
        amounts[2] = 1e16;  // 0.01 token (medium)

        for (uint256 i = 0; i < amounts.length; i++) {
            // Need to re-sync pool states after each swap
            // For exact parity testing, we test single swaps per pool pair
        }

        // Test single swap for deterministic comparison
        uint256 amountIn = 1e15;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "3000 fee zeroForOne: outputs must match exactly");
    }

    /// @notice Test swap parity for 0.3% fee tier (reverse direction)
    function test_swapParity_feeTier3000_oneForZero() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e15;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            false,
            amountIn
        );

        assertEq(localOut, mainnetOut, "3000 fee oneForZero: outputs must match exactly");
    }

    /// @notice Test swap parity for 1% fee tier (tick spacing 200)
    function test_swapParity_feeTier10000_zeroForOne() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_HIGH,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_HIGH);
        int24 tickLower = nearestUsableTick(tick - 2000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 2000, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e15;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "10000 fee zeroForOne: outputs must match exactly");
    }

    /// @notice Test swap parity for 1% fee tier (reverse direction)
    function test_swapParity_feeTier10000_oneForZero() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_HIGH,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_HIGH);
        int24 tickLower = nearestUsableTick(tick - 2000, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 2000, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e15;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            false,
            amountIn
        );

        assertEq(localOut, mainnetOut, "10000 fee oneForZero: outputs must match exactly");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Multiple Trade Sizes Parity Tests                       */
    /* -------------------------------------------------------------------------- */

    /// @notice Test parity across multiple trade sizes for 0.3% pool (tiny)
    function test_swapParity_size_tiny_zeroForOne() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e13; // Very tiny
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Tiny trade zeroForOne: outputs must match");
    }

    /// @notice Test parity for small trade size
    function test_swapParity_size_small_zeroForOne() public {
        (address token0, address token1) = address(tokenC) < address(tokenD)
            ? (address(tokenC), address(tokenD))
            : (address(tokenD), address(tokenC));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e14; // Small
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Small trade zeroForOne: outputs must match");
    }

    /// @notice Test parity for medium trade size
    function test_swapParity_size_medium_zeroForOne() public {
        // Use tokenA/tokenD pair (different from other tests)
        (address token0, address token1) = address(tokenA) < address(tokenD)
            ? (address(tokenA), address(tokenD))
            : (address(tokenD), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e16; // Medium
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Medium trade zeroForOne: outputs must match");
    }

    /// @notice Test parity across multiple trade sizes (reverse direction, tiny)
    function test_swapParity_size_tiny_oneForZero() public {
        // Use tokenB/tokenC pair
        (address token0, address token1) = address(tokenB) < address(tokenC)
            ? (address(tokenB), address(tokenC))
            : (address(tokenC), address(tokenB));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e13;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            false,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Tiny trade oneForZero: outputs must match");
    }

    /// @notice Test parity for medium trade size (reverse direction)
    function test_swapParity_size_medium_oneForZero() public {
        // Use tokenB/tokenD pair
        (address token0, address token1) = address(tokenB) < address(tokenD)
            ? (address(tokenB), address(tokenD))
            : (address(tokenD), address(tokenB));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e16;
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            false,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Medium trade oneForZero: outputs must match");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Multi-Position Liquidity Parity Tests                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test parity with multiple liquidity positions
    /// @dev Ensures tick crossing behavior matches
    function test_swapParity_multiplePositions() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);

        // Add multiple overlapping positions
        // Position 1: Wide range
        int24 tickLower1 = nearestUsableTick(tick - 3000, tickSpacing);
        int24 tickUpper1 = nearestUsableTick(tick + 3000, tickSpacing);
        addMatchingLiquidity(mainnetPool, localPool, tickLower1, tickUpper1, TEST_LIQUIDITY);

        // Position 2: Narrow range around current tick
        int24 tickLower2 = nearestUsableTick(tick - 600, tickSpacing);
        int24 tickUpper2 = nearestUsableTick(tick + 600, tickSpacing);
        addMatchingLiquidity(mainnetPool, localPool, tickLower2, tickUpper2, TEST_LIQUIDITY * 2);

        // Position 3: One-sided (above current tick)
        int24 tickLower3 = nearestUsableTick(tick + 120, tickSpacing);
        int24 tickUpper3 = nearestUsableTick(tick + 1800, tickSpacing);
        addMatchingLiquidity(mainnetPool, localPool, tickLower3, tickUpper3, TEST_LIQUIDITY);

        // Execute swap that should cross multiple tick boundaries
        uint256 amountIn = 1e16; // Larger swap to potentially cross ticks
        (uint256 mainnetOut, uint256 localOut) = executeMatchingSwaps(
            mainnetPool,
            localPool,
            true,
            amountIn
        );

        assertEq(localOut, mainnetOut, "Multi-position swap: outputs must match exactly");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Exact Output Swap Parity Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test exact output swap parity
    function test_swapParity_exactOutput_zeroForOne() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        // Execute exact output swaps
        uint256 amountOut = 1e14; // Want this much output
        uint256 mainnetIn = swapExactOutput(mainnetPool, true, amountOut, address(this));
        uint256 localIn = swapExactOutput(localPool, true, amountOut, address(this));

        assertEq(localIn, mainnetIn, "Exact output zeroForOne: input amounts must match");
    }

    /// @notice Test exact output swap parity (reverse direction)
    function test_swapParity_exactOutput_oneForZero() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountOut = 1e14;
        uint256 mainnetIn = swapExactOutput(mainnetPool, false, amountOut, address(this));
        uint256 localIn = swapExactOutput(localPool, false, amountOut, address(this));

        assertEq(localIn, mainnetIn, "Exact output oneForZero: input amounts must match");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Pool State Verification Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify pool state matches after initialization
    function test_poolStateMatch_afterInitialization() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        // Verify slot0 matches
        (uint160 mainnetSqrtPrice, int24 mainnetTick, , , , , ) = mainnetPool.slot0();
        (uint160 localSqrtPrice, int24 localTick, , , , , ) = localPool.slot0();

        assertEq(localSqrtPrice, mainnetSqrtPrice, "sqrtPriceX96 must match");
        assertEq(localTick, mainnetTick, "tick must match");

        // Verify token ordering
        assertEq(localPool.token0(), mainnetPool.token0(), "token0 must match");
        assertEq(localPool.token1(), mainnetPool.token1(), "token1 must match");

        // Verify fee
        assertEq(localPool.fee(), mainnetPool.fee(), "fee must match");
    }

    /// @notice Verify pool state matches after adding liquidity
    function test_poolStateMatch_afterLiquidity() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        // Verify liquidity matches
        assertEq(localPool.liquidity(), mainnetPool.liquidity(), "liquidity must match");

        // Verify tick state matches
        (
            uint128 mainnetLiqGross,
            int128 mainnetLiqNet,
            ,
            ,
            ,
            ,
            ,

        ) = mainnetPool.ticks(tickLower);
        (
            uint128 localLiqGross,
            int128 localLiqNet,
            ,
            ,
            ,
            ,
            ,

        ) = localPool.ticks(tickLower);

        assertEq(localLiqGross, mainnetLiqGross, "tickLower liquidityGross must match");
        assertEq(localLiqNet, mainnetLiqNet, "tickLower liquidityNet must match");
    }

    /// @notice Verify pool state matches after swap
    function test_poolStateMatch_afterSwap() public {
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        (IUniswapV3Pool mainnetPool, IUniswapV3Pool localPool) = createMatchingPools(
            token0,
            token1,
            FEE_MEDIUM,
            INITIAL_SQRT_PRICE_X96
        );

        (, int24 tick, ) = getPoolState(mainnetPool);
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(tick - 1200, tickSpacing);
        int24 tickUpper = nearestUsableTick(tick + 1200, tickSpacing);

        addMatchingLiquidity(mainnetPool, localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        // Execute swaps
        executeMatchingSwaps(mainnetPool, localPool, true, 1e15);

        // Verify state matches after swap
        (uint160 mainnetSqrtPrice, int24 mainnetTick, , , , , ) = mainnetPool.slot0();
        (uint160 localSqrtPrice, int24 localTick, , , , , ) = localPool.slot0();

        assertEq(localSqrtPrice, mainnetSqrtPrice, "sqrtPriceX96 must match after swap");
        assertEq(localTick, mainnetTick, "tick must match after swap");
        assertEq(localPool.liquidity(), mainnetPool.liquidity(), "liquidity must match after swap");
    }
}
