// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

/**
 * @notice Base contract for v3 factories to support pause windows for pools based on the factory deployment time.
 * @dev Vendored from Balancer V3 Solidity Utils.
 */
contract FactoryWidePauseWindow {
    // This contract relies on timestamps - the usual caveats apply.
    // solhint-disable not-rely-on-time

    // The pause window end time is stored in 32 bits.
    uint32 private constant _MAX_TIMESTAMP = type(uint32).max;

    uint32 private immutable _pauseWindowDuration;

    // Time when the pause window for all created Pools expires.
    uint32 private immutable _poolsPauseWindowEndTime;

    /// @notice The factory deployer gave a duration that would overflow the Unix timestamp.
    error PoolPauseWindowDurationOverflow();

    constructor(uint32 pauseWindowDuration) {
        uint256 pauseWindowEndTime = block.timestamp + pauseWindowDuration;

        if (pauseWindowEndTime > _MAX_TIMESTAMP) {
            revert PoolPauseWindowDurationOverflow();
        }

        _pauseWindowDuration = pauseWindowDuration;

        // Direct cast is safe, as it was checked above.
        _poolsPauseWindowEndTime = uint32(pauseWindowEndTime);
    }

    /**
     * @notice Return the pause window duration. This is the time pools will be pausable after factory deployment.
     * @return pauseWindowDuration The duration in seconds
     */
    function getPauseWindowDuration() external view returns (uint32) {
        return _pauseWindowDuration;
    }

    /**
     * @notice Returns the original factory pauseWindowEndTime, regardless of the current time.
     * @return pauseWindowEndTime The end time as a timestamp
     */
    function getOriginalPauseWindowEndTime() external view returns (uint32) {
        return _poolsPauseWindowEndTime;
    }

    /**
     * @notice Returns the current pauseWindowEndTime that will be applied to Pools created by this factory.
     * @dev Returns `_poolsPauseWindowEndTime` until it passes, after which it returns 0.
     */
    function getNewPoolPauseWindowEndTime() public view returns (uint32) {
        return (block.timestamp < _poolsPauseWindowEndTime) ? _poolsPauseWindowEndTime : 0;
    }
}
