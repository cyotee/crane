// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {StableMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/StableMath.sol";

/**
 * @title BalancerV3StablePoolRepo
 * @notice Storage library for Balancer V3 stable pool amplification parameters.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 * Stable pools have time-based gradual amplification transitions.
 *
 * The amplification parameter controls the "flatness" of the invariant curve:
 * - Higher values (up to 50000): Flatter curve, lower slippage for pegged assets
 * - Lower values (down to 1): Closer to constant product, handles more volatility
 *
 * Amplification changes must:
 * - Take at least 1 day to complete
 * - Change by at most 2x per day
 */
library BalancerV3StablePoolRepo {
    using FixedPoint for uint256;

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.stable");

    /// @notice The amplification factor is below the minimum of the range (1 - 50000).
    error AmplificationFactorTooLow();

    /// @notice The amplification factor is above the maximum of the range (1 - 50000).
    error AmplificationFactorTooHigh();

    /// @notice The amplification change duration is too short.
    error AmpUpdateDurationTooShort();

    /// @notice The amplification change rate is too fast.
    error AmpUpdateRateTooFast();

    /// @notice Amplification update operations must be done one at a time.
    error AmpUpdateAlreadyStarted();

    /// @notice Cannot stop an amplification update before it starts.
    error AmpUpdateNotStarted();

    /// @notice Minimum time for an amplification update (1 day).
    uint256 internal constant MIN_UPDATE_TIME = 1 days;

    /// @notice Maximum rate of amplification change (2x per day).
    uint256 internal constant MAX_AMP_UPDATE_DAILY_RATE = 2;

    struct Storage {
        // Amplification transition state (packed for gas efficiency)
        uint64 startValue;
        uint64 endValue;
        uint32 startTime;
        uint32 endTime;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /**
     * @notice Initialize the stable pool with an amplification parameter.
     * @dev The amplification parameter must be within [MIN_AMP, MAX_AMP].
     * Stored value includes the AMP_PRECISION multiplier.
     * @param layout Storage pointer.
     * @param amplificationParameter_ Initial amplification factor (1-5000, without precision).
     */
    function _initialize(Storage storage layout, uint256 amplificationParameter_) internal {
        if (amplificationParameter_ < StableMath.MIN_AMP) revert AmplificationFactorTooLow();
        if (amplificationParameter_ > StableMath.MAX_AMP) revert AmplificationFactorTooHigh();

        // Store with precision multiplier
        uint64 initialAmp = uint64(amplificationParameter_ * StableMath.AMP_PRECISION);

        // Set start = end to indicate no transition in progress
        layout.startValue = initialAmp;
        layout.endValue = initialAmp;
        layout.startTime = uint32(block.timestamp);
        layout.endTime = uint32(block.timestamp);
    }

    function _initialize(uint256 amplificationParameter_) internal {
        _initialize(_layout(), amplificationParameter_);
    }

    /**
     * @notice Start a gradual amplification parameter update.
     * @dev Validates rate limits and duration requirements.
     * @param layout Storage pointer.
     * @param rawEndValue Target amplification value (without precision multiplier).
     * @param endTime Timestamp when the update should complete.
     */
    function _startAmplificationParameterUpdate(
        Storage storage layout,
        uint256 rawEndValue,
        uint256 endTime
    ) internal {
        if (rawEndValue < StableMath.MIN_AMP) revert AmplificationFactorTooLow();
        if (rawEndValue > StableMath.MAX_AMP) revert AmplificationFactorTooHigh();

        uint256 duration = endTime - block.timestamp;
        if (duration < MIN_UPDATE_TIME) revert AmpUpdateDurationTooShort();

        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter(layout);
        if (isUpdating) revert AmpUpdateAlreadyStarted();

        uint256 endValue = rawEndValue * StableMath.AMP_PRECISION;

        // Calculate daily rate: (endValue / currentValue) / duration * 1 day
        // Round up to be conservative
        uint256 dailyRate = endValue > currentValue
            ? (endValue * 1 days + currentValue * duration - 1) / (currentValue * duration)
            : (currentValue * 1 days + endValue * duration - 1) / (endValue * duration);

        if (dailyRate > MAX_AMP_UPDATE_DAILY_RATE) revert AmpUpdateRateTooFast();

        layout.startValue = uint64(currentValue);
        layout.endValue = uint64(endValue);
        layout.startTime = uint32(block.timestamp);
        layout.endTime = uint32(endTime);
    }

    function _startAmplificationParameterUpdate(uint256 rawEndValue, uint256 endTime) internal {
        _startAmplificationParameterUpdate(_layout(), rawEndValue, endTime);
    }

    /**
     * @notice Stop an in-progress amplification update.
     * @dev Freezes the current interpolated value as the new static value.
     * @param layout Storage pointer.
     */
    function _stopAmplificationParameterUpdate(Storage storage layout) internal {
        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter(layout);
        if (!isUpdating) revert AmpUpdateNotStarted();

        _stopAmplification(layout, currentValue);
    }

    function _stopAmplificationParameterUpdate() internal {
        _stopAmplificationParameterUpdate(_layout());
    }

    /**
     * @notice Get the current amplification parameter with interpolation.
     * @param layout Storage pointer.
     * @return value Current amplification value (includes precision).
     * @return isUpdating True if currently transitioning.
     */
    function _getAmplificationParameter(Storage storage layout) internal view returns (uint256 value, bool isUpdating) {
        uint256 startValue = layout.startValue;
        uint256 endValue = layout.endValue;
        uint256 startTime = layout.startTime;
        uint256 endTime = layout.endTime;

        if (block.timestamp < endTime) {
            isUpdating = true;

            // Linear interpolation
            unchecked {
                if (endValue > startValue) {
                    value = startValue +
                        ((endValue - startValue) * (block.timestamp - startTime)) / (endTime - startTime);
                } else {
                    value = startValue -
                        ((startValue - endValue) * (block.timestamp - startTime)) / (endTime - startTime);
                }
            }
        } else {
            isUpdating = false;
            value = endValue;
        }
    }

    function _getAmplificationParameter() internal view returns (uint256 value, bool isUpdating) {
        return _getAmplificationParameter(_layout());
    }

    /**
     * @notice Get the full amplification state.
     * @param layout Storage pointer.
     * @return startValue Starting value of transition.
     * @return endValue Ending value of transition.
     * @return startTime Start timestamp.
     * @return endTime End timestamp.
     */
    function _getAmplificationState(Storage storage layout)
        internal
        view
        returns (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime
        )
    {
        startValue = layout.startValue;
        endValue = layout.endValue;
        startTime = layout.startTime;
        endTime = layout.endTime;
    }

    function _getAmplificationState()
        internal
        view
        returns (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime
        )
    {
        return _getAmplificationState(_layout());
    }

    /**
     * @notice Internal helper to stop amplification at a specific value.
     * @param layout Storage pointer.
     * @param value The value to freeze at.
     */
    function _stopAmplification(Storage storage layout, uint256 value) internal {
        uint64 currentValueUint64 = uint64(value);
        layout.startValue = currentValueUint64;
        layout.endValue = currentValueUint64;

        uint32 currentTime = uint32(block.timestamp);
        layout.startTime = currentTime;
        layout.endTime = currentTime;
    }
}
