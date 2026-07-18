// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {StableMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/StableMath.sol";

// tag::BalancerV3StablePoolRepo[]
/**
 * @title BalancerV3StablePoolRepo - Storage library for Balancer V3 stable pool amplification parameters.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for Balancer V3 stable pool amp factor + transition state.
 * @dev Provides dual (parameterized + default) overloads for _initialize, amp update/start/stop, getters.
 * @dev Stable pools have time-based gradual amplification transitions.
 * @dev Follows the gold standard from BalancerV3VaultAwareRepo, OperableRepo, ERC20Repo, EIP712Repo, ERC2535Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by BalancerV3 stable pool targets/facets/DFPkgs for Diamond storage binding of amplification state.
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

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.stable"))) - 1).
     *      This follows the canonical pattern used by BalancerV3VaultAwareRepo, OperableRepo (crane.access.operable),
     *      ERC20Repo (eip.erc.20), ERC2535Repo (eip.erc.2535), MultiStepOwnableRepo and other gold-standard Repos
     *      for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.stable"))) - 1);
    // end::STORAGE_SLOT[]

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

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for Balancer V3 stable pool amplification state.
     *      Packed for gas efficiency: start/end values and times for gradual amp updates.
     */
    struct Storage {
        // Amplification transition state (packed for gas efficiency)
        uint64 startValue;
        uint64 endValue;
        uint32 startTime;
        uint32 endTime;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-uint256)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param amplificationParameter_ Initial amplification factor (1-5000, without precision).
     *      Stored value includes the AMP_PRECISION multiplier from StableMath.
     * @custom:throws AmplificationFactorTooLow
     * @custom:throws AmplificationFactorTooHigh
     */
    function _initialize(Storage storage layoutStruct, uint256 amplificationParameter_) internal {
        if (amplificationParameter_ < StableMath.MIN_AMP) revert AmplificationFactorTooLow();
        if (amplificationParameter_ > StableMath.MAX_AMP) revert AmplificationFactorTooHigh();

        // Store with precision multiplier
        uint64 initialAmp = uint64(amplificationParameter_ * StableMath.AMP_PRECISION);

        // Set start = end to indicate no transition in progress
        layoutStruct.startValue = initialAmp;
        layoutStruct.endValue = initialAmp;
        layoutStruct.startTime = uint32(block.timestamp);
        layoutStruct.endTime = uint32(block.timestamp);
    }

    // end::_initialize(Storage-uint256)[]

    // tag::_initialize(uint256)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param amplificationParameter_ Initial amplification factor (1-5000, without precision).
     * @custom:throws AmplificationFactorTooLow
     * @custom:throws AmplificationFactorTooHigh
     */
    function _initialize(uint256 amplificationParameter_) internal {
        _initialize(_layoutStruct(), amplificationParameter_);
    }

    // end::_initialize(uint256)[]

    // tag::_startAmplificationParameterUpdate(Storage-uint256-uint256)[]
    /**
     * @dev Argumented version of _startAmplificationParameterUpdate to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param rawEndValue Target amplification value (without precision multiplier).
     * @param endTime Timestamp when the update should complete.
     * @custom:throws AmplificationFactorTooLow
     * @custom:throws AmplificationFactorTooHigh
     * @custom:throws AmpUpdateDurationTooShort
     * @custom:throws AmpUpdateAlreadyStarted
     * @custom:throws AmpUpdateRateTooFast
     */
    function _startAmplificationParameterUpdate(Storage storage layoutStruct, uint256 rawEndValue, uint256 endTime)
        internal
    {
        if (rawEndValue < StableMath.MIN_AMP) revert AmplificationFactorTooLow();
        if (rawEndValue > StableMath.MAX_AMP) revert AmplificationFactorTooHigh();

        uint256 duration = endTime - block.timestamp;
        if (duration < MIN_UPDATE_TIME) revert AmpUpdateDurationTooShort();

        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter(layoutStruct);
        if (isUpdating) revert AmpUpdateAlreadyStarted();

        uint256 endValue = rawEndValue * StableMath.AMP_PRECISION;

        // Calculate daily rate: (endValue / currentValue) / duration * 1 day
        // Round up to be conservative
        uint256 dailyRate = endValue > currentValue
            ? (endValue * 1 days + currentValue * duration - 1) / (currentValue * duration)
            : (currentValue * 1 days + endValue * duration - 1) / (endValue * duration);

        if (dailyRate > MAX_AMP_UPDATE_DAILY_RATE) revert AmpUpdateRateTooFast();

        layoutStruct.startValue = uint64(currentValue);
        layoutStruct.endValue = uint64(endValue);
        layoutStruct.startTime = uint32(block.timestamp);
        layoutStruct.endTime = uint32(endTime);
    }

    // end::_startAmplificationParameterUpdate(Storage-uint256-uint256)[]

    // tag::_startAmplificationParameterUpdate(uint256-uint256)[]
    /**
     * @dev Default version of _startAmplificationParameterUpdate binding to the standard STORAGE_SLOT.
     * @param rawEndValue Target amplification value (without precision multiplier).
     * @param endTime Timestamp when the update should complete.
     * @custom:throws AmplificationFactorTooLow
     * @custom:throws AmplificationFactorTooHigh
     * @custom:throws AmpUpdateDurationTooShort
     * @custom:throws AmpUpdateAlreadyStarted
     * @custom:throws AmpUpdateRateTooFast
     */
    function _startAmplificationParameterUpdate(uint256 rawEndValue, uint256 endTime) internal {
        _startAmplificationParameterUpdate(_layoutStruct(), rawEndValue, endTime);
    }

    // end::_startAmplificationParameterUpdate(uint256-uint256)[]

    // tag::_stopAmplificationParameterUpdate(Storage)[]
    /**
     * @dev Argumented version of _stopAmplificationParameterUpdate to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @custom:throws AmpUpdateNotStarted
     */
    function _stopAmplificationParameterUpdate(Storage storage layoutStruct) internal {
        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter(layoutStruct);
        if (!isUpdating) revert AmpUpdateNotStarted();

        _stopAmplification(layoutStruct, currentValue);
    }

    // end::_stopAmplificationParameterUpdate(Storage)[]

    // tag::_stopAmplificationParameterUpdate()[]
    /**
     * @dev Default version of _stopAmplificationParameterUpdate binding to the standard STORAGE_SLOT.
     * @custom:throws AmpUpdateNotStarted
     */
    function _stopAmplificationParameterUpdate() internal {
        _stopAmplificationParameterUpdate(_layoutStruct());
    }

    // end::_stopAmplificationParameterUpdate()[]

    // tag::_getAmplificationParameter(Storage)[]
    /**
     * @dev Argumented version of _getAmplificationParameter to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return value Current amplification value (includes precision).
     * @return isUpdating True if currently transitioning.
     */
    function _getAmplificationParameter(Storage storage layoutStruct)
        internal
        view
        returns (uint256 value, bool isUpdating)
    {
        uint256 startValue = layoutStruct.startValue;
        uint256 endValue = layoutStruct.endValue;
        uint256 startTime = layoutStruct.startTime;
        uint256 endTime = layoutStruct.endTime;

        if (block.timestamp < endTime) {
            isUpdating = true;

            // Linear interpolation
            unchecked {
                if (endValue > startValue) {
                    value =
                        startValue + ((endValue - startValue) * (block.timestamp - startTime)) / (endTime - startTime);
                } else {
                    value =
                        startValue - ((startValue - endValue) * (block.timestamp - startTime)) / (endTime - startTime);
                }
            }
        } else {
            isUpdating = false;
            value = endValue;
        }
    }

    // end::_getAmplificationParameter(Storage)[]

    // tag::_getAmplificationParameter()[]
    /**
     * @dev Default version of _getAmplificationParameter binding to the standard STORAGE_SLOT.
     * @return value Current amplification value (includes precision).
     * @return isUpdating True if currently transitioning.
     */
    function _getAmplificationParameter() internal view returns (uint256 value, bool isUpdating) {
        return _getAmplificationParameter(_layoutStruct());
    }

    // end::_getAmplificationParameter()[]

    // tag::_getAmplificationState(Storage)[]
    /**
     * @dev Argumented version of _getAmplificationState to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return startValue Starting value of transition.
     * @return endValue Ending value of transition.
     * @return startTime Start timestamp.
     * @return endTime End timestamp.
     */
    function _getAmplificationState(Storage storage layoutStruct)
        internal
        view
        returns (uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime)
    {
        startValue = layoutStruct.startValue;
        endValue = layoutStruct.endValue;
        startTime = layoutStruct.startTime;
        endTime = layoutStruct.endTime;
    }

    // end::_getAmplificationState(Storage)[]

    // tag::_getAmplificationState()[]
    /**
     * @dev Default version of _getAmplificationState binding to the standard STORAGE_SLOT.
     * @return startValue Starting value of transition.
     * @return endValue Ending value of transition.
     * @return startTime Start timestamp.
     * @return endTime End timestamp.
     */
    function _getAmplificationState()
        internal
        view
        returns (uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime)
    {
        return _getAmplificationState(_layoutStruct());
    }

    // end::_getAmplificationState()[]

    // (internal non-dual helper _stopAmplification remains without tag; called only from dual wrappers)

    /**
     * @notice Internal helper to stop amplification at a specific value.
     * @param layoutStruct The Storage struct to operate on.
     * @param value The value to freeze at.
     */
    function _stopAmplification(Storage storage layoutStruct, uint256 value) internal {
        uint64 currentValueUint64 = uint64(value);
        layoutStruct.startValue = currentValueUint64;
        layoutStruct.endValue = currentValueUint64;

        uint32 currentTime = uint32(block.timestamp);
        layoutStruct.startTime = currentTime;
        layoutStruct.endTime = currentTime;
    }
}
// end::BalancerV3StablePoolRepo[]
