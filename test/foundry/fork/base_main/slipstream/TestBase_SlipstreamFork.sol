// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {BASE_MAIN} from "@crane/contracts/constants/networks/BASE_MAIN.sol";

/// @title TestBase_SlipstreamFork
/// @notice Base test contract for Slipstream fork tests against Base mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
abstract contract TestBase_SlipstreamFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2026 - adjust as needed)
    /// Use a recent block with known pool states for deterministic testing
    /// Block 28,000,000 is a more recent block where AERO/USDC pool has liquidity
    uint256 internal constant FORK_BLOCK = 28_000_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    address internal slipstreamFactory;
    address internal slipstreamQuoterV2;

    // Standard fee tiers (in pips: 1 pip = 0.0001%)
    uint24 internal constant FEE_LOW = 100;       // 0.01%
    uint24 internal constant FEE_MEDIUM = 500;    // 0.05%
    uint24 internal constant FEE_HIGH = 3000;     // 0.3%
    uint24 internal constant FEE_HIGHEST = 10000; // 1%

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address internal constant AERO = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;
    address internal constant cbBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    /* -------------------------------------------------------------------------- */
    /*                              Well-Known Pools                              */
    /* -------------------------------------------------------------------------- */

    // WETH/USDC Slipstream pools
    // Pool addresses from GeckoTerminal and BaseScan
    address internal constant WETH_USDC_CL_500 = 0xb2cc224c1c9feE385f8ad6a55b4d94E92359DC59;  // 0.05% fee
    address internal constant WETH_USDC_CL_100 = 0xcDAC0d6c6C59727a65F871236188350531885C43;  // Lower fee variant

    // cbBTC/WETH Slipstream pool (high liquidity Bitcoin pair)
    address internal constant cbBTC_WETH_CL = 0x70aCDF2Ad0bf2402C957154f944c19Ef4e1cbAE1;  // 0.05% fee

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `base_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        if (bytes(infuraKey).length == 0) {
            vm.skip(true);
        }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("base_mainnet_infura", FORK_BLOCK);

        // Set up contract references
        slipstreamFactory = BASE_MAIN.AERODROME_SLIPSTREAM_POOL_FACTORY;
        slipstreamQuoterV2 = BASE_MAIN.AERODROME_SLIPSTREAM_QUOTER_V2;

        vm.label(slipstreamFactory, "SlipstreamFactory");
        vm.label(slipstreamQuoterV2, "SlipstreamQuoterV2");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDbC, "USDbC");
        vm.label(AERO, "AERO");
        vm.label(cbBTC, "cbBTC");

        // Label well-known pools
        vm.label(WETH_USDC_CL_500, "WETH_USDC_CL_0.05%");
        vm.label(WETH_USDC_CL_100, "WETH_USDC_CL_low");
        vm.label(cbBTC_WETH_CL, "cbBTC_WETH_CL_0.05%");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Return whether a token is pool.token0 (reverts if token not in pool)
    function tokenIsToken0(ICLPool pool, address token) internal view returns (bool) {
        address token0 = pool.token0();
        address token1 = pool.token1();
        require(token == token0 || token == token1, "token not in pool");
        return token == token0;
    }

    /// @notice Return swap direction for a specific tokenIn -> tokenOut route
    /// @dev zeroForOne means token0 -> token1
    function zeroForOneForTokens(
        ICLPool pool,
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
    function getPool(address poolAddress) internal view returns (ICLPool) {
        return ICLPool(poolAddress);
    }

    /// @notice Get current pool state (slot0)
    function getPoolState(ICLPool pool)
        internal
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint128 liquidity)
    {
        (sqrtPriceX96, tick, , , , ) = pool.slot0();
        liquidity = pool.liquidity();
    }

    /// @notice Get pool fee (dynamic fee from factory in Slipstream)
    function getPoolFee(ICLPool pool) internal view returns (uint24) {
        return pool.fee();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap Execution                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a swap (exact input) by specifying tokenIn/tokenOut
    function swapExactInputTokens(
        ICLPool pool,
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
        ICLPool pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address recipient
    ) internal returns (uint256 amountIn) {
        bool zeroForOne = zeroForOneForTokens(pool, tokenIn, tokenOut);
        return swapExactOutput(pool, zeroForOne, amountOut, recipient);
    }

    /// @notice Execute a swap on a Slipstream pool (exact input)
    /// @param pool The pool to swap in
    /// @param zeroForOne Swap direction
    /// @param amountIn Amount to swap in
    /// @param recipient Recipient of output tokens
    /// @return amountOut Amount of tokens received
    function swapExactInput(
        ICLPool pool,
        bool zeroForOne,
        uint256 amountIn,
        address recipient
    ) internal virtual returns (uint256 amountOut) {
        address tokenIn = zeroForOne ? pool.token0() : pool.token1();

        // Deal tokens to this contract for the swap
        deal(tokenIn, address(this), amountIn);

        // Approve pool to spend tokens
        IERC20PermitProxy(tokenIn).approve(address(pool), amountIn);

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

    /// @notice Execute a swap on a Slipstream pool (exact output)
    /// @param pool The pool to swap in
    /// @param zeroForOne Swap direction
    /// @param amountOut Desired output amount
    /// @param recipient Recipient of output tokens
    /// @return amountIn Amount of tokens spent
    function swapExactOutput(
        ICLPool pool,
        bool zeroForOne,
        uint256 amountOut,
        address recipient
    ) internal virtual returns (uint256 amountIn) {
        address tokenIn = zeroForOne ? pool.token0() : pool.token1();

        // Deal a large amount of input tokens (will refund unused)
        // Use a large fixed buffer rather than multiplier to handle cross-decimal scenarios
        uint256 maxAmountIn = amountOut * 10000 + 100 ether; // Large buffer for any token
        deal(tokenIn, address(this), maxAmountIn);

        // Approve pool to spend tokens
        IERC20PermitProxy(tokenIn).approve(address(pool), maxAmountIn);

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
    /*                                Callbacks                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Slipstream swap callback - pay the pool for the swap
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        address payer = abi.decode(data, (address));
        require(payer == address(this), "unexpected payer");

        ICLPool pool = ICLPool(msg.sender);
        if (amount0Delta > 0) IERC20PermitProxy(pool.token0()).transfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) IERC20PermitProxy(pool.token1()).transfer(msg.sender, uint256(amount1Delta));
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool Existence Check                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pool exists and has sufficient liquidity at the fork block
    /// @param poolAddress The address of the pool to check
    /// @return exists True if the pool exists and has non-zero liquidity
    function poolExistsAndHasLiquidity(address poolAddress) internal view returns (bool exists) {
        // Check if address has code
        if (poolAddress.code.length == 0) return false;

        // Try to get liquidity from the pool
        try ICLPool(poolAddress).liquidity() returns (uint128 liq) {
            exists = liq > 0;
        } catch {
            exists = false;
        }
    }

    /// @notice Skip the current test if the pool doesn't exist or has no liquidity
    /// @param poolAddress The address of the pool to check
    /// @param poolName Human-readable name for logging
    function skipIfPoolInvalid(address poolAddress, string memory poolName) internal {
        if (!poolExistsAndHasLiquidity(poolAddress)) {
            console.log("Skipping test - pool not available at fork block:", poolName);
            vm.skip(true);
        }
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

    /// @notice Get tick spacing for common Slipstream pools
    /// @dev Slipstream supports various tick spacings: 1, 50, 100, 200
    function getTickSpacing(uint24 fee) internal pure returns (int24) {
        if (fee == FEE_LOW) return 1;
        if (fee == FEE_MEDIUM) return 1;
        if (fee == FEE_HIGH) return 50;
        if (fee == FEE_HIGHEST) return 100;
        revert("Invalid fee tier");
    }
}
