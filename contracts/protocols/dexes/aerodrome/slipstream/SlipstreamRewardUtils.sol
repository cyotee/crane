// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {ICLPool} from "./interfaces/ICLPool.sol";

/// @title SlipstreamRewardUtils
/// @notice Utility library for estimating and calculating Slipstream (Aerodrome CL) rewards
/// @dev Provides view functions to estimate pending rewards and calculate reward rates for positions
library SlipstreamRewardUtils {
    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Q128 fixed point format constant (2^128)
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    /* -------------------------------------------------------------------------- */
    /*                               Reward Structs                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for estimating pending rewards
    struct RewardEstimateParams {
        ICLPool pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 positionRewardGrowthInsideLastX128;
    }

    /// @notice Result of reward estimation
    struct RewardEstimateResult {
        uint256 pendingReward;
        uint256 rewardGrowthInsideX128;
        uint256 effectiveRewardGrowthGlobalX128;
    }

    /// @notice Pool reward state snapshot
    struct PoolRewardState {
        uint256 rewardRate;
        uint256 rewardReserve;
        uint256 periodFinish;
        uint32 lastUpdated;
        uint256 rewardGrowthGlobalX128;
        uint128 stakedLiquidity;
    }

    /// @notice Parameters for claim preparation
    struct ClaimParams {
        address gauge;
        uint256 tokenId;
    }

    /* -------------------------------------------------------------------------- */
    /*                           Reward State Queries                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Get the current reward state of a pool
    /// @param pool The Slipstream CL pool
    /// @return state The pool's reward state
    function _getPoolRewardState(ICLPool pool) internal view returns (PoolRewardState memory state) {
        state.rewardRate = pool.rewardRate();
        state.rewardReserve = pool.rewardReserve();
        state.periodFinish = pool.periodFinish();
        state.lastUpdated = pool.lastUpdated();
        state.rewardGrowthGlobalX128 = pool.rewardGrowthGlobalX128();
        state.stakedLiquidity = pool.stakedLiquidity();
    }

    /// @notice Check if rewards are currently active for the pool
    /// @param pool The Slipstream CL pool
    /// @return active True if rewards are being distributed
    function _isRewardActive(ICLPool pool) internal view returns (bool active) {
        return block.timestamp < pool.periodFinish() && pool.rewardReserve() > 0;
    }

    /// @notice Get the time remaining in the current reward period
    /// @param pool The Slipstream CL pool
    /// @return remaining Seconds remaining in reward period (0 if ended)
    function _getRewardPeriodRemaining(ICLPool pool) internal view returns (uint256 remaining) {
        uint256 periodFinish = pool.periodFinish();
        if (block.timestamp >= periodFinish) {
            return 0;
        }
        return periodFinish - block.timestamp;
    }

    /* -------------------------------------------------------------------------- */
    /*                      Reward Growth Calculations                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculate the effective reward growth global including pending updates
    /// @dev This accounts for rewards that have accrued since lastUpdated but not yet been recorded
    /// @param pool The Slipstream CL pool
    /// @return effectiveRewardGrowthGlobalX128 The effective reward growth global in X128 format
    function _getEffectiveRewardGrowthGlobalX128(ICLPool pool)
        internal
        view
        returns (uint256 effectiveRewardGrowthGlobalX128)
    {
        PoolRewardState memory state = _getPoolRewardState(pool);
        return _calculateEffectiveRewardGrowthGlobalX128(state);
    }

    /// @notice Calculate effective reward growth global from a state snapshot
    /// @param state The pool reward state
    /// @return effectiveRewardGrowthGlobalX128 The effective reward growth global in X128 format
    function _calculateEffectiveRewardGrowthGlobalX128(PoolRewardState memory state)
        internal
        view
        returns (uint256 effectiveRewardGrowthGlobalX128)
    {
        effectiveRewardGrowthGlobalX128 = state.rewardGrowthGlobalX128;

        uint256 timeDelta = block.timestamp - state.lastUpdated;

        if (timeDelta > 0 && state.rewardReserve > 0 && state.stakedLiquidity > 0) {
            uint256 reward = state.rewardRate * timeDelta;

            // Cap reward at available reserve
            if (reward > state.rewardReserve) {
                reward = state.rewardReserve;
            }

            // Add pending rewards to growth global
            effectiveRewardGrowthGlobalX128 += _mulDiv(reward, Q128, state.stakedLiquidity);
        }
    }

    /// @notice Get the reward growth inside a tick range
    /// @dev Wrapper around pool's getRewardGrowthInside with effective global calculation
    /// @param pool The Slipstream CL pool
    /// @param tickLower Lower tick of the range
    /// @param tickUpper Upper tick of the range
    /// @return rewardGrowthInsideX128 The reward growth inside the range in X128 format
    function _getRewardGrowthInside(ICLPool pool, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint256 rewardGrowthInsideX128)
    {
        uint256 effectiveGlobal = _getEffectiveRewardGrowthGlobalX128(pool);
        return pool.getRewardGrowthInside(tickLower, tickUpper, effectiveGlobal);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Pending Reward Estimation                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Estimate pending rewards for a staked position
    /// @dev This calculates the rewards that would be claimable if getReward were called now
    /// @param pool The Slipstream CL pool
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity The position's liquidity
    /// @param positionRewardGrowthInsideLastX128 The position's last recorded reward growth inside
    /// @return pendingReward The estimated pending reward amount
    function _estimatePendingReward(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 positionRewardGrowthInsideLastX128
    ) internal view returns (uint256 pendingReward) {
        RewardEstimateParams memory params = RewardEstimateParams({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            positionRewardGrowthInsideLastX128: positionRewardGrowthInsideLastX128
        });

        RewardEstimateResult memory result = _estimatePendingRewardDetailed(params);
        return result.pendingReward;
    }

    /// @notice Estimate pending rewards with detailed result
    /// @param params The reward estimation parameters
    /// @return result Detailed estimation result including growth values
    function _estimatePendingRewardDetailed(RewardEstimateParams memory params)
        internal
        view
        returns (RewardEstimateResult memory result)
    {
        result.effectiveRewardGrowthGlobalX128 = _getEffectiveRewardGrowthGlobalX128(params.pool);

        result.rewardGrowthInsideX128 = params.pool.getRewardGrowthInside(
            params.tickLower, params.tickUpper, result.effectiveRewardGrowthGlobalX128
        );

        // Calculate reward delta
        uint256 rewardGrowthDelta = result.rewardGrowthInsideX128 - params.positionRewardGrowthInsideLastX128;

        // Convert to token amount
        result.pendingReward = _mulDiv(rewardGrowthDelta, params.liquidity, Q128);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Reward Rate Calculations                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculate the reward rate per unit of liquidity in the given tick range
    /// @dev Only returns non-zero if the current tick is within the range (position is in-range)
    /// @param pool The Slipstream CL pool
    /// @param tickLower Lower tick of the range
    /// @param tickUpper Upper tick of the range
    /// @return rewardRatePerLiquidityX128 Reward rate per liquidity in X128 format (per second)
    function _calculateRewardRateForRange(ICLPool pool, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint256 rewardRatePerLiquidityX128)
    {
        // Check if position is in range
        (, int24 currentTick,,,,) = pool.slot0();

        if (currentTick < tickLower || currentTick >= tickUpper) {
            // Position is out of range, no rewards accruing
            return 0;
        }

        // Get staked liquidity
        uint128 stakedLiquidity = pool.stakedLiquidity();
        if (stakedLiquidity == 0) {
            return 0;
        }

        uint256 rewardRate = pool.rewardRate();
        if (rewardRate == 0) {
            return 0;
        }

        // Reward rate per liquidity per second in X128
        rewardRatePerLiquidityX128 = _mulDiv(rewardRate, Q128, stakedLiquidity);
    }

    /// @notice Estimate rewards that would accrue over a time period for a position
    /// @dev Assumes reward rate and liquidity remain constant
    /// @param pool The Slipstream CL pool
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity The position's liquidity
    /// @param duration Time period in seconds
    /// @return estimatedReward Estimated reward amount for the period
    function _estimateRewardForDuration(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 duration
    ) internal view returns (uint256 estimatedReward) {
        uint256 rewardRatePerLiquidityX128 = _calculateRewardRateForRange(pool, tickLower, tickUpper);

        if (rewardRatePerLiquidityX128 == 0) {
            return 0;
        }

        // Cap duration at remaining reward period
        uint256 remaining = _getRewardPeriodRemaining(pool);
        if (duration > remaining) {
            duration = remaining;
        }

        // Calculate: (rewardRatePerLiquidity * liquidity * duration) / Q128
        // Rearranged for precision: (rewardRatePerLiquidity * duration * liquidity) / Q128
        uint256 rewardX128 = rewardRatePerLiquidityX128 * duration;
        estimatedReward = _mulDiv(rewardX128, liquidity, Q128);
    }

    /// @notice Calculate APR for a position based on current reward rate
    /// @dev Returns APR in basis points (1% = 100, 100% = 10000)
    /// @param pool The Slipstream CL pool
    /// @param tickLower Lower tick of the position
    /// @param tickUpper Upper tick of the position
    /// @param liquidity The position's liquidity
    /// @param liquidityValueInRewardToken Estimated value of liquidity in reward token terms
    /// @return aprBps APR in basis points
    function _calculateRewardAPR(
        ICLPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 liquidityValueInRewardToken
    ) internal view returns (uint256 aprBps) {
        if (liquidityValueInRewardToken == 0) {
            return 0;
        }

        // Estimate yearly rewards (365 days)
        uint256 yearlyRewards = _estimateRewardForDuration(pool, tickLower, tickUpper, liquidity, 365 days);

        // APR = (yearlyRewards / liquidityValue) * 10000 (basis points)
        aprBps = (yearlyRewards * 10000) / liquidityValueInRewardToken;
    }

    /* -------------------------------------------------------------------------- */
    /*                          Claim Preparation Helpers                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Prepare parameters for claiming rewards from gauge
    /// @dev Returns the ClaimParams struct needed for gauge interaction
    /// @param gauge The gauge contract address
    /// @param tokenId The NFT position token ID
    /// @return params The prepared claim parameters
    function _prepareClaimParams(address gauge, uint256 tokenId) internal pure returns (ClaimParams memory params) {
        params.gauge = gauge;
        params.tokenId = tokenId;
    }

    /// @notice Check if a position needs to call updateRewardsGrowthGlobal before claiming
    /// @dev Returns true if there's a time delta since last pool update
    /// @param pool The Slipstream CL pool
    /// @return needsUpdate True if pool.updateRewardsGrowthGlobal() should be called
    function _needsRewardGrowthUpdate(ICLPool pool) internal view returns (bool needsUpdate) {
        return block.timestamp > pool.lastUpdated();
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Math                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculates floor(a×b÷denominator) with full precision
    /// @dev Simplified version for this library - uses unchecked for gas efficiency
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function _mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "Division by zero");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256
        require(denominator > prod1, "Overflow");

        // 512 by 256 division
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        uint256 twos = (0 - denominator) & denominator;
        assembly {
            denominator := div(denominator, twos)
            prod0 := div(prod0, twos)
        }

        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        uint256 inv = (3 * denominator) ^ 2;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
    }
}
