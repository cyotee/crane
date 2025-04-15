// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IOwnable "Owned" contract management and inspection interface.
 * @author cyotee doge <doge.cyotee>
 */
interface IOwnable {

    error NotOwner(address caller);

    error NotProposed(address caller);

    event TransferProposed(address indexed proposedOwner);

    event OwnershipTransferred(
        address indexed prevOwner,
        address indexed newOwner
    );

    /**
     * @return The address of the owner of this contract instance.
     * @custom:func-sig owner()
     * @custom:func-sig-hash 0x8da5cb5b
     */
    function owner() external view returns(address);

    /**
     * @return The address of the owner proposed for transfer.
     * @custom:func-sig proposedOwner()
     * @custom:func-sig-hash 0xd153b60c
     */
    function proposedOwner() external view returns(address);

    /**
     * @param proposedOwner_ The address to propose for transferring ownership.
     * @return Boolean indicating domain logic success.
     * @custom:func-sig transferOwnership(address)
     * @custom:func-sig-hash 0xf2fde38b
     */
    function transferOwnership(address proposedOwner_)
    external returns(bool);

    /**
     * @notice Allows the proposed owner to accept ownership transfer.
     * @return Boolean indicating domain logic success.
     * @custom:func-sig acceptOwnership()
     * @custom:func-sig-hash 0x79ba5097
     */
    function acceptOwnership() external returns(bool);

    /**
     * @notice Allows the owner to remove ownership claim without transfer.
     * @notice Reverts if a proposed owner is set to other than address(0);
     * @return Boolean indicating domain logic success.
     * @custom:func-sig renounceOwnership()
     * @custom:func-sig-hash 0x715018a6
     */
    function renounceOwnership() external returns(bool);

}