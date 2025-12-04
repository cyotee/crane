// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";

contract MultiStepOwnableTarget is IMultiStepOwnable {
    /* -------------------------------------------------------------------------- */
    /*                          IMultiStepOwnable Functions                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function initiateOwnershipTransfer(address pendingOwner_) external {
        MultiStepOwnableRepo._initiateOwnershipTransfer(pendingOwner_);
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function confirmOwnershipTransfer(address pendingOwner_) external {
        MultiStepOwnableRepo._confirmOwnershipTransfer(pendingOwner_);
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function cancelPendingOwnershipTransfer() external {
        MultiStepOwnableRepo._cancelPendingOwnershipTransfer();
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function acceptOwnershipTransfer() external {
        MultiStepOwnableRepo._acceptOwnershipTransfer();
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function owner() external view returns (address) {
        return MultiStepOwnableRepo._owner();
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function pendingOwner() external view returns (address) {
        return MultiStepOwnableRepo._pendingOwner();
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function preConfirmedOwner() external view returns (address) {
        return MultiStepOwnableRepo._preConfirmedOwner();
    }

    /**
     * @inheritdoc IMultiStepOwnable
     */
    function getOwnershipTransferBuffer() external view returns (uint256) {
        return MultiStepOwnableRepo._ownershipBufferPeriod();
    }
}
