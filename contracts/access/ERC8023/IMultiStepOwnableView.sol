// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::IMultiStepOwnableView[]
/**
 * @title IMultiStepOwnableView - ERC8023 "Owned" contract inspection interface.
 * @author cyotee doge <not_cyotee@proton.me>
 * @custom:interfaceid 0x7bc767d7
 */
interface IMultiStepOwnableView {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::owner()[]
    /**
     * @return The current owner of the contract.
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
// end::IMultiStepOwnableView[]
