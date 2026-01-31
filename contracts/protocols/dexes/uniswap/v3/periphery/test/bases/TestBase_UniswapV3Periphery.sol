// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_UniswapV3} from "../../../test/bases/TestBase_UniswapV3.sol";
import {ISwapRouter} from "../../interfaces/ISwapRouter.sol";
import {SwapRouter} from "../../SwapRouter.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";
import {NonfungiblePositionManager} from "../../NonfungiblePositionManager.sol";
import {Quoter} from "../../lens/Quoter.sol";
import {QuoterV2} from "../../lens/QuoterV2.sol";
import {TickLens} from "../../lens/TickLens.sol";
import {IUniswapV3Pool} from "../../../interfaces/IUniswapV3Pool.sol";
import {TickMath} from "../../../libraries/TickMath.sol";

/// @title Test Base for Uniswap V3 Periphery Contracts
/// @notice Extends TestBase_UniswapV3 with periphery contract deployment and helpers
abstract contract TestBase_UniswapV3Periphery is TestBase_UniswapV3 {
    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    SwapRouter internal swapRouter;
    NonfungiblePositionManager internal positionManager;
    Quoter internal quoter;
    QuoterV2 internal quoterV2;
    TickLens internal tickLens;

    // Mock token descriptor (returns empty URI, acceptable for testing)
    address internal mockTokenDescriptor;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual override {
        TestBase_UniswapV3.setUp();

        // Deploy mock token descriptor (simple contract that returns empty string)
        mockTokenDescriptor = address(new MockTokenDescriptor());
        vm.label(mockTokenDescriptor, "mockTokenDescriptor");

        // Deploy SwapRouter
        swapRouter = new SwapRouter(address(uniswapV3Factory), address(weth));
        vm.label(address(swapRouter), "swapRouter");

        // Deploy NonfungiblePositionManager
        positionManager = new NonfungiblePositionManager(
            address(uniswapV3Factory),
            address(weth),
            mockTokenDescriptor
        );
        vm.label(address(positionManager), "positionManager");

        // Deploy Quoter
        quoter = new Quoter(address(uniswapV3Factory), address(weth));
        vm.label(address(quoter), "quoter");

        // Deploy QuoterV2
        quoterV2 = new QuoterV2(address(uniswapV3Factory), address(weth));
        vm.label(address(quoterV2), "quoterV2");

        // Deploy TickLens
        tickLens = new TickLens();
        vm.label(address(tickLens), "tickLens");
    }

    /* -------------------------------------------------------------------------- */
    /*                            SwapRouter Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute an exact input single swap via SwapRouter
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param fee Pool fee tier
    /// @param amountIn Amount of input tokens
    /// @param recipient Recipient of output tokens
    /// @return amountOut Amount of output tokens received
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        address recipient
    ) internal returns (uint256 amountOut) {
        // Ensure we have tokens and approve router
        _mintOrDeal(tokenIn, address(this), amountIn);
        _approveToken(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 1 hours,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice Execute an exact output single swap via SwapRouter
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param fee Pool fee tier
    /// @param amountOut Desired amount of output tokens
    /// @param amountInMaximum Maximum amount of input tokens
    /// @param recipient Recipient of output tokens
    /// @return amountIn Amount of input tokens used
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) internal returns (uint256 amountIn) {
        // Ensure we have tokens and approve router
        _mintOrDeal(tokenIn, address(this), amountInMaximum);
        _approveToken(tokenIn, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp + 1 hours,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        amountIn = swapRouter.exactOutputSingle(params);
    }

    /* -------------------------------------------------------------------------- */
    /*                       PositionManager Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Mint a new liquidity position via PositionManager
    /// @param token0 Token0 address
    /// @param token1 Token1 address
    /// @param fee Pool fee tier
    /// @param tickLower Lower tick bound
    /// @param tickUpper Upper tick bound
    /// @param amount0Desired Desired amount of token0
    /// @param amount1Desired Desired amount of token1
    /// @param recipient Recipient of NFT
    /// @return tokenId The minted position NFT ID
    /// @return liquidity The amount of liquidity minted
    function mintPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        address recipient
    ) internal returns (uint256 tokenId, uint128 liquidity) {
        // Ensure tokens are ordered
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
            (amount0Desired, amount1Desired) = (amount1Desired, amount0Desired);
        }

        // Mint tokens and approve
        _mintOrDeal(token0, address(this), amount0Desired);
        _mintOrDeal(token1, address(this), amount1Desired);
        _approveToken(token0, address(positionManager), amount0Desired);
        _approveToken(token1, address(positionManager), amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: recipient,
            deadline: block.timestamp + 1 hours
        });

        (tokenId, liquidity, , ) = positionManager.mint(params);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Token Helpers                                */
    /* -------------------------------------------------------------------------- */

    function _approveToken(address token, address spender, uint256 amount) internal {
        (bool success, ) = token.call(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
        require(success, "Token approval failed");
    }
}

/// @notice Mock token descriptor that returns empty tokenURI
/// @dev Used for testing when NFT metadata is not needed
contract MockTokenDescriptor {
    function tokenURI(address, uint256) external pure returns (string memory) {
        return "";
    }
}
