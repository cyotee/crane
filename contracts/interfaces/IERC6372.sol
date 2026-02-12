// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for the ERC-6372 Contract clock standard.
 * @notice Native Crane implementation - no external dependencies
 *
 * This interface provides a standard way to query the current "time"
 * according to the contract's clock, which can be block numbers, timestamps,
 * or any other monotonically increasing value.
 */
interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}
