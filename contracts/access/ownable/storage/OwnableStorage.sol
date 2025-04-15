// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IOwnable
} from "../../../access/ownable/interfaces/IOwnable.sol";

import {
    OwnableLayout,
    OwnableRepo
} from "../../../access/ownable/libs/OwnableRepo.sol";

interface IOwnableStorage
{
    struct OwnableAccountInit{
        address owner;
    }

}

/**
 * @title OwnableStorage - Storage contract for Ownable state management.
 * @author cyotee doge <doge.cyotee>
 * @dev Includes actual storage operations for integration in logic that
 * @dev wishes to included Ownable as an atomic operation.
 */
contract OwnableStorage is IOwnableStorage {

    /* ------------------------------ LIBRARIES ----------------------------- */

    // using OwnableRepo for OwnableLayout;
    using OwnableRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */
  
    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(OwnableRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IOwnable).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_ownable()[]
    function _ownable()
    internal pure virtual returns(OwnableLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_ownable()[]

    function _initOwnable(
        address owner
    ) internal {
        _initOwner(owner);
    }

    /**
     * @dev Ownable initialization to set owner.
     * @dev Will revert if called to override previous owner during init.
     * @param newOwner Address to set as the initial owner.
     */
    function _initOwner(address newOwner) internal {
        // if(_ownable().owner != address(0)) {
        //     revert IOwnable.NotProposed(newOwner);
        // }
        _ownable().owner = newOwner;
        emit IOwnable.OwnershipTransferred(
            address(0),
            newOwner
        );
    }

    /**
     * @return Current owner of contract.
     */
    function _owner()
    internal view returns(address) {
        return _ownable().owner;
    }

    /**
     * @param challenger Address to query for ownership.
     * @return Boolean indicating ownership.
     */
    function _isOwner(address challenger) internal view returns(bool) {
        return challenger == _owner();
    }

    /**
     * @dev DOES NOT change ownership.
     * @dev Stores proposed owner pending acceptance.
     * @dev Acceptance workflow minimizes ownership transfer errors.
     * @param proposedOwner_ Address to propose for ownership.
     */
    function _transferOwnerShip(address proposedOwner_) internal returns(bool) {
        // Address(0) MAY NOT propose ownership transfer;
        if(msg.sender == address(0)) {
            revert IOwnable.NotOwner(msg.sender);
        }
        // No valid reason to propose address(0) for onwership
        if(proposedOwner_ == address(0)) {
            revert IOwnable.NotProposed(proposedOwner_);
        }
        _ownable().proposedOwner = proposedOwner_;
        emit IOwnable.TransferProposed(proposedOwner_);
        return true;
    }

    /**
     * @dev Accepts ownership proposal.
     * @dev DOES change ownership.
     * @dev Included WITHOUT caller validation for inclusion in other atomic operations.
     * @return Boolean indicating successful ownership transfer.
     */
    function _acceptOwnership() internal returns(bool) {
        // Address(0) MAY NOT accept ownership.
        // Transfer to address(0) handled directly via renouncement.
        // Check is included because proposed user defaults to address(0).
        if(msg.sender == address(0)) {
            revert IOwnable.NotProposed(msg.sender);
        }
        address prevOwner = _ownable().owner;
        address newOwner = _ownable().proposedOwner;
        _ownable().owner = newOwner;
        _ownable().proposedOwner = address(0);
        emit IOwnable.OwnershipTransferred(prevOwner, newOwner);
        return true;
    }

    /**
     * @dev Renounces ownership by transferring ownership to address(0).
     * @return Boolean indicating successful ownership transfer to address(0).
     */
    function _renounceOwnership() internal returns(bool) {
        // require(_ownable().proposedOwner == address(0), "MUST NOT have proposed owner");
        if(_ownable().proposedOwner != address(0)) {
            revert IOwnable.NotProposed(address(0));
        }
        address prevOwner = _ownable().owner;
        _ownable().owner = address(0);
        emit IOwnable.OwnershipTransferred(prevOwner, address(0));
        return true;
    }
    
}
