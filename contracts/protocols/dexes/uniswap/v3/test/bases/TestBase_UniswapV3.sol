// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Factory} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {UniswapV3Factory} from "@crane/contracts/protocols/dexes/uniswap/v3/UniswapV3Factory.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol";
import {FixedPoint96} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FixedPoint96.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {TestBase_Weth9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol";
import {IUniswapV3MintCallback} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/callback/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/callback/IUniswapV3SwapCallback.sol";

abstract contract TestBase_UniswapV3 is TestBase_Weth9, IUniswapV3MintCallback, IUniswapV3SwapCallback {
    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    IUniswapV3Factory internal uniswapV3Factory;

    // Standard fee tiers (in pips: 1 pip = 0.0001%)
    uint24 internal constant FEE_LOW = 500;      // 0.05%
    uint24 internal constant FEE_MEDIUM = 3000;  // 0.3%
    uint24 internal constant FEE_HIGH = 10000;   // 1%

    // Standard tick spacings for each fee tier
    int24 internal constant TICK_SPACING_LOW = 10;
    int24 internal constant TICK_SPACING_MEDIUM = 60;
    int24 internal constant TICK_SPACING_HIGH = 200;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual override {
        TestBase_Weth9.setUp();

        if (address(uniswapV3Factory) == address(0)) {
            uniswapV3Factory = new UniswapV3Factory();
            vm.label(address(uniswapV3Factory), "uniswapV3Factory");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Creation                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a Uniswap V3 pool with specified parameters
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @param fee Fee tier (500, 3000, or 10000)
    /// @param sqrtPriceX96 Initial sqrt price in Q64.96 format
    /// @return pool The created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint160 sqrtPriceX96
    ) internal virtual returns (IUniswapV3Pool pool) {
        // Ensure tokens are ordered (token0 < token1)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Create pool
        pool = IUniswapV3Pool(uniswapV3Factory.createPool(token0, token1, fee));

        // Initialize pool with price
        pool.initialize(sqrtPriceX96);

        vm.label(address(pool), string(abi.encodePacked("V3Pool_", vm.toString(fee))));
    }

    /// @notice Create a pool with 1:1 price ratio
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @param fee Fee tier
    /// @return pool The created pool
    function createPoolOneToOne(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal virtual returns (IUniswapV3Pool pool) {
        // 1:1 price = sqrt(1) * 2^96
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);
        return createPool(tokenA, tokenB, fee, sqrtPriceX96);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Liquidity Management                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Mint a liquidity position in a V3 pool
    /// @dev Simplified minting that directly transfers tokens to pool
    /// @param pool The pool to mint in
    /// @param recipient Recipient of liquidity
    /// @param tickLower Lower tick of position
    /// @param tickUpper Upper tick of position
    /// @param amount Liquidity amount to mint
    /// @return amount0 Amount of token0 used
    /// @return amount1 Amount of token1 used
    function mintPosition(
        IUniswapV3Pool pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) internal virtual returns (uint256 amount0, uint256 amount1) {
        address token0 = pool.token0();
        address token1 = pool.token1();

        // Over-fund the payer, then pay the exact owed amounts via the Uniswap V3 mint callback.
        // This avoids duplicating liquidity->amount math here (and keeps the harness robust across ranges).
        uint256 fundAmount = uint256(amount) * 1000;
        _mintOrDeal(token0, address(this), fundAmount);
        _mintOrDeal(token1, address(this), fundAmount);

        (amount0, amount1) = pool.mint(recipient, tickLower, tickUpper, amount, abi.encode(address(this)));
    }

    /* -------------------------------------------------------------------------- */
    /*                                Price Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Encode a price as a sqrt price in Q64.96 format
    /// @dev price = token1/token0, so sqrtPrice = sqrt(reserve1/reserve0) * 2^96
    /// @param reserve0 Reserve of token0
    /// @param reserve1 Reserve of token1
    /// @return sqrtPriceX96 The sqrt price in Q64.96 format
    function encodePriceSqrt(uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        require(reserve0 > 0, "reserve0 must be > 0");

        // Calculate: sqrt(reserve1/reserve0) * 2^96
        // Cannot use 2^192 directly (overflow), so use: sqrt(reserve1) * 2^96 / sqrt(reserve0)
        uint256 sqrtReserve0 = BetterMath._sqrt(reserve0);
        uint256 sqrtReserve1 = BetterMath._sqrt(reserve1);

        sqrtPriceX96 = uint160(FullMath.mulDiv(sqrtReserve1, FixedPoint96.Q96, sqrtReserve0));
    }

    /* -------------------------------------------------------------------------- */
    /*                             Amount Calculations                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Get amount0 for given liquidity between two sqrt prices
    function _getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        return FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Get amount1 for given liquidity between two sqrt prices
    function _getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Swap Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a swap on a V3 pool (exact input)
    /// @param pool The pool to swap in
    /// @param zeroForOne Swap direction
    /// @param amountIn Amount to swap in
    /// @param recipient Recipient of output tokens
    /// @return amountOut Amount of tokens received
    function swapExactInput(
        IUniswapV3Pool pool,
        bool zeroForOne,
        uint256 amountIn,
        address recipient
    ) internal virtual returns (uint256 amountOut) {
        address tokenIn = zeroForOne ? pool.token0() : pool.token1();

        // Ensure payer has tokens, then pay via the Uniswap V3 swap callback.
        _mintOrDeal(tokenIn, address(this), amountIn);

        // Set price limit to allow full swap
        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Execute swap
        (int256 amount0, int256 amount1) = pool.swap(
            recipient,
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            abi.encode(address(this))
        );

        // Return output amount (negative because it's being sent out)
        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }

    /* -------------------------------------------------------------------------- */
    /*                                Callbacks                                   */
    /* -------------------------------------------------------------------------- */

    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        address payer = abi.decode(data, (address));
        require(payer == address(this), "unexpected payer");

        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        if (amount0Owed > 0) IERC20PermitProxy(pool.token0()).transfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20PermitProxy(pool.token1()).transfer(msg.sender, amount1Owed);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        address payer = abi.decode(data, (address));
        require(payer == address(this), "unexpected payer");

        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        if (amount0Delta > 0) IERC20PermitProxy(pool.token0()).transfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20PermitProxy(pool.token1()).transfer(msg.sender, uint256(amount1Delta));
    }

    function _mintOrDeal(address token, address to, uint256 amount) internal {
        if (amount == 0) return;

        (bool ok, ) = token.call(abi.encodeWithSignature("mint(address,uint256)", to, amount));
        if (ok) return;

        deal(token, to, amount, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Tick Alignment Helpers                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Get nearest tick aligned to tick spacing
    /// @param tick The tick to align
    /// @param tickSpacing The tick spacing
    /// @return Aligned tick
    function nearestUsableTick(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        // Round down to nearest multiple of tickSpacing
        int24 rounded = (tick / tickSpacing) * tickSpacing;

        // Ensure it's within bounds
        if (rounded < TickMath.MIN_TICK) {
            return TickMath.MIN_TICK;
        } else if (rounded > TickMath.MAX_TICK) {
            return TickMath.MAX_TICK;
        }

        return rounded;
    }

    /// @notice Get tick spacing for a fee tier
    function getTickSpacing(uint24 fee) internal pure returns (int24) {
        if (fee == FEE_LOW) return TICK_SPACING_LOW;
        if (fee == FEE_MEDIUM) return TICK_SPACING_MEDIUM;
        if (fee == FEE_HIGH) return TICK_SPACING_HIGH;
        revert("Invalid fee tier");
    }
}
