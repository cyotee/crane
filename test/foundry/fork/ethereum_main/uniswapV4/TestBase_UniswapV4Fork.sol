// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPoolManager, StateLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {PoolKey} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "../../../../../contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {IHooks} from "../../../../../contracts/protocols/dexes/uniswap/v4/interfaces/IHooks.sol";
import {TickMath} from "../../../../../contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";

/// @title TestBase_UniswapV4Fork
/// @notice Base test contract for Uniswap V4 fork tests against Ethereum mainnet
/// @dev V4 Architecture Key Points:
///      - PoolManager is a singleton (vs V3's separate pool contracts)
///      - Pools are identified by PoolKey (currency0, currency1, fee, tickSpacing, hooks)
///      - PoolId is derived from keccak256(abi.encode(poolKey))
///      - State is read via StateLibrary using extsload (no unlock required for views)
///      - Currency type wraps address (address(0) = native ETH)
abstract contract TestBase_UniswapV4Fork is Test {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2025 - after V4 launch)
    /// V4 launched on Ethereum mainnet in Jan 2025
    uint256 internal constant FORK_BLOCK = 21_500_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    /// @dev V4 PoolManager singleton - all pools managed by this contract
    IPoolManager internal poolManager;

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /// @dev Native ETH represented as address(0) in V4
    address internal constant NATIVE_ETH = address(0);

    /* -------------------------------------------------------------------------- */
    /*                              V4 Fee Tiers                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Standard fee tiers in V4 (in hundredths of a bip)
    /// Fee = feePips / 1e6, so 500 = 0.05%, 3000 = 0.3%, 10000 = 1%
    uint24 internal constant FEE_LOWEST = 100;    // 0.01%
    uint24 internal constant FEE_LOW = 500;       // 0.05%
    uint24 internal constant FEE_MEDIUM = 3000;   // 0.3%
    uint24 internal constant FEE_HIGH = 10000;    // 1%

    /// @dev Dynamic fee flag (highest bit set indicates pool uses dynamic fees via hooks)
    uint24 internal constant FEE_DYNAMIC = 0x800000;

    /* -------------------------------------------------------------------------- */
    /*                              V4 Tick Spacings                               */
    /* -------------------------------------------------------------------------- */

    /// @dev Standard tick spacings corresponding to fee tiers
    int24 internal constant TICK_SPACING_1 = 1;    // For 0.01% fee
    int24 internal constant TICK_SPACING_10 = 10;   // For 0.05% fee
    int24 internal constant TICK_SPACING_60 = 60;   // For 0.3% fee
    int24 internal constant TICK_SPACING_200 = 200; // For 1% fee

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        if (bytes(infuraKey).length == 0) {
            vm.skip(true);
        }

        // Create fork at specific block for reproducibility
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up PoolManager reference
        // Note: Using the constant from ETHEREUM_MAIN (has typo "UNSWAP" in original)
        poolManager = IPoolManager(ETHEREUM_MAIN.UNSWAP_V4_POOL_MNANAGER);
        vm.label(address(poolManager), "PoolManager");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(DAI, "DAI");
        vm.label(WBTC, "WBTC");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Key Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a PoolKey for a standard pair (no hooks)
    /// @dev V4-specific: PoolKey replaces pool addresses
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @param fee Fee in hundredths of a bip (e.g., 3000 = 0.3%)
    /// @param tickSpacing Tick spacing for the pool
    /// @return key The constructed PoolKey with currencies sorted
    function createPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickSpacing
    ) internal pure returns (PoolKey memory key) {
        return createPoolKey(tokenA, tokenB, fee, tickSpacing, IHooks(address(0)));
    }

    /// @notice Create a PoolKey with hooks
    /// @dev V4-specific: Hooks address must be sorted with currencies
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @param fee Fee in hundredths of a bip
    /// @param tickSpacing Tick spacing for the pool
    /// @param hooks Hooks contract address
    /// @return key The constructed PoolKey with currencies sorted
    function createPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks
    ) internal pure returns (PoolKey memory key) {
        // Sort currencies (currency0 < currency1)
        Currency currency0;
        Currency currency1;
        if (tokenA < tokenB) {
            currency0 = Currency.wrap(tokenA);
            currency1 = Currency.wrap(tokenB);
        } else {
            currency0 = Currency.wrap(tokenB);
            currency1 = Currency.wrap(tokenA);
        }

        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });
    }

    /// @notice Get PoolId from a PoolKey
    /// @dev V4-specific: PoolId = keccak256(abi.encode(poolKey))
    function getPoolId(PoolKey memory key) internal pure returns (PoolId) {
        return key.toId();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool State Helpers                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Get current pool state (slot0 data)
    /// @dev V4-specific: Uses StateLibrary to read via extsload
    /// @param key The pool key
    /// @return sqrtPriceX96 Current sqrt price in Q64.96 format
    /// @return tick Current tick
    /// @return protocolFee Protocol fee (if any)
    /// @return lpFee LP fee for swaps
    function getPoolState(PoolKey memory key)
        internal
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee)
    {
        PoolId poolId = key.toId();
        (sqrtPriceX96, tick, protocolFee, lpFee) = poolManager.getSlot0(poolId);
    }

    /// @notice Get pool liquidity
    /// @dev V4-specific: Uses StateLibrary to read via extsload
    /// @param key The pool key
    /// @return liquidity Current pool liquidity
    function getPoolLiquidity(PoolKey memory key) internal view returns (uint128 liquidity) {
        PoolId poolId = key.toId();
        liquidity = poolManager.getLiquidity(poolId);
    }

    /// @notice Check if a pool is initialized
    /// @dev V4-specific: Pool is initialized if sqrtPriceX96 != 0
    /// @param key The pool key
    /// @return True if pool is initialized
    function isPoolInitialized(PoolKey memory key) internal view returns (bool) {
        (uint160 sqrtPriceX96, , , ) = getPoolState(key);
        return sqrtPriceX96 != 0;
    }

    /// @notice Get tick info for a specific tick
    /// @dev V4-specific: Uses StateLibrary to read via extsload
    /// @param key The pool key
    /// @param tick The tick to query
    /// @return liquidityGross Total liquidity referencing this tick
    /// @return liquidityNet Net liquidity change when crossing this tick
    function getTickInfo(PoolKey memory key, int24 tick)
        internal
        view
        returns (uint128 liquidityGross, int128 liquidityNet)
    {
        PoolId poolId = key.toId();
        (liquidityGross, liquidityNet, , ) = poolManager.getTickInfo(poolId, tick);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Direction Helpers                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Determine if token is currency0 in the pool
    /// @dev V4-specific: Currencies are sorted, currency0 < currency1
    /// @param key The pool key
    /// @param token Token address to check
    /// @return True if token is currency0
    function tokenIsCurrency0(PoolKey memory key, address token) internal pure returns (bool) {
        return Currency.unwrap(key.currency0) == token;
    }

    /// @notice Get swap direction for tokenIn -> tokenOut
    /// @dev V4-specific: zeroForOne means currency0 -> currency1
    /// @param key The pool key
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @return zeroForOne True if swapping currency0 for currency1
    function getSwapDirection(
        PoolKey memory key,
        address tokenIn,
        address tokenOut
    ) internal pure returns (bool zeroForOne) {
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        require(
            (tokenIn == token0 && tokenOut == token1) || (tokenIn == token1 && tokenOut == token0),
            "V4FORK:TOKEN_MISMATCH"
        );

        return tokenIn == token0;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Tick Helpers                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get nearest usable tick aligned to tick spacing
    /// @dev Same logic as V3, tick must be multiple of tickSpacing
    /// @param tick The tick to align
    /// @param tickSpacing The pool's tick spacing
    /// @return The nearest usable tick
    function nearestUsableTick(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 rounded = (tick / tickSpacing) * tickSpacing;

        if (rounded < TickMath.MIN_TICK) {
            return ((TickMath.MIN_TICK / tickSpacing) + 1) * tickSpacing;
        } else if (rounded > TickMath.MAX_TICK) {
            return (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        }

        return rounded;
    }

    /// @notice Get tick spacing for a fee tier
    /// @dev V4: tickSpacing is part of PoolKey, but these are common defaults
    /// @param fee Fee in hundredths of a bip
    /// @return tickSpacing The corresponding tick spacing
    function getTickSpacing(uint24 fee) internal pure returns (int24 tickSpacing) {
        if (fee == FEE_LOWEST) return TICK_SPACING_1;
        if (fee == FEE_LOW) return TICK_SPACING_10;
        if (fee == FEE_MEDIUM) return TICK_SPACING_60;
        if (fee == FEE_HIGH) return TICK_SPACING_200;
        revert("V4FORK:INVALID_FEE");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Assertion Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert quote matches actual within tolerance
    /// @param quoted The quoted amount
    /// @param actual The actual amount
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

    /// @notice Assert quote matches actual within 0.1% tolerance
    function assertQuoteAccuracy(uint256 quoted, uint256 actual, string memory message) internal pure {
        assertQuoteAccuracy(quoted, actual, 10, message); // 10 bps = 0.1%
    }

    /* -------------------------------------------------------------------------- */
    /*                              Currency Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if currency is native ETH
    /// @dev V4-specific: Native ETH is represented as address(0)
    /// @param currency The currency to check
    /// @return True if currency is native ETH
    function isNativeETH(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == address(0);
    }

    /// @notice Get the underlying address of a currency
    /// @param currency The currency
    /// @return The underlying address
    function currencyToAddress(Currency currency) internal pure returns (address) {
        return Currency.unwrap(currency);
    }

    /// @notice Convert address to Currency
    /// @param token The token address
    /// @return The Currency wrapper
    function addressToCurrency(address token) internal pure returns (Currency) {
        return Currency.wrap(token);
    }
}
