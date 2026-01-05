// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";

// tag::MultiStepOwnableTarget[]
/**
 * @title MultiStepOwnableTarget - Target contract implementing IMultiStepOwnable functions.
 * @author cyotee doge <not_cyotee@proton.me>
 * @custom:contract-list-ipfs
 */
contract MultiStepOwnableTarget is IMultiStepOwnable {
    /* -------------------------------------------------------------------------- */
    /*                          IMultiStepOwnable Functions                       */
    /* -------------------------------------------------------------------------- */

    // tag::initiateOwnershipTransfer(address)[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function initiateOwnershipTransfer(address pendingOwner_) external {
        MultiStepOwnableRepo._initiateOwnershipTransfer(pendingOwner_);
    }
    // end::initiateOwnershipTransfer(address)[]

    // tag::confirmOwnershipTransfer(address)[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function confirmOwnershipTransfer(address pendingOwner_) external {
        MultiStepOwnableRepo._confirmOwnershipTransfer(pendingOwner_);
    }
    // end::confirmOwnershipTransfer(address)[]

    // tag::cancelPendingOwnershipTransfer()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function cancelPendingOwnershipTransfer() external {
        MultiStepOwnableRepo._cancelPendingOwnershipTransfer();
    }
    // end::cancelPendingOwnershipTransfer()[]

    // tag::acceptOwnershipTransfer()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function acceptOwnershipTransfer() external {
        MultiStepOwnableRepo._acceptOwnershipTransfer();
    }
    // end::acceptOwnershipTransfer()[]

    // tag::owner()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function owner() external view returns (address) {
        return MultiStepOwnableRepo._owner();
    }
    // end::owner()[]

    // tag::pendingOwner()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function pendingOwner() external view returns (address) {
        return MultiStepOwnableRepo._pendingOwner();
    }
    // end::pendingOwner()[]

    // tag::preConfirmedOwner()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function preConfirmedOwner() external view returns (address) {
        return MultiStepOwnableRepo._preConfirmedOwner();
    }
    // end::preConfirmedOwner()[]

    // tag::getOwnershipTransferBuffer()[]
    /**
     * @inheritdoc IMultiStepOwnable
     */
    function getOwnershipTransferBuffer() external view returns (uint256) {
        return MultiStepOwnableRepo._ownershipBufferPeriod();
    }
    // end::getOwnershipTransferBuffer()[]
}
// end::MultiStepOwnableTarget[]