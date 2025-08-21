// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IOwnable
} from "contracts/interfaces/IOwnable.sol";

import {
    IOwnableStorage,
    OwnableStorage
} from "contracts/access/ownable/utils/OwnableStorage.sol";


/**
 * @title OwnableModifiers - Inheritable modifiers for ownership status validation.
 * @author cyotee doge <doge.cyotee>
 * @notice Modifiers accept arguments to allow application to any variable.
 */
// TODO argument the modifiers.
contract OwnableModifiers is OwnableStorage {

    /**
     * @notice Reverts if msg.sender is NOT owner.
     */
    modifier onlyOwner() {
        if(msg.sender != _ownable().owner) {
            revert IOwnable.NotOwner(msg.sender);
        }
        _;
    }
    
    /**
     * @notice Reverts if challenger is NOT proposed for ownership.
     */
    modifier onlyProposedOwner() {
        // _ifNotProposedOwner(challenger);
        if(msg.sender != _ownable().proposedOwner) {
            revert IOwnable.NotProposed(msg.sender);
        }
        _;
    }

}