// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IMultiStepOwnable[]
/**
 * @title IMultiStepOwnable - ERC8023 "Owned" contract management and inspection interface.
 * @author cyotee doge <not_cyotee@proton.me>
 * @custom:interfaceid 0x4c60d07c
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
    * @custom:topiczero 0xb150023a879fd806e3599b6ca8ee3b60f0e360ab3846d128d67ebce1a391639a
     */
    event OwnershipTransferInitiated(address indexed prevOwner, address indexed newOwner);
    // end::OwnershipTransferInitiated(address-address)[]

    // tag::OwnershipTransferConfirmed(address-address)[]
    /**
     * @notice Emitted when an ownership transfer is confirmed after the buffer period.
     * @notice Ownership 
     * @param prevOwner The address that initiated the ownership transfer. Is still the current owner.
     * @param newOwner The address to which ownership transfer has been confirmed.
    * @custom:topiczero 0x646fe5eeb20d96ea45a9caafcb508854a2fb5660885ced7772e12a633c974571
     */
    event OwnershipTransferConfirmed(address indexed prevOwner, address indexed newOwner);
    // end::OwnershipTransferConfirmed(address-address)[]

    // tag::OwnershipTransferred(address-address)[]
    /**
     * @notice Emitted when a pending ownership transfer is completed.
     * @param prevOwner The address that initiated the ownership transfer.
     * @param newOwner The address to which ownership transfer has been completed. Is the current owner.
    * @custom:topiczero 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
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
     * @custom:selector 0x245aecd3
     */
    error NotOwner(address caller);
    // end::NotOwner(address)[]

    // tag::NotPending(address)[]
    /**
     * @notice Thrown when an address that is not the pending owner tries to call a pending owner restricted function.
     * @param caller The address that call the pending owner restricted function.
     * @custom:selector 0xa7fa19b1
     */
    error NotPending(address caller);
    // end::NotPending(address)[]

    // tag::BufferPeriodNotElapsed(uint256-uint256)[]
    /**
     * @notice Thrown when the owner tries to confirm a pending owner before the ownership transfer buffer period has elapsed.
     * @param currentTime The current block.timestamp when ownership transfer confirmation was attempted.
     * @param bufferEndTime The timestamp when the ownership transfer buffer period has ellapsed.
     * @custom:selector 0xd64ede73
     */
    error BufferPeriodNotElapsed(uint256 currentTime, uint256 bufferEndTime);
    // end::BufferPeriodNotElapsed(uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::initiateOwnershipTransfer(address)[]
    /**
     * @notice Initiates a ownership transfer by storing `newOwner` as the pending owner.
     * @param newOwner The address to which to intiate a ownership transfer.
     * @custom:selector 0xc0b6f561
     * @custom:signature initiateOwnershipTransfer(address)
     * @custom:emits OwnershipTransferInitiated(address,address)
     * @custom:throws NotOwner(address)
     */
    function initiateOwnershipTransfer(address newOwner) external;
    // end::initiateOwnershipTransfer(address)[]

    // tag::confirmOwnershipTransfer(address)[]
    /**
     * @notice Confirms a pending ownership transfer after the buffer period has elapsed.
     * @param newOwner The address for which to confirm the ownership transfer. Must match the current pending owner.
     * @custom:selector 0x3c213957
     * @custom:signature confirmOwnershipTransfer(address)
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
     * @custom:selector 0x737293e2
     * @custom:signature cancelPendingOwnershipTransfer()
     * @custom:throws NotOwner(address)
     */
    function cancelPendingOwnershipTransfer() external;
    // end::cancelPendingOwnershipTransfer()[]

    // tag::acceptOwnershipTransfer()[]
    /**
     * @notice Accepts a confirmed ownership transfer. Final step of ownership transfer.
     * @custom:selector 0xb842e87f
     * @custom:signature acceptOwnershipTransfer()
     * @custom:emits OwnershipTransferred(address,address)
     * @custom:throws NotPending(address)
     */
    function acceptOwnershipTransfer() external;
    // end::acceptOwnershipTransfer()[]

    // tag::owner()[]
    /**
     * @return The curent owner of the contract.
     * @custom:selector 0x8da5cb5b
     * @custom:signature owner()
     */
    function owner() external view returns (address);
    // end::owner()[]

    // tag::pendingOwner()[]
    /**
     * @return The current pending owner for a pending ownership transfer.
     * @custom:selector 0xe30c3978
     * @custom:signature pendingOwner()
     */
    function pendingOwner() external view returns (address);
    // end::pendingOwner()[]

    // tag::preConfirmedOwner()[]
    /**
     * @return The current pending owner that was confirmed by the owner for ownership transfer.
     * @custom:selector 0x1af1b0c4
     * @custom:signature preConfirmedOwner()
     */
    function preConfirmedOwner() external view returns (address);
    // end::preConfirmedOwner()[]

    // tag::getOwnershipTransferBuffer()[]
    /**
     * @return The ownership transfer buffer time in seconds.
     * @custom:selector 0x0f9f2530
     * @custom:signature getOwnershipTransferBuffer()
     */
    function getOwnershipTransferBuffer() external view returns (uint256);
    // end::getOwnershipTransferBuffer()[]
}
// end::IMultiStepOwnable[]