// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IArbitrator
 * @notice Minimal interface for an arbitrator (sufficient for Kleros and similar).
 * @dev Used via Call Target Registry to resolve the active arbitrator for a board.
 */
interface IArbitrator {
    /**
     * @notice Create a dispute with the given number of choices.
     * @param choices The number of possible rulings (typically 2 for binary).
     * @param extraData Additional data for the dispute (e.g. subcourt, policy).
     * @return disputeID The ID of the created dispute.
     */
    function createDispute(uint256 choices, bytes calldata extraData) external payable returns (uint256 disputeID);

    /**
     * @notice Return the cost to create a dispute with the given extraData.
     * @param extraData Additional data.
     * @return cost The arbitration fee in wei.
     */
    function arbitrationCost(bytes calldata extraData) external view returns (uint256 cost);
}
