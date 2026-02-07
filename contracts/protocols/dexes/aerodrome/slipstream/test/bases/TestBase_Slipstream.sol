// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol";
import {FixedPoint96} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FixedPoint96.sol";
import {BitMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/BitMath.sol";
import {LiquidityMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/LiquidityMath.sol";
import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SwapMath.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";

/// @title TestBase_Slipstream
/// @notice Base test contract for Slipstream (Aerodrome CL) tests
/// @dev Uses a mock CLPool implementation since actual Slipstream contracts use incompatible Solidity versions
abstract contract TestBase_Slipstream is Test {
    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    // Standard fee tiers (in pips: 1 pip = 0.0001%)
    uint24 internal constant FEE_LOW = 500;      // 0.05%
    uint24 internal constant FEE_MEDIUM = 3000;  // 0.3%
    uint24 internal constant FEE_HIGH = 10000;   // 1%

    // Standard tick spacings for each fee tier
    int24 internal constant TICK_SPACING_LOW = 1;    // Slipstream default
    int24 internal constant TICK_SPACING_MEDIUM = 50;  // Common for CL pools
    int24 internal constant TICK_SPACING_HIGH = 100;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Base setup - override in inheritors
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Creation                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Create a mock Slipstream pool with specified parameters
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @param fee Fee tier (500, 3000, or 10000)
    /// @param tickSpacing Tick spacing for the pool
    /// @param sqrtPriceX96 Initial sqrt price in Q64.96 format
    /// @return pool The created mock pool
    function createMockPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickSpacing,
        uint160 sqrtPriceX96
    ) internal virtual returns (MockCLPool pool) {
        // Ensure tokens are ordered (token0 < token1)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Create mock pool
        pool = new MockCLPool(token0, token1, fee, tickSpacing);

        // Initialize pool with price
        pool.initialize(sqrtPriceX96);

        vm.label(address(pool), string(abi.encodePacked("MockCLPool_", vm.toString(fee))));
    }

    /// @notice Create a mock pool with 1:1 price ratio
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @param fee Fee tier
    /// @param tickSpacing Tick spacing
    /// @return pool The created pool
    function createMockPoolOneToOne(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickSpacing
    ) internal virtual returns (MockCLPool pool) {
        // 1:1 price = sqrt(1) * 2^96
        uint160 sqrtPriceX96 = uint160(uint256(1) << 96);
        return createMockPool(tokenA, tokenB, fee, tickSpacing, sqrtPriceX96);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Liquidity Management                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Add liquidity to a mock pool position
    /// @param pool The pool to add liquidity to
    /// @param tickLower Lower tick of position
    /// @param tickUpper Upper tick of position
    /// @param liquidity Amount of liquidity to add
    function addLiquidity(
        MockCLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal virtual {
        pool.addLiquidity(tickLower, tickUpper, liquidity);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Price Helpers                               */
    /* -------------------------------------------------------------------------- */

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
        int24 rounded = (tick / tickSpacing) * tickSpacing;

        if (rounded < TickMath.MIN_TICK) {
            return TickMath.MIN_TICK;
        } else if (rounded > TickMath.MAX_TICK) {
            return TickMath.MAX_TICK;
        }

        return rounded;
    }

    /// @notice Get tick spacing for a fee tier (default Slipstream spacings)
    function getTickSpacing(uint24 fee) internal pure returns (int24) {
        if (fee == FEE_LOW) return TICK_SPACING_LOW;
        if (fee == FEE_MEDIUM) return TICK_SPACING_MEDIUM;
        if (fee == FEE_HIGH) return TICK_SPACING_HIGH;
        revert("Invalid fee tier");
    }
}

/// @title MockCLPool
/// @notice Mock implementation of Slipstream CLPool for testing
/// @dev Implements the ICLPool interface with simplified swap execution
contract MockCLPool is ICLPool {
    using TickMath for int24;

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    address public override token0;
    address public override token1;
    uint24 internal _fee;
    uint24 internal _unstakedFee;
    int24 public override tickSpacing;
    address public override factory;

    // slot0 data
    uint160 internal _sqrtPriceX96;
    int24 internal _tick;
    uint16 internal _observationIndex;
    uint16 internal _observationCardinality;
    uint16 internal _observationCardinalityNext;
    bool internal _unlocked;

    // Liquidity
    uint128 internal _liquidity;
    uint128 internal _stakedLiquidity;

    // Fee growth
    uint256 public override feeGrowthGlobal0X128;
    uint256 public override feeGrowthGlobal1X128;
    uint256 public override rewardGrowthGlobalX128;

    // Tick data
    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        int128 stakedLiquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        uint256 rewardGrowthOutsideX128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

    mapping(int24 => TickInfo) internal _ticks;
    mapping(int16 => uint256) internal _tickBitmap;

    /* -------------------------------------------------------------------------- */
    /*                                Constructor                                 */
    /* -------------------------------------------------------------------------- */

    constructor(address _token0, address _token1, uint24 fee_, int24 tickSpacing_) {
        token0 = _token0;
        token1 = _token1;
        _fee = fee_;
        tickSpacing = tickSpacing_;
        factory = address(0);  // Mock factory
        _unlocked = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                           Initialization                                   */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address,
        address,
        address,
        int24,
        address,
        uint160 sqrtPriceX96_
    ) external override {
        _initializeInternal(sqrtPriceX96_);
    }

    function initialize(uint160 sqrtPriceX96_) external {
        _initializeInternal(sqrtPriceX96_);
    }

    function _initializeInternal(uint160 sqrtPriceX96_) internal {
        require(_sqrtPriceX96 == 0, "Already initialized");
        _sqrtPriceX96 = sqrtPriceX96_;
        _tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96_);
        _observationCardinality = 1;
        _observationCardinalityNext = 1;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Constants                                */
    /* -------------------------------------------------------------------------- */

    function fee() external view override returns (uint24) {
        return _fee;
    }

    function unstakedFee() external view override returns (uint24) {
        return _unstakedFee;
    }

    function maxLiquidityPerTick() external pure override returns (uint128) {
        return type(uint128).max / 2;
    }

    function gauge() external pure override returns (address) {
        return address(0);
    }

    function nft() external pure override returns (address) {
        return address(0);
    }

    function factoryRegistry() external pure override returns (address) {
        return address(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Pool State                                 */
    /* -------------------------------------------------------------------------- */

    function slot0()
        external
        view
        override
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            bool unlocked
        )
    {
        return (_sqrtPriceX96, _tick, _observationIndex, _observationCardinality, _observationCardinalityNext, _unlocked);
    }

    function gaugeFees() external pure override returns (uint128, uint128) {
        return (0, 0);
    }

    function rewardRate() external pure override returns (uint256) {
        return 0;
    }

    function rewardReserve() external pure override returns (uint256) {
        return 0;
    }

    function periodFinish() external pure override returns (uint256) {
        return 0;
    }

    function lastUpdated() external pure override returns (uint32) {
        return 0;
    }

    function rollover() external pure override returns (uint256) {
        return 0;
    }

    function liquidity() external view override returns (uint128) {
        return _liquidity;
    }

    function stakedLiquidity() external view override returns (uint128) {
        return _stakedLiquidity;
    }

    function ticks(int24 tick)
        external
        view
        override
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            int128 stakedLiquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            uint256 rewardGrowthOutsideX128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        TickInfo storage info = _ticks[tick];
        return (
            info.liquidityGross,
            info.liquidityNet,
            info.stakedLiquidityNet,
            info.feeGrowthOutside0X128,
            info.feeGrowthOutside1X128,
            info.rewardGrowthOutsideX128,
            info.tickCumulativeOutside,
            info.secondsPerLiquidityOutsideX128,
            info.secondsOutside,
            info.initialized
        );
    }

    function tickBitmap(int16 wordPosition) external view override returns (uint256) {
        return _tickBitmap[wordPosition];
    }

    function positions(bytes32) external pure override returns (uint128, uint256, uint256, uint128, uint128) {
        return (0, 0, 0, 0, 0);
    }

    function observations(uint256) external pure override returns (uint32, int56, uint160, bool) {
        return (0, 0, 0, false);
    }

    function getRewardGrowthInside(int24, int24, uint256) external pure override returns (uint256) {
        return 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Derived State                                 */
    /* -------------------------------------------------------------------------- */

    function observe(uint32[] calldata) external pure override returns (int56[] memory, uint160[] memory) {
        return (new int56[](0), new uint160[](0));
    }

    function snapshotCumulativesInside(int24, int24) external pure override returns (int56, uint160, uint32) {
        return (0, 0, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Actions                                   */
    /* -------------------------------------------------------------------------- */

    function mint(address, int24, int24, uint128, bytes calldata) external pure override returns (uint256, uint256) {
        revert("Use addLiquidity for mock");
    }

    function collect(address, int24, int24, uint128, uint128) external pure override returns (uint128, uint128) {
        return (0, 0);
    }

    function collect(address, int24, int24, uint128, uint128, address) external pure override returns (uint128, uint128) {
        return (0, 0);
    }

    function burn(int24, int24, uint128) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function burn(int24, int24, uint128, address) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    /// @notice Execute swap (simplified implementation for testing)
    /// @dev Implements basic swap math for single-tick quotes
    function swap(
        address,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata
    ) external override returns (int256 amount0, int256 amount1) {
        require(_sqrtPriceX96 != 0, "Not initialized");

        // Simple implementation: compute step using SwapMath
        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = SwapMath.computeSwapStep(
            _sqrtPriceX96,
            sqrtPriceLimitX96,
            _liquidity,
            amountSpecified,
            _fee
        );

        // Update state
        _sqrtPriceX96 = sqrtRatioNextX96;
        _tick = TickMath.getTickAtSqrtRatio(sqrtRatioNextX96);

        // Return deltas
        if (zeroForOne) {
            amount0 = int256(amountIn + feeAmount);
            amount1 = -int256(amountOut);
        } else {
            amount0 = -int256(amountOut);
            amount1 = int256(amountIn + feeAmount);
        }
    }

    function flash(address, uint256, uint256, bytes calldata) external pure override {
        revert("Not implemented");
    }

    function increaseObservationCardinalityNext(uint16) external pure override {
        // No-op
    }

    /* -------------------------------------------------------------------------- */
    /*                              Staking Actions                               */
    /* -------------------------------------------------------------------------- */

    function stake(int128, int24, int24, bool) external pure override {
        revert("Not implemented");
    }

    function updateRewardsGrowthGlobal() external pure override {
        // No-op
    }

    function syncReward(uint256, uint256, uint256) external pure override {
        // No-op
    }

    function setGaugeAndPositionManager(address, address) external pure override {
        // No-op
    }

    function collectFees() external pure override returns (uint128, uint128) {
        return (0, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Test Helpers                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Add liquidity to a position (simplified for testing)
    /// @dev This is a test helper, not part of ICLPool
    function addLiquidity(int24 tickLower, int24 tickUpper, uint128 amount) external {
        require(tickLower < tickUpper, "Invalid range");
        require(tickLower >= TickMath.MIN_TICK && tickUpper <= TickMath.MAX_TICK, "Out of bounds");

        // Update ticks - both get the same liquidityGross
        // liquidityNet: +amount at lower tick, -amount at upper tick
        _updateTickWithLiquidity(tickLower, amount, true);  // isLower = true
        _updateTickWithLiquidity(tickUpper, amount, false); // isLower = false

        // Update liquidity if current tick is in range
        if (_tick >= tickLower && _tick < tickUpper) {
            _liquidity += amount;
        }
    }

    function _updateTickWithLiquidity(int24 tick, uint128 liquidityAmount, bool isLower) internal {
        TickInfo storage info = _ticks[tick];

        // liquidityGross tracks total liquidity referencing this tick (always positive)
        info.liquidityGross += liquidityAmount;

        // liquidityNet tracks net change when crossing this tick
        // When crossing lower tick going up: add liquidity (positive)
        // When crossing upper tick going up: remove liquidity (negative)
        if (isLower) {
            info.liquidityNet += int128(liquidityAmount);
        } else {
            info.liquidityNet -= int128(liquidityAmount);
        }

        if (!info.initialized && info.liquidityGross > 0) {
            info.initialized = true;
            _flipTick(tick);
        } else if (info.initialized && info.liquidityGross == 0) {
            info.initialized = false;
            _flipTick(tick);
        }
    }

    function _flipTick(int24 tick) internal {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        int16 wordPos = int16(compressed >> 8);
        uint8 bitPos = uint8(uint24(compressed % 256));
        _tickBitmap[wordPos] ^= (1 << bitPos);
    }

    /// @notice Set unstaked fee for testing
    function setUnstakedFee(uint24 unstakedFee_) external {
        _unstakedFee = unstakedFee_;
    }

    /// @notice Set pool state directly for testing
    function setState(uint160 sqrtPriceX96_, int24 tick_, uint128 liquidity_) external {
        _sqrtPriceX96 = sqrtPriceX96_;
        _tick = tick_;
        _liquidity = liquidity_;
    }
}
