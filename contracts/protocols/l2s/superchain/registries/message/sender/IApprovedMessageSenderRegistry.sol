// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IApprovedMessageSenderRegistry
 * @notice Interface for the ApprovedMessageSenderRegistry, which allows recipients to manage a list of approved senders that can send messages to them.
 */
interface IApprovedMessageSenderRegistry {
    /**
     * @notice Checks if a sender is approved to send messages to a recipient.
     * @param recipient The address of the message recipient.
     * @param sender The address of the message sender.
     * @return True if the sender is approved to send messages to the recipient, false otherwise
     */
    function isApprovedSender(address recipient, address sender) external view returns (bool);

    /**
     * @notice Retrieves the list of all approved senders for a recipient.
     * @param recipient The address of the message recipient.
     * @return An array of addresses representing the approved senders for the recipient.
     */
    function allApprovedSenders(address recipient) external view returns (address[] memory);
    
    /**
     * @notice Approves a sender to send messages to a recipient.
     * @param recipient The address of the message recipient.
     * @param sender The address of the message sender.
     * @return True if the sender was successfully approved, false otherwise.
     */
    function approveSender(address recipient, address sender) external returns (bool);
}