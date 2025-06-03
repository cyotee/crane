// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFactoryWidePauseWindow {

    /**
     * @notice Return the pause window duration. This is the time pools will be pausable after factory deployment.
     * @return pauseWindowDuration The duration in seconds
     */
    function getPauseWindowDuration() external view returns (uint32);

    /**
     * @notice Returns the original factory pauseWindowEndTime, regardless of the current time.
     * @return pauseWindowEndTime The end time as a timestamp
     */
    function getOriginalPauseWindowEndTime() external view returns (uint32);

    /**
     * @notice Returns the current pauseWindowEndTime that will be applied to Pools created by this factory.
     * @dev We intend for all pools deployed by this factory to have the same pause window end time (i.e., after
     * this date, all future pools will be unpausable). This function will return `_poolsPauseWindowEndTime`
     * until it passes, after which it will return 0.
     *
     * @return pauseWindowEndTime The resolved pause window end time (0 indicating it's no longer pausable)
     */
    function getNewPoolPauseWindowEndTime() external view returns (uint32);

}