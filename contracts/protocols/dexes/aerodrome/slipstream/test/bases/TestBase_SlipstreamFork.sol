// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {ICLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLFactory.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol";
import {FixedPoint96} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FixedPoint96.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/// @title TestBase_SlipstreamFork
/// @notice Base test contract for Slipstream fork tests on Base mainnet
/// @dev Tests are skipped if INFURA_KEY environment variable is not set
abstract contract TestBase_SlipstreamFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Production Addresses                          */
    /* -------------------------------------------------------------------------- */

    // Slipstream (Aerodrome CL) on Base mainnet
    // Pool factory: https://basescan.org/address/0x5e7BB104d84c7CB9B682AaC2F3d509f5F406809A
    // Pool implementation (used by factory): https://basescan.org/address/0xeC8E5342B19977B4eF8892e02D8DAEcfa1315831
    address public constant SLIPSTREAM_FACTORY = 0x5e7BB104d84c7CB9B682AaC2F3d509f5F406809A;
    address public constant SLIPSTREAM_POOL_IMPLEMENTATION = 0xeC8E5342B19977B4eF8892e02D8DAEcfa1315831;

    // See: https://basescan.org/address/0xbe6d8f0d05cc4be24d5167a3ef062215be6d18a5
    address public constant SLIPSTREAM_SWAP_ROUTER = 0xBE6D8f0d05cC4be24d5167a3eF062215bE6D18a5;

    // See: https://basescan.org/address/0x254cF9E1E6e233aa1AC962CB9B05b2cfeAaE15b0
    address public constant SLIPSTREAM_QUOTER = 0x254cF9E1E6e233aa1AC962CB9B05b2cfeAaE15b0;

    // Common tokens on Base
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant AERO = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;

    /* -------------------------------------------------------------------------- */
    /*                              Standard Tick Spacings                        */
    /* -------------------------------------------------------------------------- */

    int24 public constant TICK_SPACING_1 = 1;      // 0.01% fee
    int24 public constant TICK_SPACING_50 = 50;    // 0.05% fee
    int24 public constant TICK_SPACING_100 = 100;  // 0.05% fee (same as 50)
    int24 public constant TICK_SPACING_200 = 200;  // 0.30% fee
    int24 public constant TICK_SPACING_2000 = 2000; // 1.00% fee

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    ICLFactory internal productionFactory;
    uint256 internal baseFork;
    bool internal forkEnabled;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Check if INFURA_KEY is available
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     forkEnabled = false;
        //     return;
        // }

        // Create and select the Base mainnet fork
        // try vm.createFork("base_mainnet_infura") returns (uint256 forkId) {
        //     baseFork = forkId;
        //     vm.selectFork(baseFork);
        //     forkEnabled = true;

        //     // Initialize production factory reference
        //     productionFactory = ICLFactory(SLIPSTREAM_FACTORY);

        //     // Label known addresses for better traces
        //     vm.label(SLIPSTREAM_FACTORY, "SlipstreamFactory");
        //     vm.label(SLIPSTREAM_POOL_IMPLEMENTATION, "SlipstreamPoolImplementation");
        //     vm.label(SLIPSTREAM_SWAP_ROUTER, "SlipstreamSwapRouter");
        //     vm.label(SLIPSTREAM_QUOTER, "SlipstreamQuoter");
        //     vm.label(WETH, "WETH");
        //     vm.label(USDC, "USDC");
        //     vm.label(AERO, "AERO");
        // } catch {
        //     forkEnabled = false;
        // }
        vm.createFork("base_mainnet_infura");
        // Initialize production factory reference
        productionFactory = ICLFactory(SLIPSTREAM_FACTORY);

        // Label known addresses for better traces
        vm.label(SLIPSTREAM_FACTORY, "SlipstreamFactory");
        vm.label(SLIPSTREAM_POOL_IMPLEMENTATION, "SlipstreamPoolImplementation");
        vm.label(SLIPSTREAM_SWAP_ROUTER, "SlipstreamSwapRouter");
        vm.label(SLIPSTREAM_QUOTER, "SlipstreamQuoter");
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(AERO, "AERO");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Skip Modifier                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Skips the test if fork is not enabled
    modifier onlyFork() {
        if (!forkEnabled) {
            emit log("Skipping: INFURA_KEY not set or fork failed");
            return;
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Get an existing pool from the production factory
    /// @param token0 First token address
    /// @param token1 Second token address
    /// @param tickSpacing The tick spacing
    /// @return pool The pool address, or address(0) if not found
    function getProductionPool(address token0, address token1, int24 tickSpacing)
        internal
        view
        returns (ICLPool pool)
    {
        address poolAddr = productionFactory.getPool(token0, token1, tickSpacing);
        if (poolAddr != address(0)) {
            pool = ICLPool(poolAddr);
        }
    }

    /// @notice Encode a price as a sqrt price in Q64.96 format
    /// @param reserve0 Reserve of token0
    /// @param reserve1 Reserve of token1
    /// @return sqrtPriceX96 The sqrt price in Q64.96 format
    function encodePriceSqrt(uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        require(reserve0 > 0, "reserve0 must be > 0");

        uint256 sqrtReserve0 = BetterMath._sqrt(reserve0);
        uint256 sqrtReserve1 = BetterMath._sqrt(reserve1);

        sqrtPriceX96 = uint160(FullMath.mulDiv(sqrtReserve1, FixedPoint96.Q96, sqrtReserve0));
    }

    /// @notice Get nearest tick aligned to tick spacing
    /// @param tick The tick to align
    /// @param tickSpacing The tick spacing
    /// @return Aligned tick
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

    /// @notice Deal tokens to an address (fork only)
    /// @param token The token address
    /// @param to The recipient
    /// @param amount The amount to deal
    function dealTokens(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
    }

    /// @notice Check if the fork is active and on the correct network
    function assertForkActive() internal view {
        require(forkEnabled, "Fork not enabled");
        require(block.chainid == 8453, "Not on Base mainnet");
    }

    /// @notice Log pool state for debugging
    function logPoolState(ICLPool pool) internal {
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            bool unlocked
        ) = pool.slot0();

        emit log_named_address("Pool", address(pool));
        emit log_named_uint("sqrtPriceX96", sqrtPriceX96);
        emit log_named_int("tick", tick);
        emit log_named_uint("observationIndex", observationIndex);
        emit log_named_uint("observationCardinality", observationCardinality);
        emit log_named_uint("observationCardinalityNext", observationCardinalityNext);
        emit log_named_string("unlocked", unlocked ? "true" : "false");
        emit log_named_uint("liquidity", pool.liquidity());
        emit log_named_uint("fee", pool.fee());
        emit log_named_int("tickSpacing", pool.tickSpacing());
    }
}
