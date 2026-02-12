// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {SlipstreamRewardUtils} from
    "@crane/contracts/protocols/dexes/aerodrome/slipstream/SlipstreamRewardUtils.sol";
import {TestBase_SlipstreamFork} from "./TestBase_SlipstreamFork.sol";

/// @title SlipstreamRewardUtils Fork Tests
/// @notice Validates reward estimation accuracy against production Slipstream pools on Base mainnet
/// @dev Tests _getPoolRewardState, _estimatePendingReward, _calculateRewardRateForRange, etc.
///      against real pools with active gauges and reward distributions.
contract SlipstreamRewardUtils_Fork_Test is TestBase_SlipstreamFork {
    using SlipstreamRewardUtils for ICLPool;

    /* -------------------------------------------------------------------------- */
    /*                              Pool Reward Helpers                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pool has active rewards at the fork block
    /// @param poolAddress The pool to check
    /// @return hasRewards True if the pool has a gauge with active rewards
    function poolHasActiveRewards(address poolAddress) internal view returns (bool hasRewards) {
        if (poolAddress.code.length == 0) return false;

        try ICLPool(poolAddress).gauge() returns (address gauge_) {
            if (gauge_ == address(0)) return false;

            try ICLPool(poolAddress).rewardRate() returns (uint256 rate) {
                try ICLPool(poolAddress).periodFinish() returns (uint256 finish) {
                    hasRewards = rate > 0 && finish > block.timestamp;
                } catch {
                    hasRewards = false;
                }
            } catch {
                hasRewards = false;
            }
        } catch {
            hasRewards = false;
        }
    }

    /// @notice Skip test if pool has no active rewards
    function skipIfNoRewards(address poolAddress, string memory poolName) internal {
        if (!poolHasActiveRewards(poolAddress)) {
            console.log("Skipping test - no active rewards at fork block:", poolName);
            vm.skip(true);
        }
    }

    /// @notice Find a pool with active rewards among well-known pools
    /// @return pool The pool with active rewards, or address(0) if none found
    function findPoolWithRewards() internal view returns (address pool) {
        address[3] memory candidates = [WETH_USDC_CL_500, WETH_USDC_CL_100, cbBTC_WETH_CL];

        for (uint256 i = 0; i < candidates.length; i++) {
            if (poolHasActiveRewards(candidates[i])) {
                return candidates[i];
            }
        }
        return address(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Pool Reward State Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that _getPoolRewardState reads real pool state correctly
    function test_getPoolRewardState_readsLiveState() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards found at fork block");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        SlipstreamRewardUtils.PoolRewardState memory state = SlipstreamRewardUtils._getPoolRewardState(pool);

        // Verify state fields match direct pool calls
        assertEq(state.rewardRate, pool.rewardRate(), "rewardRate mismatch");
        assertEq(state.rewardReserve, pool.rewardReserve(), "rewardReserve mismatch");
        assertEq(state.periodFinish, pool.periodFinish(), "periodFinish mismatch");
        assertEq(state.lastUpdated, pool.lastUpdated(), "lastUpdated mismatch");
        assertEq(state.rewardGrowthGlobalX128, pool.rewardGrowthGlobalX128(), "rewardGrowthGlobalX128 mismatch");
        assertEq(state.stakedLiquidity, pool.stakedLiquidity(), "stakedLiquidity mismatch");

        // Log for debugging
        console.log("Pool reward state at block", FORK_BLOCK);
        console.log("  rewardRate:", state.rewardRate);
        console.log("  rewardReserve:", state.rewardReserve);
        console.log("  periodFinish:", state.periodFinish);
        console.log("  lastUpdated:", state.lastUpdated);
        console.log("  stakedLiquidity:", state.stakedLiquidity);
    }

    /// @notice Test _isRewardActive on a pool with active rewards
    function test_isRewardActive_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        bool active = SlipstreamRewardUtils._isRewardActive(pool);

        assertTrue(active, "Pool should have active rewards");

        console.log("Pool reward active:", active);
        console.log("  periodFinish:", pool.periodFinish());
        console.log("  block.timestamp:", block.timestamp);
        console.log("  rewardReserve:", pool.rewardReserve());
    }

    /// @notice Test _getRewardPeriodRemaining returns non-zero for active pool
    function test_getRewardPeriodRemaining_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        uint256 remaining = SlipstreamRewardUtils._getRewardPeriodRemaining(pool);

        assertTrue(remaining > 0, "Should have time remaining in reward period");
        assertEq(remaining, pool.periodFinish() - block.timestamp, "Remaining should match manual calc");

        console.log("Reward period remaining:", remaining, "seconds");
    }

    /* -------------------------------------------------------------------------- */
    /*                   Effective Reward Growth Global Tests                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Test that effective reward growth >= stored reward growth on live pool
    /// @dev The effective growth includes pending rewards since lastUpdated
    function test_effectiveRewardGrowth_geStoredGrowth() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        uint256 storedGrowth = pool.rewardGrowthGlobalX128();
        uint256 effectiveGrowth = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Effective should be >= stored (pending rewards added)
        assertTrue(effectiveGrowth >= storedGrowth, "Effective growth should be >= stored growth");

        uint256 delta = effectiveGrowth - storedGrowth;
        console.log("Reward growth:");
        console.log("  stored:", storedGrowth);
        console.log("  effective:", effectiveGrowth);
        console.log("  delta (pending):", delta);
    }

    /// @notice Test that effective reward growth increases with time (vm.warp)
    function test_effectiveRewardGrowth_increasesWithTime() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        // Skip if no staked liquidity (growth can't increase without it)
        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        uint256 growthNow = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Warp 1 hour forward (within period)
        uint256 remaining = SlipstreamRewardUtils._getRewardPeriodRemaining(pool);
        uint256 warpDuration = remaining > 3600 ? 3600 : remaining / 2;

        if (warpDuration == 0) {
            console.log("Skipping - reward period too short to warp");
            vm.skip(true);
        }

        vm.warp(block.timestamp + warpDuration);

        uint256 growthAfter = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        assertTrue(growthAfter > growthNow, "Effective growth should increase after time warp");

        console.log("Growth after", warpDuration, "seconds:");
        console.log("  before:", growthNow);
        console.log("  after:", growthAfter);
        console.log("  increase:", growthAfter - growthNow);
    }

    /// @notice Test that effective growth caps at reward reserve
    /// @dev Warp past periodFinish to verify reward doesn't exceed reserve
    function test_effectiveRewardGrowth_capsAtReserve() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        SlipstreamRewardUtils.PoolRewardState memory state = SlipstreamRewardUtils._getPoolRewardState(pool);

        // Calculate max possible growth from remaining reserve
        uint256 Q128 = SlipstreamRewardUtils.Q128;
        uint256 maxAdditionalGrowth = (state.rewardReserve * Q128) / state.stakedLiquidity;
        uint256 maxPossibleGrowth = state.rewardGrowthGlobalX128 + maxAdditionalGrowth;

        // Warp far past the period end
        vm.warp(state.periodFinish + 365 days);

        uint256 effectiveGrowth = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);

        // Effective growth should not exceed max possible from reserve
        assertTrue(
            effectiveGrowth <= maxPossibleGrowth,
            "Effective growth should be capped by reward reserve"
        );

        console.log("Reserve cap test:");
        console.log("  maxPossibleGrowth:", maxPossibleGrowth);
        console.log("  effectiveGrowth (warped):", effectiveGrowth);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Reward Growth Inside Range Tests                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _getRewardGrowthInside on a real pool with known tick range
    function test_getRewardGrowthInside_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        // Create a wide range around current tick
        int24 tickLower = nearestUsableTick(currentTick - 10 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 10 * tickSpacing, tickSpacing);

        uint256 growthInside = SlipstreamRewardUtils._getRewardGrowthInside(pool, tickLower, tickUpper);

        // Compare with pool's own getRewardGrowthInside using effective global
        uint256 effectiveGlobal = SlipstreamRewardUtils._getEffectiveRewardGrowthGlobalX128(pool);
        uint256 directGrowthInside = pool.getRewardGrowthInside(tickLower, tickUpper, effectiveGlobal);

        assertEq(growthInside, directGrowthInside, "Growth inside should match direct pool call");

        console.log("Reward growth inside tick range:");
        console.log("  tickLower:", tickLower);
        console.log("  tickUpper:", tickUpper);
        console.log("  growthInside:", growthInside);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Reward Rate Calculation Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _calculateRewardRateForRange returns non-zero for in-range position
    function test_calculateRewardRateForRange_inRange_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        // Position that spans the current tick (in-range)
        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);

        uint256 ratePerLiqX128 = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);

        assertTrue(ratePerLiqX128 > 0, "In-range position should have non-zero reward rate");

        console.log("In-range reward rate per liquidity (X128):", ratePerLiqX128);
        console.log("  currentTick:", currentTick);
        console.log("  tickLower:", tickLower);
        console.log("  tickUpper:", tickUpper);
    }

    /// @notice Test _calculateRewardRateForRange returns zero for out-of-range position
    function test_calculateRewardRateForRange_outOfRange_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        // Position entirely above current tick (out-of-range)
        int24 tickLower = nearestUsableTick(currentTick + 100 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 200 * tickSpacing, tickSpacing);

        uint256 rateAbove = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);
        assertEq(rateAbove, 0, "Above-range position should have zero reward rate");

        // Position entirely below current tick (out-of-range)
        tickLower = nearestUsableTick(currentTick - 200 * tickSpacing, tickSpacing);
        tickUpper = nearestUsableTick(currentTick - 100 * tickSpacing, tickSpacing);

        uint256 rateBelow = SlipstreamRewardUtils._calculateRewardRateForRange(pool, tickLower, tickUpper);
        assertEq(rateBelow, 0, "Below-range position should have zero reward rate");
    }

    /* -------------------------------------------------------------------------- */
    /*                     Pending Reward Estimation Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _estimatePendingReward increases proportionally with time
    /// @dev Uses vm.warp to simulate time passing and checks reward proportionality
    function test_estimatePendingReward_proportionalToTime() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        // In-range position
        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);
        uint128 liquidity = 1e18;

        // Get current reward growth inside as the "last" snapshot
        uint256 rewardGrowthInsideLast = SlipstreamRewardUtils._getRewardGrowthInside(pool, tickLower, tickUpper);

        // Save current timestamp for reference
        uint256 startTime = block.timestamp;

        // Warp 1 hour and measure pending reward
        vm.warp(startTime + 1 hours);
        uint256 reward1h = SlipstreamRewardUtils._estimatePendingReward(
            pool, tickLower, tickUpper, liquidity, rewardGrowthInsideLast
        );

        // Warp 2 hours (from start) and measure pending reward
        vm.warp(startTime + 2 hours);
        uint256 reward2h = SlipstreamRewardUtils._estimatePendingReward(
            pool, tickLower, tickUpper, liquidity, rewardGrowthInsideLast
        );

        console.log("Pending reward proportionality:");
        console.log("  reward after 1h:", reward1h);
        console.log("  reward after 2h:", reward2h);

        // 2h reward should be approximately 2x the 1h reward
        // Allow 1% tolerance for rounding
        if (reward1h > 0) {
            uint256 expectedDoubled = reward1h * 2;
            uint256 tolerance = expectedDoubled / 100; // 1%
            if (tolerance == 0) tolerance = 1;
            assertApproxEqAbs(reward2h, expectedDoubled, tolerance, "2h reward should be ~2x 1h reward");
        }
    }

    /// @notice Test _estimatePendingRewardDetailed returns consistent values
    function test_estimatePendingRewardDetailed_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);

        // Simulate that the position was staked at the current reward growth
        uint256 growthInsideLast = SlipstreamRewardUtils._getRewardGrowthInside(pool, tickLower, tickUpper);

        // Warp forward so there are pending rewards
        vm.warp(block.timestamp + 1 hours);

        SlipstreamRewardUtils.RewardEstimateParams memory params = SlipstreamRewardUtils.RewardEstimateParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: 1e18,
            positionRewardGrowthInsideLastX128: growthInsideLast
        });

        SlipstreamRewardUtils.RewardEstimateResult memory result =
            SlipstreamRewardUtils._estimatePendingRewardDetailed(params);

        // Verify the simple estimate matches detailed
        uint256 simpleEstimate = SlipstreamRewardUtils._estimatePendingReward(
            pool, tickLower, tickUpper, 1e18, growthInsideLast
        );

        assertEq(result.pendingReward, simpleEstimate, "Detailed and simple estimates should match");

        // Growth inside should be >= last
        assertTrue(
            result.rewardGrowthInsideX128 >= growthInsideLast,
            "Current growth inside should be >= last snapshot"
        );

        // Effective global should be >= stored
        assertTrue(
            result.effectiveRewardGrowthGlobalX128 >= pool.rewardGrowthGlobalX128(),
            "Effective global should be >= stored"
        );

        console.log("Detailed estimate:");
        console.log("  pendingReward:", result.pendingReward);
        console.log("  rewardGrowthInsideX128:", result.rewardGrowthInsideX128);
        console.log("  effectiveGlobalX128:", result.effectiveRewardGrowthGlobalX128);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Duration Estimation Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _estimateRewardForDuration on live pool
    function test_estimateRewardForDuration_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);
        uint128 liquidity = 1e18;

        // Estimate for 1 day
        uint256 dailyReward = SlipstreamRewardUtils._estimateRewardForDuration(
            pool, tickLower, tickUpper, liquidity, 1 days
        );

        // Estimate for 7 days
        uint256 weeklyReward = SlipstreamRewardUtils._estimateRewardForDuration(
            pool, tickLower, tickUpper, liquidity, 7 days
        );

        console.log("Duration-based reward estimates:");
        console.log("  daily reward:", dailyReward);
        console.log("  weekly reward:", weeklyReward);

        // Weekly should be ~7x daily (capped at remaining period)
        uint256 remaining = SlipstreamRewardUtils._getRewardPeriodRemaining(pool);
        if (remaining >= 7 days) {
            // Full 7 days available - weekly should be ~7x daily
            if (dailyReward > 0) {
                assertApproxEqRel(weeklyReward, dailyReward * 7, 0.01e18, "Weekly should be ~7x daily");
            }
        } else {
            // Period caps the duration - weekly can't exceed what remaining allows
            assertTrue(weeklyReward >= dailyReward, "Weekly should be >= daily even if capped");
        }
    }

    /// @notice Test _estimateRewardForDuration caps at remaining period
    function test_estimateRewardForDuration_capsAtRemaining() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);
        uint128 liquidity = 1e18;

        uint256 remaining = SlipstreamRewardUtils._getRewardPeriodRemaining(pool);

        // Estimate for exactly remaining time
        uint256 rewardRemaining = SlipstreamRewardUtils._estimateRewardForDuration(
            pool, tickLower, tickUpper, liquidity, remaining
        );

        // Estimate for way more time (should be capped at remaining)
        uint256 rewardExcess = SlipstreamRewardUtils._estimateRewardForDuration(
            pool, tickLower, tickUpper, liquidity, remaining + 365 days
        );

        assertEq(rewardExcess, rewardRemaining, "Excess duration should be capped to remaining period");

        console.log("Duration capping:");
        console.log("  remaining seconds:", remaining);
        console.log("  reward for remaining:", rewardRemaining);
        console.log("  reward for remaining + 365d:", rewardExcess);
    }

    /* -------------------------------------------------------------------------- */
    /*                           APR Calculation Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _calculateRewardAPR returns realistic values on live pool
    function test_calculateRewardAPR_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);
        uint128 liquidity = 1e18;

        // Assume 1 AERO liquidity value for simplicity
        uint256 liquidityValue = 1e18;

        uint256 aprBps = SlipstreamRewardUtils._calculateRewardAPR(
            pool, tickLower, tickUpper, liquidity, liquidityValue
        );

        console.log("Reward APR (bps):", aprBps);
        console.log("  APR %:", aprBps / 100);

        // APR should be non-zero for active pool with non-zero staked liquidity
        assertTrue(aprBps > 0, "APR should be non-zero for active pool");

        // APR should be finite (not overflow/near max uint256)
        assertTrue(aprBps < type(uint256).max / 2, "APR should be finite");

        // Verify proportionality: doubling liquidityValue should halve APR
        uint256 aprBps2x = SlipstreamRewardUtils._calculateRewardAPR(
            pool, tickLower, tickUpper, liquidity, liquidityValue * 2
        );
        assertApproxEqRel(aprBps2x, aprBps / 2, 0.01e18, "APR should halve when liquidityValue doubles");
    }

    /// @notice Test _calculateRewardAPR returns 0 for zero liquidity value
    function test_calculateRewardAPR_zeroLiquidityValue_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);

        uint256 aprBps = SlipstreamRewardUtils._calculateRewardAPR(pool, tickLower, tickUpper, 1e18, 0);

        assertEq(aprBps, 0, "APR should be 0 when liquidity value is 0");
    }

    /* -------------------------------------------------------------------------- */
    /*                        Claim Preparation Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test _needsRewardGrowthUpdate on live pool
    function test_needsRewardGrowthUpdate_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        uint32 lastUpdated = pool.lastUpdated();

        // At fork block, block.timestamp should be >= lastUpdated
        bool needsUpdate = SlipstreamRewardUtils._needsRewardGrowthUpdate(pool);

        if (block.timestamp > lastUpdated) {
            assertTrue(needsUpdate, "Should need update when timestamp > lastUpdated");
        } else {
            assertFalse(needsUpdate, "Should not need update when timestamp == lastUpdated");
        }

        console.log("Needs reward growth update:", needsUpdate);
        console.log("  block.timestamp:", block.timestamp);
        console.log("  lastUpdated:", lastUpdated);
    }

    /// @notice Test _prepareClaimParams returns correct values
    function test_prepareClaimParams_livePool() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);
        address gauge_ = pool.gauge();
        uint256 tokenId = 12345;

        SlipstreamRewardUtils.ClaimParams memory params =
            SlipstreamRewardUtils._prepareClaimParams(gauge_, tokenId);

        assertEq(params.gauge, gauge_, "gauge should match");
        assertEq(params.tokenId, tokenId, "tokenId should match");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Cross-Validation Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify that pending reward estimation is consistent with reward rate
    /// @dev Pending rewards from warp should approximately equal rewardRate * duration / stakedLiquidity * position_liquidity
    function test_pendingReward_consistentWithRewardRate() public {
        address poolAddr = findPoolWithRewards();
        if (poolAddr == address(0)) {
            console.log("Skipping - no pool with active rewards");
            vm.skip(true);
        }

        ICLPool pool = ICLPool(poolAddr);

        if (pool.stakedLiquidity() == 0) {
            console.log("Skipping - no staked liquidity");
            vm.skip(true);
        }

        (, int24 currentTick,,,,) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        // Use full-range-ish position so all staked liquidity is "ours" in the same range
        int24 tickLower = nearestUsableTick(currentTick - 5 * tickSpacing, tickSpacing);
        int24 tickUpper = nearestUsableTick(currentTick + 5 * tickSpacing, tickSpacing);

        // Use large liquidity for precision
        uint128 posLiquidity = 1e18;

        // Snapshot reward growth at current time
        uint256 growthInsideLast = SlipstreamRewardUtils._getRewardGrowthInside(pool, tickLower, tickUpper);

        // Warp exactly 1 hour
        uint256 duration = 1 hours;
        vm.warp(block.timestamp + duration);

        // Get pending reward
        uint256 pendingReward = SlipstreamRewardUtils._estimatePendingReward(
            pool, tickLower, tickUpper, posLiquidity, growthInsideLast
        );

        // Calculate expected from duration estimation
        // Note: we need to warp back to get the duration estimate at the original time
        vm.warp(block.timestamp - duration);
        uint256 durationEstimate = SlipstreamRewardUtils._estimateRewardForDuration(
            pool, tickLower, tickUpper, posLiquidity, duration
        );

        console.log("Pending vs Duration estimate consistency:");
        console.log("  pending reward (1h warp):", pendingReward);
        console.log("  duration estimate (1h):", durationEstimate);

        // These should be approximately equal
        // Allow 5% tolerance because reward growth is tick-dependent
        if (durationEstimate > 0) {
            assertApproxEqRel(
                pendingReward,
                durationEstimate,
                0.05e18,
                "Pending reward should approximately match duration estimate"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                        All Pools Diagnostic Test                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Log reward state for all well-known pools (diagnostic, always passes)
    function test_logAllPoolRewardStates() public view {
        address[3] memory pools = [WETH_USDC_CL_500, WETH_USDC_CL_100, cbBTC_WETH_CL];
        string[3] memory names = ["WETH_USDC_CL_500", "WETH_USDC_CL_100", "cbBTC_WETH_CL"];

        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].code.length == 0) {
                console.log(names[i], ": no code at address");
                continue;
            }

            ICLPool pool = ICLPool(pools[i]);

            console.log("--- Pool:", names[i], "---");

            try pool.gauge() returns (address gauge_) {
                console.log("  gauge:", gauge_);
            } catch {
                console.log("  gauge: (call failed)");
                continue;
            }

            try pool.rewardRate() returns (uint256 rate) {
                console.log("  rewardRate:", rate);
            } catch {
                console.log("  rewardRate: (call failed)");
            }

            try pool.rewardReserve() returns (uint256 reserve) {
                console.log("  rewardReserve:", reserve);
            } catch {
                console.log("  rewardReserve: (call failed)");
            }

            try pool.periodFinish() returns (uint256 finish) {
                console.log("  periodFinish:", finish);
                console.log("  block.timestamp:", block.timestamp);
                console.log("  active:", finish > block.timestamp);
            } catch {
                console.log("  periodFinish: (call failed)");
            }

            try pool.stakedLiquidity() returns (uint128 staked) {
                console.log("  stakedLiquidity:", staked);
            } catch {
                console.log("  stakedLiquidity: (call failed)");
            }

            try pool.liquidity() returns (uint128 liq) {
                console.log("  liquidity:", liq);
            } catch {
                console.log("  liquidity: (call failed)");
            }
        }
    }
}
