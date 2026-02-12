// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {SlipstreamRewardUtils} from
    "@crane/contracts/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.sol";

/// @title SlipstreamRewardUtils Tests
/// @notice Unit tests for SlipstreamRewardUtils library
contract SlipstreamRewardUtilsTest is Test {
    using SlipstreamRewardUtils for ICLPool;

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    MockRewardPool internal mockPool;
    ICLPool internal pool;
    address internal token0;
    address internal token1;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public {
        token0 = address(0x1);
        token1 = address(0x2);

        mockPool = new MockRewardPool(token0, token1);
        pool = ICLPool(address(mockPool));

        vm.label(address(mockPool), "MockRewardPool");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Pool Reward State Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_getPoolRewardState_returnsCorrectValues() public view {
        SlipstreamRewardUtils.PoolRewardState memory state = SlipstreamRewardUtils._getPoolRewardState(pool);

        assertEq(state.rewardRate, pool.rewardRate());
        assertEq(state.rewardReserve, pool.rewardReserve());
        assertEq(state.periodFinish, pool.periodFinish());
        assertEq(state.lastUpdated, pool.lastUpdated());
        assertEq(state.rewardGrowthGlobalX128, pool.rewardGrowthGlobalX128());
        assertEq(state.stakedLiquidity, pool.stakedLiquidity());
    }

    function test_isRewardActive_returnsTrueWhenActive() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);

        assertTrue(SlipstreamRewardUtils._isRewardActive(pool));
    }

    function test_isRewardActive_returnsFalseWhenPeriodEnded() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp - 1);

        assertFalse(SlipstreamRewardUtils._isRewardActive(pool));
    }

    function test_isRewardActive_returnsFalseWhenNoReserve() public {
        mockPool.setRewardParams(1e18, 0, block.timestamp + 1 weeks);

        assertFalse(SlipstreamRewardUtils._isRewardActive(pool));
    }

    function test_getRewardPeriodRemaining_returnsCorrectValue() public {
        uint256 finishTime = block.timestamp + 1 weeks;
        mockPool.setRewardParams(1e18, 1000e18, finishTime);

        assertEq(SlipstreamRewardUtils._getRewardPeriodRemaining(pool), 1 weeks);
    }

    function test_getRewardPeriodRemaining_returnsZeroWhenEnded() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp - 1);

        assertEq(SlipstreamRewardUtils._getRewardPeriodRemaining(pool), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Effective Reward Growth Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_getEffectiveRewardGrowthGlobalX128_noTimeDelta() public {
        // Warp to reasonable timestamp
        vm.warp(1_000_000);

        // Set last updated to now
        mockPool.setLastUpdated(uint32(block.timestamp));
        mockPool.setRewardGrowthGlobalX128(1000 * Q128);
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);

        uint256 effective = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Should equal the current value since no time has passed
        assertEq(effective, 1000 * Q128);
    }

    function test_getEffectiveRewardGrowthGlobalX128_withTimeDelta() public {
        // Warp to reasonable timestamp
        vm.warp(1_000_000);

        // Set last updated to 100 seconds ago
        mockPool.setLastUpdated(uint32(block.timestamp - 100));
        mockPool.setRewardGrowthGlobalX128(1000 * Q128);
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);

        uint256 effective = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Expected: 1000 * Q128 + (1e18 * 100 * Q128 / 100e18)
        // = 1000 * Q128 + (100e18 * Q128 / 100e18)
        // = 1000 * Q128 + 1 * Q128
        // = 1001 * Q128
        uint256 expectedReward = 1e18 * 100; // 100 seconds of rewards at 1e18 rate
        uint256 expectedGrowth = (expectedReward * Q128) / 100e18;
        uint256 expected = 1000 * Q128 + expectedGrowth;

        assertEq(effective, expected);
    }

    function test_getEffectiveRewardGrowthGlobalX128_capsAtReserve() public {
        // Warp to reasonable timestamp
        vm.warp(1_000_000);

        // Set last updated to a long time ago - more than reserve can cover
        mockPool.setLastUpdated(uint32(block.timestamp - 10000));
        mockPool.setRewardGrowthGlobalX128(1000 * Q128);
        mockPool.setRewardParams(1e18, 100e18, block.timestamp + 1 weeks); // Only 100 reserve
        mockPool.setStakedLiquidity(100e18);

        uint256 effective = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Expected: 1000 * Q128 + (100e18 * Q128 / 100e18) - capped at reserve
        uint256 expectedGrowth = (100e18 * Q128) / 100e18;
        uint256 expected = 1000 * Q128 + expectedGrowth;

        assertEq(effective, expected);
    }

    function test_getEffectiveRewardGrowthGlobalX128_zeroStakedLiquidity() public {
        // Warp to reasonable timestamp
        vm.warp(1_000_000);

        mockPool.setLastUpdated(uint32(block.timestamp - 100));
        mockPool.setRewardGrowthGlobalX128(1000 * Q128);
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(0);

        uint256 effective = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // No staked liquidity means no growth
        assertEq(effective, 1000 * Q128);
    }

    /* -------------------------------------------------------------------------- */
    /*                       Pending Reward Estimation Tests                      */
    /* -------------------------------------------------------------------------- */

    function test_estimatePendingReward_basic() public {
        // Setup pool state
        mockPool.setLastUpdated(uint32(block.timestamp));
        mockPool.setRewardGrowthGlobalX128(0);
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        // Set tick range that contains current tick
        int24 tickLower = -100;
        int24 tickUpper = 100;

        // Set reward growth inside for the tick range
        mockPool.setRewardGrowthInside(tickLower, tickUpper, 10 * Q128);

        // Estimate pending rewards
        // Position has 50e18 liquidity, last recorded growth was 5 * Q128
        uint128 liquidity = 50e18;
        uint256 positionLastGrowth = 5 * Q128;

        uint256 pending = SlipstreamRewardUtils._estimatePendingReward(pool, tickLower, tickUpper, liquidity, positionLastGrowth);

        // Growth delta = 10 * Q128 - 5 * Q128 = 5 * Q128
        // Pending = (5 * Q128 * 50e18) / Q128 = 5 * 50e18 = 250e18
        assertEq(pending, 250e18);
    }

    function test_estimatePendingReward_detailed() public {
        // Setup pool state
        mockPool.setLastUpdated(uint32(block.timestamp));
        mockPool.setRewardGrowthGlobalX128(1000 * Q128);
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;
        mockPool.setRewardGrowthInside(tickLower, tickUpper, 50 * Q128);

        SlipstreamRewardUtils.RewardEstimateParams memory params = SlipstreamRewardUtils.RewardEstimateParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 25e18,
            positionRewardGrowthInsideLastX128: 20 * Q128
        });

        SlipstreamRewardUtils.RewardEstimateResult memory result = SlipstreamRewardUtils._estimatePendingRewardDetailed(params);

        // Growth delta = 50 * Q128 - 20 * Q128 = 30 * Q128
        // Pending = (30 * Q128 * 25e18) / Q128 = 750e18
        assertEq(result.pendingReward, 750e18);
        assertEq(result.rewardGrowthInsideX128, 50 * Q128);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Reward Rate Calculation Tests                       */
    /* -------------------------------------------------------------------------- */

    function test_calculateRewardRateForRange_inRange() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;

        uint256 ratePerLiquidity = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);

        // Rate = (1e18 * Q128) / 100e18 = 0.01 * Q128
        uint256 expected = (1e18 * Q128) / 100e18;
        assertEq(ratePerLiquidity, expected);
    }

    function test_calculateRewardRateForRange_outOfRange_below() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(-200); // Below range

        int24 tickLower = -100;
        int24 tickUpper = 100;

        uint256 ratePerLiquidity = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);

        // Out of range = 0
        assertEq(ratePerLiquidity, 0);
    }

    function test_calculateRewardRateForRange_outOfRange_above() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(100); // At upper bound (exclusive)

        int24 tickLower = -100;
        int24 tickUpper = 100;

        uint256 ratePerLiquidity = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);

        // At upper tick = out of range
        assertEq(ratePerLiquidity, 0);
    }

    function test_calculateRewardRateForRange_zeroStakedLiquidity() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(0);
        mockPool.setCurrentTick(0);

        uint256 ratePerLiquidity = SlipstreamRewardUtils._calculateRewardRateForRange(pool, -100, 100);

        assertEq(ratePerLiquidity, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Duration Reward Estimation Tests                      */
    /* -------------------------------------------------------------------------- */

    function test_estimateRewardForDuration_basic() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;
        uint128 liquidity = 50e18;
        uint256 duration = 1 days;

        uint256 estimated = SlipstreamRewardUtils._estimateRewardForDuration(pool, tickLower, tickUpper, liquidity, duration);

        // Rate per liquidity = 1e18 * Q128 / 100e18
        // Estimated = ratePerLiq * duration * liquidity / Q128
        // = (1e18 * Q128 / 100e18) * 1 days * 50e18 / Q128
        // = 1e18 * 1 days * 50e18 / 100e18
        // = 1e18 * 86400 * 0.5
        // = 43200e18 (allow 1 wei rounding)
        assertApproxEqAbs(estimated, 43200e18, 1);
    }

    function test_estimateRewardForDuration_capsAtRemaining() public {
        uint256 remaining = 1 days;
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + remaining);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;
        uint128 liquidity = 50e18;
        uint256 requestedDuration = 7 days; // More than remaining

        uint256 estimated = SlipstreamRewardUtils._estimateRewardForDuration(pool, tickLower, tickUpper, liquidity, requestedDuration);

        // Should be capped at 1 day (allow 1 wei rounding)
        uint256 expectedForOneDay = 43200e18;
        assertApproxEqAbs(estimated, expectedForOneDay, 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                           APR Calculation Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_calculateRewardAPR_basic() public {
        mockPool.setRewardParams(1e18, 365 days * 1e18, block.timestamp + 365 days);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;
        uint128 liquidity = 100e18;
        uint256 liquidityValue = 1000e18; // Value in reward tokens

        uint256 aprBps = SlipstreamRewardUtils._calculateRewardAPR(pool, tickLower, tickUpper, liquidity, liquidityValue);

        // Yearly rewards = 1e18/s * 365 days * (100e18/100e18) = ~31.5M tokens
        // APR = (31536000e18 / 1000e18) * 10000 = 315360000 bps = 31536x
        // This is expected for high emission rate
        assertGt(aprBps, 0);
    }

    function test_calculateRewardAPR_zeroLiquidityValue() public {
        mockPool.setRewardParams(1e18, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(100e18);
        mockPool.setCurrentTick(0);

        uint256 aprBps = SlipstreamRewardUtils._calculateRewardAPR(pool, -100, 100, 100e18, 0);

        assertEq(aprBps, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Claim Preparation Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_prepareClaimParams() public pure {
        address gauge = address(0x123);
        uint256 tokenId = 456;

        SlipstreamRewardUtils.ClaimParams memory params = SlipstreamRewardUtils._prepareClaimParams(gauge, tokenId);

        assertEq(params.gauge, gauge);
        assertEq(params.tokenId, tokenId);
    }

    function test_needsRewardGrowthUpdate_true() public {
        mockPool.setLastUpdated(uint32(block.timestamp - 1));

        assertTrue(SlipstreamRewardUtils._needsRewardGrowthUpdate(pool));
    }

    function test_needsRewardGrowthUpdate_false() public {
        mockPool.setLastUpdated(uint32(block.timestamp));

        assertFalse(SlipstreamRewardUtils._needsRewardGrowthUpdate(pool));
    }

    /* -------------------------------------------------------------------------- */
    /*                              Fuzz Tests                                    */
    /* -------------------------------------------------------------------------- */

    function testFuzz_estimatePendingReward(
        uint128 posLiquidity,
        uint256 rewardGrowthDelta
    ) public {
        // Warp to reasonable timestamp
        vm.warp(1_000_000);

        // Bound inputs to reasonable values - limit rewardGrowthDelta to avoid overflow
        posLiquidity = uint128(bound(posLiquidity, 1e6, 1e24));
        rewardGrowthDelta = bound(rewardGrowthDelta, 0, 1e24);

        mockPool.setLastUpdated(uint32(block.timestamp));
        mockPool.setRewardGrowthGlobalX128(0);
        mockPool.setCurrentTick(0);

        int24 tickLower = -100;
        int24 tickUpper = 100;

        // Set the reward growth inside - cap to prevent overflow
        uint256 growthInside = (rewardGrowthDelta * Q128) / 1e18; // Scale to Q128
        mockPool.setRewardGrowthInside(tickLower, tickUpper, growthInside);

        uint256 pending = SlipstreamRewardUtils._estimatePendingReward(pool, tickLower, tickUpper, posLiquidity, 0);

        // Verify calculation: (growthInside * posLiquidity) / Q128
        uint256 expected = (growthInside * uint256(posLiquidity)) / Q128;
        assertEq(pending, expected);
    }

    function testFuzz_calculateRewardRateForRange(
        uint256 poolRewardRate,
        uint128 stakedLiq,
        int24 currentTick,
        int24 tickLower,
        int24 tickUpper
    ) public {
        // Bound inputs
        poolRewardRate = bound(poolRewardRate, 0, 1e30);
        stakedLiq = uint128(bound(stakedLiq, 1, type(uint128).max));

        // Ensure valid tick range
        tickLower = int24(bound(tickLower, -887272, 887271));
        tickUpper = int24(bound(tickUpper, tickLower + 1, 887272));
        currentTick = int24(bound(currentTick, -887272, 887272));

        mockPool.setRewardParams(poolRewardRate, 1000e18, block.timestamp + 1 weeks);
        mockPool.setStakedLiquidity(stakedLiq);
        mockPool.setCurrentTick(currentTick);

        uint256 rate = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);

        if (currentTick < tickLower || currentTick >= tickUpper || poolRewardRate == 0) {
            assertEq(rate, 0, "Should be zero when out of range or no rewards");
        } else {
            uint256 expected = (poolRewardRate * Q128) / stakedLiq;
            assertEq(rate, expected, "Rate should match expected calculation");
        }
    }
}

/// @title MockRewardPool
/// @notice Mock pool implementation with configurable reward state for testing
contract MockRewardPool is ICLPool {
    address public override token0;
    address public override token1;

    // Configurable reward state
    uint256 internal _rewardRate;
    uint256 internal _rewardReserve;
    uint256 internal _periodFinish;
    uint32 internal _lastUpdated;
    uint256 internal _rewardGrowthGlobalX128;
    uint128 internal _stakedLiquidity;
    int24 internal _currentTick;

    // Reward growth inside mapping
    mapping(bytes32 => uint256) internal _rewardGrowthInside;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    /* -------------------------------------------------------------------------- */
    /*                            State Setters                                   */
    /* -------------------------------------------------------------------------- */

    function setRewardParams(uint256 rate, uint256 reserve, uint256 finish) external {
        _rewardRate = rate;
        _rewardReserve = reserve;
        _periodFinish = finish;
    }

    function setLastUpdated(uint32 timestamp) external {
        _lastUpdated = timestamp;
    }

    function setRewardGrowthGlobalX128(uint256 growth) external {
        _rewardGrowthGlobalX128 = growth;
    }

    function setStakedLiquidity(uint128 liquidity) external {
        _stakedLiquidity = liquidity;
    }

    function setCurrentTick(int24 tick) external {
        _currentTick = tick;
    }

    function setRewardGrowthInside(int24 tickLower, int24 tickUpper, uint256 growth) external {
        bytes32 key = keccak256(abi.encode(tickLower, tickUpper));
        _rewardGrowthInside[key] = growth;
    }

    /* -------------------------------------------------------------------------- */
    /*                        ICLPool Implementation                              */
    /* -------------------------------------------------------------------------- */

    function factory() external pure override returns (address) {
        return address(0);
    }

    function fee() external pure override returns (uint24) {
        return 3000;
    }

    function unstakedFee() external pure override returns (uint24) {
        return 0;
    }

    function tickSpacing() external pure override returns (int24) {
        return 60;
    }

    function maxLiquidityPerTick() external pure override returns (uint128) {
        return type(uint128).max;
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
        return (0, _currentTick, 0, 1, 1, true);
    }

    function feeGrowthGlobal0X128() external pure override returns (uint256) {
        return 0;
    }

    function feeGrowthGlobal1X128() external pure override returns (uint256) {
        return 0;
    }

    function rewardGrowthGlobalX128() external view override returns (uint256) {
        return _rewardGrowthGlobalX128;
    }

    function gaugeFees() external pure override returns (uint128, uint128) {
        return (0, 0);
    }

    function rewardRate() external view override returns (uint256) {
        return _rewardRate;
    }

    function rewardReserve() external view override returns (uint256) {
        return _rewardReserve;
    }

    function periodFinish() external view override returns (uint256) {
        return _periodFinish;
    }

    function lastUpdated() external view override returns (uint32) {
        return _lastUpdated;
    }

    function rollover() external pure override returns (uint256) {
        return 0;
    }

    function liquidity() external pure override returns (uint128) {
        return 0;
    }

    function stakedLiquidity() external view override returns (uint128) {
        return _stakedLiquidity;
    }

    function ticks(int24)
        external
        pure
        override
        returns (
            uint128,
            int128,
            int128,
            uint256,
            uint256,
            uint256,
            int56,
            uint160,
            uint32,
            bool
        )
    {
        return (0, 0, 0, 0, 0, 0, 0, 0, 0, false);
    }

    function tickBitmap(int16) external pure override returns (uint256) {
        return 0;
    }

    function positions(bytes32) external pure override returns (uint128, uint256, uint256, uint128, uint128) {
        return (0, 0, 0, 0, 0);
    }

    function observations(uint256) external pure override returns (uint32, int56, uint160, bool) {
        return (0, 0, 0, false);
    }

    function getRewardGrowthInside(int24 tickLower, int24 tickUpper, uint256)
        external
        view
        override
        returns (uint256)
    {
        bytes32 key = keccak256(abi.encode(tickLower, tickUpper));
        return _rewardGrowthInside[key];
    }

    function observe(uint32[] calldata) external pure override returns (int56[] memory, uint160[] memory) {
        return (new int56[](0), new uint160[](0));
    }

    function snapshotCumulativesInside(int24, int24) external pure override returns (int56, uint160, uint32) {
        return (0, 0, 0);
    }

    function initialize(address, address, address, int24, address, uint160) external pure override {}

    function mint(address, int24, int24, uint128, bytes calldata) external pure override returns (uint256, uint256) {
        return (0, 0);
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

    function swap(address, bool, int256, uint160, bytes calldata) external pure override returns (int256, int256) {
        return (0, 0);
    }

    function flash(address, uint256, uint256, bytes calldata) external pure override {}

    function increaseObservationCardinalityNext(uint16) external pure override {}

    function stake(int128, int24, int24, bool) external pure override {}

    function updateRewardsGrowthGlobal() external pure override {}

    function syncReward(uint256, uint256, uint256) external pure override {}

    function setGaugeAndPositionManager(address, address) external pure override {}

    function collectFees() external pure override returns (uint128, uint128) {
        return (0, 0);
    }
}
