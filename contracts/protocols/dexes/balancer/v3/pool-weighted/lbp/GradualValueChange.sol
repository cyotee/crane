// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {Math} from "@crane/contracts/utils/Math.sol";

// solhint-disable not-rely-on-time

/**
 * @title GradualValueChange
 * @notice Library for computing time-based linear interpolation between values.
 * @dev Used by LBPs to gradually change weights over time.
 *
 * Port of Balancer V3's GradualValueChange library for use in Crane framework.
 */
library GradualValueChange {
    using FixedPoint for uint256;

    /// @dev Indicates that the start time is after the end time
    error InvalidStartTime(uint256 resolvedStartTime, uint256 endTime);

    /**
     * @notice Get the current interpolated value based on time progress.
     * @param startValue The value at startTime.
     * @param endValue The value at endTime.
     * @param startTime The start timestamp.
     * @param endTime The end timestamp.
     * @return The interpolated value at the current block timestamp.
     */
    function getInterpolatedValue(
        uint256 startValue,
        uint256 endValue,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256) {
        uint256 pctProgress = calculateValueChangeProgress(startTime, endTime);
        return interpolateValue(startValue, endValue, pctProgress);
    }

    /**
     * @notice Resolve the effective start time, fast-forwarding if in the past.
     * @dev This avoids discontinuities in the value curve. Otherwise, if you set
     * the start/end times with only 10% of the period in the future, the value
     * would immediately jump 90%.
     * @param startTime The requested start time.
     * @param endTime The end time.
     * @return resolvedStartTime The effective start time (at least block.timestamp).
     */
    function resolveStartTime(uint256 startTime, uint256 endTime) internal view returns (uint256 resolvedStartTime) {
        // If the start time is in the past, "fast forward" to start now
        resolvedStartTime = Math.max(block.timestamp, startTime);

        if (resolvedStartTime > endTime) {
            revert InvalidStartTime(resolvedStartTime, endTime);
        }
    }

    /**
     * @notice Interpolate between two values given a progress percentage.
     * @param startValue The starting value.
     * @param endValue The ending value.
     * @param pctProgress Progress as an 18-decimal fixed point (0 to 1e18).
     * @return The interpolated value.
     */
    function interpolateValue(
        uint256 startValue,
        uint256 endValue,
        uint256 pctProgress
    ) internal pure returns (uint256) {
        if (pctProgress >= FixedPoint.ONE || startValue == endValue) {
            return endValue;
        }

        if (pctProgress == 0) {
            return startValue;
        }

        unchecked {
            if (startValue > endValue) {
                uint256 delta = pctProgress.mulDown(startValue - endValue);
                return startValue - delta;
            } else {
                uint256 delta = pctProgress.mulDown(endValue - startValue);
                return startValue + delta;
            }
        }
    }

    /**
     * @notice Calculate the progress of a time-based value change.
     * @dev Returns a fixed-point number representing how far along the current
     * value change is, where 0 means the change has not yet started, and
     * FixedPoint.ONE means it has fully completed.
     * @param startTime The start timestamp.
     * @param endTime The end timestamp.
     * @return Progress as an 18-decimal fixed point (0 to 1e18).
     */
    function calculateValueChangeProgress(uint256 startTime, uint256 endTime) internal view returns (uint256) {
        if (block.timestamp >= endTime) {
            return FixedPoint.ONE;
        } else if (block.timestamp <= startTime) {
            return 0;
        }

        // No need for checked math as the magnitudes are verified above: endTime > block.timestamp > startTime
        uint256 totalSeconds;
        uint256 secondsElapsed;

        unchecked {
            totalSeconds = endTime - startTime;
            secondsElapsed = block.timestamp - startTime;
        }

        // We don't need to consider zero division here as the code would never reach this point in that case.
        // If startTime == endTime:
        // - Progress = 1 if block.timestamp >= endTime (== startTime)
        // - Progress = 0 if block.timestamp < startTime (== endTime)
        return secondsElapsed.divDown(totalSeconds);
    }
}
