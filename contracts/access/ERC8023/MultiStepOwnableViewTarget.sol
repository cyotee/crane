// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {IMultiStepOwnableView} from "@crane/contracts/access/ERC8023/IMultiStepOwnableView.sol";

// tag::MultiStepOwnableViewTarget[]
/**
 * @title MultiStepOwnableViewTarget - Target contract implementing IMultiStepOwnableView functions.
 * @author cyotee doge <not_cyotee@proton.me>
 */
contract MultiStepOwnableViewTarget is IMultiStepOwnableView {
    /* -------------------------------------------------------------------------- */
    /*                          IMultiStepOwnableView Functions                   */
    /* -------------------------------------------------------------------------- */

    // tag::owner()[]
    /**
     * @inheritdoc IMultiStepOwnableView
     */
    function owner() external view returns (address) {
        return MultiStepOwnableRepo._owner();
    }

    // end::owner()[]

    // tag::pendingOwner()[]
    /**
     * @inheritdoc IMultiStepOwnableView
     */
    function pendingOwner() external view returns (address) {
        return MultiStepOwnableRepo._pendingOwner();
    }

    // end::pendingOwner()[]

    // tag::preConfirmedOwner()[]
    /**
     * @inheritdoc IMultiStepOwnableView
     */
    function preConfirmedOwner() external view returns (address) {
        return MultiStepOwnableRepo._preConfirmedOwner();
    }

    // end::preConfirmedOwner()[]

    // tag::getOwnershipTransferBuffer()[]
    /**
     * @inheritdoc IMultiStepOwnableView
     */
    function getOwnershipTransferBuffer() external view returns (uint256) {
        return MultiStepOwnableRepo._ownershipBufferPeriod();
    }
    // end::getOwnershipTransferBuffer()[]
}
// end::MultiStepOwnableViewTarget[]
