// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TestBase_UniswapV3Periphery} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/test/bases/TestBase_UniswapV3Periphery.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {INonfungiblePositionManager} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/interfaces/INonfungiblePositionManager.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

/// @title Uniswap V3 Periphery Repository Tests
/// @notice Verifies the ported V3 periphery contracts work correctly
contract UniswapV3PeripheryRepoTest is TestBase_UniswapV3Periphery {
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    IUniswapV3Pool internal pool;

    function setUp() public override {
        super.setUp();

        // Deploy test tokens
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        vm.label(address(tokenA), "tokenA");
        vm.label(address(tokenB), "tokenB");

        // Order tokens for pool creation
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        // Create and initialize pool at 1:1 price
        pool = createPoolOneToOne(token0, token1, FEE_MEDIUM);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Deployment Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_SwapRouterDeployment() public view {
        assertNotEq(address(swapRouter), address(0), "SwapRouter should be deployed");
        assertEq(swapRouter.factory(), address(uniswapV3Factory), "SwapRouter factory should match");
        assertEq(swapRouter.WETH9(), address(weth), "SwapRouter WETH9 should match");
    }

    function test_PositionManagerDeployment() public view {
        assertNotEq(address(positionManager), address(0), "PositionManager should be deployed");
        assertEq(positionManager.factory(), address(uniswapV3Factory), "PositionManager factory should match");
        assertEq(positionManager.WETH9(), address(weth), "PositionManager WETH9 should match");
    }

    function test_QuoterDeployment() public view {
        assertNotEq(address(quoter), address(0), "Quoter should be deployed");
        assertEq(quoter.factory(), address(uniswapV3Factory), "Quoter factory should match");
        assertEq(quoter.WETH9(), address(weth), "Quoter WETH9 should match");
    }

    function test_QuoterV2Deployment() public view {
        assertNotEq(address(quoterV2), address(0), "QuoterV2 should be deployed");
        assertEq(quoterV2.factory(), address(uniswapV3Factory), "QuoterV2 factory should match");
        assertEq(quoterV2.WETH9(), address(weth), "QuoterV2 WETH9 should match");
    }

    function test_TickLensDeployment() public view {
        assertNotEq(address(tickLens), address(0), "TickLens should be deployed");
    }

    /* -------------------------------------------------------------------------- */
    /*                              SwapRouter Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_SwapRouter_ExactInputSingle() public {
        // First add liquidity to the pool
        _addLiquidityToPool();

        // Order tokens
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        uint256 amountIn = 1 ether;
        uint256 balanceBefore = MockERC20(token1).balanceOf(address(this));

        // Swap token0 for token1
        uint256 amountOut = swapExactInputSingle(
            token0,
            token1,
            FEE_MEDIUM,
            amountIn,
            address(this)
        );

        uint256 balanceAfter = MockERC20(token1).balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAfter - balanceBefore, amountOut, "Balance should increase by amountOut");
    }

    function test_SwapRouter_ExactOutputSingle() public {
        // First add liquidity to the pool
        _addLiquidityToPool();

        // Order tokens
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        uint256 amountOut = 0.5 ether;
        uint256 amountInMaximum = 2 ether;

        uint256 balanceBefore = MockERC20(token1).balanceOf(address(this));

        // Swap for exact amount of token1
        uint256 amountIn = swapExactOutputSingle(
            token0,
            token1,
            FEE_MEDIUM,
            amountOut,
            amountInMaximum,
            address(this)
        );

        uint256 balanceAfter = MockERC20(token1).balanceOf(address(this));

        assertGt(amountIn, 0, "Should use input tokens");
        assertLe(amountIn, amountInMaximum, "Should not exceed maximum input");
        assertEq(balanceAfter - balanceBefore, amountOut, "Should receive exact output amount");
    }

    /* -------------------------------------------------------------------------- */
    /*                         PositionManager Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_PositionManager_Mint() public {
        // Order tokens
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        int24 tickSpacing = pool.tickSpacing();
        int24 tickLower = -tickSpacing * 10;
        int24 tickUpper = tickSpacing * 10;

        (uint256 tokenId, uint128 liquidity) = mintPosition(
            token0,
            token1,
            FEE_MEDIUM,
            tickLower,
            tickUpper,
            10 ether,
            10 ether,
            address(this)
        );

        assertGt(tokenId, 0, "Should receive NFT");
        assertGt(liquidity, 0, "Should have liquidity");
        assertEq(positionManager.ownerOf(tokenId), address(this), "Should own the NFT");
    }

    function test_PositionManager_IncreaseLiquidity() public {
        // Order tokens
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        int24 tickSpacing = pool.tickSpacing();
        int24 tickLower = -tickSpacing * 10;
        int24 tickUpper = tickSpacing * 10;

        // First mint a position
        (uint256 tokenId, uint128 initialLiquidity) = mintPosition(
            token0,
            token1,
            FEE_MEDIUM,
            tickLower,
            tickUpper,
            10 ether,
            10 ether,
            address(this)
        );

        // Prepare more tokens
        _mintOrDeal(token0, address(this), 5 ether);
        _mintOrDeal(token1, address(this), 5 ether);
        _approveToken(token0, address(positionManager), 5 ether);
        _approveToken(token1, address(positionManager), 5 ether);

        // Increase liquidity
        (uint128 addedLiquidity, , ) = positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: 5 ether,
                amount1Desired: 5 ether,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 1 hours
            })
        );

        assertGt(addedLiquidity, 0, "Should add liquidity");

        // Verify total liquidity increased
        (,,,,,,, uint128 totalLiquidity,,,,) = positionManager.positions(tokenId);
        assertEq(totalLiquidity, initialLiquidity + addedLiquidity, "Total liquidity should increase");
    }

    /* -------------------------------------------------------------------------- */
    /*                              TickLens Tests                                 */
    /* -------------------------------------------------------------------------- */

    function test_TickLens_GetPopulatedTicks() public {
        // Add liquidity to populate some ticks
        _addLiquidityToPool();

        // Get tick bitmap index for tick 0
        int16 tickBitmapIndex = 0;

        // Query populated ticks (may be empty if no ticks in this word)
        // This just verifies the function doesn't revert
        tickLens.getPopulatedTicksInWord(address(pool), tickBitmapIndex);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                               */
    /* -------------------------------------------------------------------------- */

    function _addLiquidityToPool() internal {
        // Order tokens
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        int24 tickSpacing = pool.tickSpacing();
        int24 tickLower = -tickSpacing * 100;
        int24 tickUpper = tickSpacing * 100;

        // Mint position with substantial liquidity
        mintPosition(
            token0,
            token1,
            FEE_MEDIUM,
            tickLower,
            tickUpper,
            1000 ether,
            1000 ether,
            address(this)
        );
    }

    // Required interface for position NFT receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
