// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IUniswapV3Factory} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {IUniswapV3MintCallback} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/callback/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/callback/IUniswapV3SwapCallback.sol";
import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";

/// @title TestBase_UniswapV3Fork
/// @notice Base test contract for Uniswap V3 fork tests against Ethereum mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
abstract contract TestBase_UniswapV3Fork is Test, IUniswapV3MintCallback, IUniswapV3SwapCallback {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Dec 2024)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 21_000_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    IUniswapV3Factory internal uniswapV3Factory;

    // Standard fee tiers (in pips: 1 pip = 0.0001%)
    uint24 internal constant FEE_LOW = 500;      // 0.05%
    uint24 internal constant FEE_MEDIUM = 3000;  // 0.3%
    uint24 internal constant FEE_HIGH = 10000;   // 1%

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /* -------------------------------------------------------------------------- */
    /*                              Well-Known Pools                              */
    /* -------------------------------------------------------------------------- */

    // WETH/USDC pools (various fee tiers)
    address internal constant WETH_USDC_500 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address internal constant WETH_USDC_3000 = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    address internal constant WETH_USDC_10000 = 0x7BeA39867e4169DBe237d55C8242a8f2fcDcc387;

    // USDC/USDT pool (stablecoin, low fee)
    address internal constant USDC_USDT_500 = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;

    // WBTC/WETH pool (high value pair)
    address internal constant WBTC_WETH_3000 = 0xCBCdF9626bC03E24f779434178A73a0B4bad62eD;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `ethereum_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up factory reference
        uniswapV3Factory = IUniswapV3Factory(ETHEREUM_MAIN.UNISWAP_V3_FACTORY);
        vm.label(address(uniswapV3Factory), "UniswapV3Factory");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(WBTC, "WBTC");

        // Label well-known pools
        vm.label(WETH_USDC_500, "WETH_USDC_0.05%");
        vm.label(WETH_USDC_3000, "WETH_USDC_0.3%");
        vm.label(WETH_USDC_10000, "WETH_USDC_1%");
        vm.label(USDC_USDT_500, "USDC_USDT_0.05%");
        vm.label(WBTC_WETH_3000, "WBTC_WETH_0.3%");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Return whether a token is pool.token0 (reverts if token not in pool)
    function tokenIsToken0(IUniswapV3Pool pool, address token) internal view returns (bool) {
        address token0 = pool.token0();
        address token1 = pool.token1();
        require(token == token0 || token == token1, "token not in pool");
        return token == token0;
    }

    /// @notice Return swap direction for a specific tokenIn -> tokenOut route
    /// @dev zeroForOne means token0 -> token1
    function zeroForOneForTokens(
        IUniswapV3Pool pool,
        address tokenIn,
        address tokenOut
    ) internal view returns (bool) {
        address token0 = pool.token0();
        address token1 = pool.token1();
        require(
            (tokenIn == token0 && tokenOut == token1) || (tokenIn == token1 && tokenOut == token0),
            "token pair mismatch"
        );
        return tokenIn == token0;
    }

    /// @notice Get pool at mainnet address
    function getPool(address poolAddress) internal view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(poolAddress);
    }

    /// @notice Get pool for token pair and fee from factory
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(uniswapV3Factory.getPool(tokenA, tokenB, fee));
    }

    /// @notice Get current pool state (slot0)
    function getPoolState(IUniswapV3Pool pool)
        internal
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint128 liquidity)
    {
        (sqrtPriceX96, tick, , , , , ) = pool.slot0();
        liquidity = pool.liquidity();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap Execution                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a swap (exact input) by specifying tokenIn/tokenOut
    function swapExactInputTokens(
        IUniswapV3Pool pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address recipient
    ) internal returns (uint256 amountOut) {
        bool zeroForOne = zeroForOneForTokens(pool, tokenIn, tokenOut);
        return swapExactInput(pool, zeroForOne, amountIn, recipient);
    }

    /// @notice Execute a swap (exact output) by specifying tokenIn/tokenOut
    function swapExactOutputTokens(
        IUniswapV3Pool pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address recipient
    ) internal returns (uint256 amountIn) {
        bool zeroForOne = zeroForOneForTokens(pool, tokenIn, tokenOut);
        return swapExactOutput(pool, zeroForOne, amountOut, recipient);
    }

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

        // Deal tokens to this contract for the swap
        deal(tokenIn, address(this), amountIn);

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

    /// @notice Execute a swap on a V3 pool (exact output)
    /// @param pool The pool to swap in
    /// @param zeroForOne Swap direction
    /// @param amountOut Desired output amount
    /// @param recipient Recipient of output tokens
    /// @return amountIn Amount of tokens spent
    function swapExactOutput(
        IUniswapV3Pool pool,
        bool zeroForOne,
        uint256 amountOut,
        address recipient
    ) internal virtual returns (uint256 amountIn) {
        address tokenIn = zeroForOne ? pool.token0() : pool.token1();

        // Deal a large amount of input tokens (will refund unused)
        // Use a large fixed buffer rather than multiplier to handle cross-decimal scenarios
        uint256 maxAmountIn = amountOut * 10000 + 100 ether; // Large buffer for any token
        deal(tokenIn, address(this), maxAmountIn);

        // Set price limit to allow full swap
        uint160 sqrtPriceLimitX96 = zeroForOne
            ? TickMath.MIN_SQRT_RATIO + 1
            : TickMath.MAX_SQRT_RATIO - 1;

        // Execute swap (negative amount = exact output)
        (int256 amount0, int256 amount1) = pool.swap(
            recipient,
            zeroForOne,
            -int256(amountOut),
            sqrtPriceLimitX96,
            abi.encode(address(this))
        );

        // Return input amount (positive because it's being paid)
        amountIn = uint256(zeroForOne ? amount0 : amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Liquidity Management                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Mint a liquidity position in a V3 pool
    /// @param pool The pool to mint in
    /// @param recipient Recipient of liquidity
    /// @param tickLower Lower tick of position
    /// @param tickUpper Upper tick of position
    /// @param liquidity Liquidity amount to mint
    /// @return amount0 Amount of token0 used
    /// @return amount1 Amount of token1 used
    function mintPosition(
        IUniswapV3Pool pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal virtual returns (uint256 amount0, uint256 amount1) {
        address token0 = pool.token0();
        address token1 = pool.token1();

        // Deal large amounts of tokens for the mint.
        // Using a fixed large amount is more robust than a liquidity-based heuristic,
        // since owed amounts depend on price and tick range.
        uint256 fundAmount = 1e30;
        deal(token0, address(this), fundAmount);
        deal(token1, address(this), fundAmount);

        (amount0, amount1) = pool.mint(recipient, tickLower, tickUpper, liquidity, abi.encode(address(this)));
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

    /* -------------------------------------------------------------------------- */
    /*                            Assertion Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert quote matches actual within tolerance (0.1% default)
    /// @param quoted The quoted amount
    /// @param actual The actual amount from swap
    /// @param toleranceBps Tolerance in basis points (10 = 0.1%)
    function assertQuoteAccuracy(
        uint256 quoted,
        uint256 actual,
        uint256 toleranceBps,
        string memory message
    ) internal pure {
        uint256 tolerance = (actual * toleranceBps) / 10000;
        if (tolerance == 0) tolerance = 1; // Minimum 1 wei tolerance
        assertApproxEqAbs(quoted, actual, tolerance, message);
    }

    /// @notice Assert quote matches actual within 0.1% tolerance
    function assertQuoteAccuracy(uint256 quoted, uint256 actual, string memory message) internal pure {
        assertQuoteAccuracy(quoted, actual, 10, message); // 10 bps = 0.1%
    }

    /* -------------------------------------------------------------------------- */
    /*                              Tick Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get nearest tick aligned to tick spacing
    function nearestUsableTick(int24 tick, int24 tickSpacing)
        internal
        pure
        returns (int24)
    {
        int24 rounded = (tick / tickSpacing) * tickSpacing;

        if (rounded < TickMath.MIN_TICK) {
            return TickMath.MIN_TICK;
        } else if (rounded > TickMath.MAX_TICK) {
            return TickMath.MAX_TICK;
        }

        return rounded;
    }

    /// @notice Get tick spacing for a fee tier
    function getTickSpacing(uint24 fee) internal pure returns (int24) {
        if (fee == FEE_LOW) return 10;
        if (fee == FEE_MEDIUM) return 60;
        if (fee == FEE_HIGH) return 200;
        revert("Invalid fee tier");
    }
}
