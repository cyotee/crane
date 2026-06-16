// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IArbitrable
 * @notice Interface for contracts that can be ruled on by an arbitrator (ERC-792 / Kleros compatible).
 * @dev The arbitrator calls rule(disputeID, ruling) on this contract after a dispute is created via the arbitrator.
 */
interface IArbitrable {
    /**
     * @dev To be emitted when a ruling is executed.
     * @param arbitrator The arbitrator that gave the ruling.
     * @param disputeId ID of the dispute.
     * @param ruling The ruling given (implementation defined; 0 often means no decision).
     */
    event Ruling(address indexed arbitrator, uint256 indexed disputeId, uint256 ruling);

    /**
     * @notice Receive a ruling from the arbitrator.
     * @dev Must be called by the current arbitrator (verified in implementation).
     * @param disputeId The dispute identifier from the arbitrator.
     * @param ruling The ruling (e.g. 1 = favor worker/claimant, 2 = favor issuer).
     */
    function rule(uint256 disputeId, uint256 ruling) external;
}
