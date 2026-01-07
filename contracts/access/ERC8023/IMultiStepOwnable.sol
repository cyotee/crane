// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IMultiStepOwnable[]
/**
 * @title IMultiStepOwnable - ERC8023 "Owned" contract management and inspection interface.
 * @author cyotee doge <not_cyotee@proton.me>
 */
interface IMultiStepOwnable {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    // tag::OwnershipTransferInitiated(address-address)[]
    /**
     * @notice Emitted when an ownership transfer is initiated.
     * @param prevOwner The address initiating the transfer. Will only be current owner.
     * @param newOwner The address to whcih ownership is being transfered.
     */
    event OwnershipTransferInitiated(address indexed prevOwner, address indexed newOwner);
    // end::OwnershipTransferInitiated(address-address)[]

    // tag::OwnershipTransferConfirmed(address-address)[]
    /**
     * @notice Emitted when an ownership transfer is confirmed after the buffer period.
     * @notice Ownership 
     * @param prevOwner The address that initiated the ownership transfer. Is still the current owner.
     * @param newOwner The address to which ownership transfer has been confirmed.
     */
    event OwnershipTransferConfirmed(address indexed prevOwner, address indexed newOwner);
    // end::OwnershipTransferConfirmed(address-address)[]

    // tag::OwnershipTransferred(address-address)[]
    /**
     * @notice Emitted when a pending ownership transfer is completed.
     * @param prevOwner The address that initiated the ownership transfer.
     * @param newOwner The address to which ownership transfer has been completed. Is the current owner.
     */
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    // end::OwnershipTransferred(address-address)[]

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    // tag::NotOwner(address)[]
    /**
     * @notice Thrown when an address that is not the owner tries to call a owner restricted function.
     * @param caller The address that called the owner restricted function.
     */
    error NotOwner(address caller);
    // end::NotOwner(address)[]

    // tag::NotPending(address)[]
    /**
     * @notice Thrown when an address that is not the pending owner tries to call a pending owner restricted function.
     * @param caller The address that call the pending owner restricted function.
     */
    error NotPending(address caller);
    // end::NotPending(address)[]

    // tag::BufferPeriodNotElapsed(uint256-uint256)[]
    /**
     * @notice Thrown when the owner tries to confirm a pending owner before the ownership transfer buffer period has elapsed.
     * @param currentTime The current block.timestamp when ownership transfer confirmation was attempted.
     * @param bufferEndTime The timestamp when the ownership transfer buffer period has ellapsed.
     */
    error BufferPeriodNotElapsed(uint256 currentTime, uint256 bufferEndTime);
    // end. v::BufferPeriodNotElapsed(uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::initiateOwnershipTransfer(address)[]
    /**
     * @notice Initiates a ownership transfer by storing `newOwner` as the pending owner.
     * @param newOwner The address to which to intiate a ownership transfer.
     * @custom:emits OwnershipTransferInitiated(address,address)
     * @custom:throws NotOwner(address)
     */
    function initiateOwnershipTransfer(address newOwner) external;
    // end::initiateOwnershipTransfer(address)[]

    // tag::confirmOwnershipTransfer(address)[]
    /**
     * @notice Confirms a pending ownership transfer after the buffer period has elapsed.
     * @param newOwner The address for which to confirm the ownership transfer. Must match the current pending owner.
     * @custom:emits OwnershipTransferConfirmed(address,address)
     * @custom:throws NotOwner(address)
     * @custom:throws BufferPeriodNotElapsed(uint256,uint256)
     * @custom:throws NotPending(address)
     */
    function confirmOwnershipTransfer(address newOwner) external;
    // end::confirmOwnershipTransfer(address)[]

    // tag::cancelPendingOwnershipTransfer()[]
    /**
     * @notice Cancels a pending ownership transfer before it is accepted by the new owner.
     * @custom:throws NotOwner(address)
     */
    function cancelPendingOwnershipTransfer() external;
    // end::cancelPendingOwnershipTransfer()[]

    // tag::acceptOwnershipTransfer()[]
    /**
     * @notice Accepts a confirmed ownership transfer. Final step of ownership transfer.
     * @custom:emits OwnershipTransferred(address,address)
     * @custom:throws NotPending(address)
     */
    function acceptOwnershipTransfer() external;
    // end::acceptOwnershipTransfer()[]

    // tag::owner()[]
    /**
     * @return The curent owner of the contract.
     */
    function owner() external view returns (address);
    // end::owner()[]

    /// @dev returns the pending owner of the account.
    /// pending owner should not have any authority/access/right.
    // tag::pendingOwner()[]
    /**
     * @return The current pending owner for a pending ownership transfer.
     */
    function pendingOwner() external view returns (address);
    // end::pendingOwner()[]

    // tag::preConfirmedOwner()[]
    /**
     * @return The current pending owner that was confirmed by the owner for ownership transfer.
     */
    function preConfirmedOwner() external view returns (address);
    // end::preConfirmedOwner()[]

    // tag::getOwnershipTransferBuffer()[]
    /**
     * @return The ownership transfer buffer time in seconds.
     */
    function getOwnershipTransferBuffer() external view returns (uint256);
    // end::getOwnershipTransferBuffer()[]
}
// end::IMultiStepOwnable[]