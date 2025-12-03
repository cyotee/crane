// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IOwnable "Owned" contract management and inspection interface.
 * @author cyotee doge <doge.cyotee>
 */
interface IMultiStepOwnable {
    error NotOwner(address caller);
    error NotPending(address caller);
    error BufferPeriodNotElapsed(uint256 currentTime, uint256 bufferEndTime);

    event OwnershipTransferInitiated(address indexed prevOwner, address indexed newOwner);
    event OwnershipTransferConfirmed(address indexed prevOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    /// @dev initiate the ownership transfer. First step of ownership transfer.
    /// moves the newOwner to the preConfirmed stage.
    ///
    /// @param newOwner the address of the new owner of the contract.
    /// stored as preConfirmedOwner.
    function initiateOwnershipTransfer(address newOwner) external;

    /// @dev confirm the ownership transfer. Second step of ownership transfer.
    /// confirmation can only be done after the transfer-buffer period from initiation.
    /// newOwner should match with the initiation step's newOwner.
    /// To initiate ownership transfer to a different newOwner, initiation step should be re-conducted.
    ///
    /// @param newOwner the address of the new owner of the contract.
    /// stored as pendingOwner.
    function confirmOwnershipTransfer(address newOwner) external;

    /// @dev cancels the pending ownership transfer. Before the final step of ownership transfer (acceptOwnershipTransfer()).
    /// This function should wipe out the pendingOwner.
    /// By calling this function, ownership transfer process is canceled and should be reinitiated from initiateOwnershipTransfer().
    function cancelPendingOwnershipTransfer() external;

    /// @dev accepts the ownership transfer. Final step of ownership transfer.
    /// This function can only be called by the newOwner that was confirmed in step 2.
    /// The contract should perform access control e.g.,
    /// msg.sender == pendingOwner()
    function acceptOwnershipTransfer() external;

    /// @notice only the address returned by owner() has authority as the owner.
    /// pendingOwner() and preConfirmedOwner() should not possess any
    /// authority/access/right.
    /// @dev returns the owner of the contract
    function owner() external view returns (address);

    /// @dev returns the pending owner of the account.
    /// pending owner should not have any authority/access/right.
    function pendingOwner() external view returns (address);

    /// @dev returns the pre-confirmed owner of the account.
    /// pre-confirmed owner should not have any authority/access/right.
    function preConfirmedOwner() external view returns (address);

    /// @dev returns the ownership transfer buffer time (in seconds).
    /// the buffer is enforced between initiation <> confirmation of ownership transfer.
    /// the standard does not enforce the value range. it is highly recommended to be between 2 <> 14 days.
    function getOwnershipTransferBuffer() external view returns (uint256);
}
