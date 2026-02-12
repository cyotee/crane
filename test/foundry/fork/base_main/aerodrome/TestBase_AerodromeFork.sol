// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BASE_MAIN} from "@crane/contracts/constants/networks/BASE_MAIN.sol";

/// @title TestBase_AerodromeFork
/// @notice Base test contract for Aerodrome V1 fork tests against Base mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
///      Aerodrome V1 pools (both volatile xy=k and stable x^3y+xy^3=k curves)
abstract contract TestBase_AerodromeFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2026 - adjust as needed)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 28_000_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    IPoolFactory internal aerodromeFactory;
    IRouter internal aerodromeRouter;

    /// @notice Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 internal constant AERO_FEE_DENOM = 10000;

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

    // Volatile pools (xy = k curve)
    // WETH/USDC volatile pool - high liquidity pair
    address internal constant WETH_USDC_VOLATILE = 0xcDAC0d6c6C59727a65F871236188350531885C43;
    // WETH/AERO volatile pool
    address internal constant WETH_AERO_VOLATILE = 0x7f670f78B17dEC44d5Ef68a48740b6f8849cc2e6;

    // Stable pools (x^3y + xy^3 = k curve)
    // USDC/USDbC stable pool - stablecoin pair
    address internal constant USDC_USDbC_STABLE = 0x27a8Afa3Bd49406e48a074350fB7b2020c43B2bD;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `base_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("base_mainnet_infura", FORK_BLOCK);

        // Set up contract references
        aerodromeFactory = IPoolFactory(BASE_MAIN.AERODROME_POOL_FACTORY);
        aerodromeRouter = IRouter(BASE_MAIN.AERODROME_ROUTER);

        vm.label(address(aerodromeFactory), "AerodromePoolFactory");
        vm.label(address(aerodromeRouter), "AerodromeRouter");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDbC, "USDbC");
        vm.label(DAI, "DAI");
        vm.label(AERO, "AERO");
        vm.label(cbBTC, "cbBTC");

        // Label well-known pools
        vm.label(WETH_USDC_VOLATILE, "WETH_USDC_VOLATILE");
        vm.label(WETH_AERO_VOLATILE, "WETH_AERO_VOLATILE");
        vm.label(USDC_USDbC_STABLE, "USDC_USDbC_STABLE");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get pool at mainnet address
    function getPool(address poolAddress) internal pure returns (IPool) {
        return IPool(poolAddress);
    }

    /// @notice Check if a token is token0 of the pool
    function tokenIsToken0(IPool pool, address token) internal view returns (bool) {
        return pool.token0() == token;
    }

    /// @notice Get pool reserves
    function getPoolReserves(IPool pool)
        internal
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        (reserve0, reserve1,) = pool.getReserves();
    }

    /// @notice Get pool metadata
    function getPoolMetadata(IPool pool)
        internal
        view
        returns (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            bool stable,
            address token0,
            address token1
        )
    {
        (decimals0, decimals1, reserve0, reserve1, stable, token0, token1) = pool.metadata();
    }

    /// @notice Get fee for a pool
    function getPoolFee(IPool pool) internal view returns (uint256) {
        bool isStable = pool.stable();
        return aerodromeFactory.getFee(address(pool), isStable);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap Execution                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a swap via the Aerodrome router
    /// @param tokenIn Token to sell
    /// @param tokenOut Token to buy
    /// @param amountIn Amount of tokenIn to swap
    /// @param stable True for stable pool, false for volatile
    /// @param recipient Address to receive output tokens
    /// @return amountOut Amount of tokenOut received
    function swapViaRouter(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool stable,
        address recipient
    ) internal returns (uint256 amountOut) {
        // Deal tokens to this contract
        deal(tokenIn, address(this), amountIn);

        // Approve router
        IERC20(tokenIn).approve(address(aerodromeRouter), amountIn);

        // Build route
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({
            from: tokenIn,
            to: tokenOut,
            stable: stable,
            factory: address(aerodromeFactory)
        });

        // Execute swap
        uint256[] memory amounts = aerodromeRouter.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin - no slippage protection for tests
            routes,
            recipient,
            block.timestamp + 1
        );

        return amounts[amounts.length - 1];
    }

    /// @notice Execute a swap directly on the pool (bypassing router)
    /// @dev This is useful for comparing pool output directly
    /// @param pool The pool to swap in
    /// @param tokenIn Token to sell
    /// @param amountIn Amount of tokenIn to swap
    /// @param recipient Address to receive output tokens
    /// @return amountOut Amount of tokenOut received
    function swapViaPool(
        IPool pool,
        address tokenIn,
        uint256 amountIn,
        address recipient
    ) internal returns (uint256 amountOut) {
        address token0 = pool.token0();
        address token1 = pool.token1();
        bool zeroForOne = tokenIn == token0;

        // Deal tokens and transfer to pool
        deal(tokenIn, address(this), amountIn);
        IERC20(tokenIn).transfer(address(pool), amountIn);

        // Get expected output
        amountOut = pool.getAmountOut(amountIn, tokenIn);

        // Execute swap
        if (zeroForOne) {
            pool.swap(0, amountOut, recipient, "");
        } else {
            pool.swap(amountOut, 0, recipient, "");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool Existence Check                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pool exists and has sufficient liquidity at the fork block
    /// @param poolAddress The address of the pool to check
    /// @return exists True if the pool exists and has non-zero reserves
    function poolExistsAndHasLiquidity(address poolAddress) internal view returns (bool exists) {
        // Check if address has code
        if (poolAddress.code.length == 0) return false;

        // Try to get reserves from the pool
        try IPool(poolAddress).getReserves() returns (uint256 r0, uint256 r1, uint256) {
            exists = r0 > 0 && r1 > 0;
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

    /// @notice Assert quote matches actual within tolerance (basis points)
    /// @param quoted The quoted amount
    /// @param actual The actual amount from swap
    /// @param toleranceBps Tolerance in basis points (10 = 0.1%)
    /// @param message Error message
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

    /// @notice Assert quote matches actual within 0.1% tolerance (default)
    function assertQuoteAccuracy(uint256 quoted, uint256 actual, string memory message) internal pure {
        assertQuoteAccuracy(quoted, actual, 10, message); // 10 bps = 0.1%
    }

    /// @notice Assert exact equality for integer amounts
    function assertExactMatch(uint256 expected, uint256 actual, string memory message) internal pure {
        assertEq(expected, actual, message);
    }
}
