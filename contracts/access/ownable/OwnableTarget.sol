// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IOwnable
} from "./IOwnable.sol";

import {
    OwnableModifiers
} from "./OwnableModifiers.sol";

/**
 * @title OwnableTarget - Contract exposing IOwnable.
 * @author cyotee doge <doge.cyotee>
 */
contract OwnableTarget is OwnableModifiers, IOwnable {

    /**
     * @inheritdoc IOwnable
     */
    function owner()
    public view returns(address) {
        return _ownable().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function proposedOwner()
    public view returns(address) {
        return _ownable().proposedOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function transferOwnership(address proposedOwner_)
    public onlyOwner() returns(bool) {
        return _transferOwnerShip(proposedOwner_);
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership()
    public onlyProposedOwner() returns(bool) {
        return _acceptOwnership();
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceOwnership()
    public onlyOwner() returns(bool) {
        return _renounceOwnership();
    }

}