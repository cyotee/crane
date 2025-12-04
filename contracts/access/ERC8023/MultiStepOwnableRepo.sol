// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";

library MultiStepOwnableRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("daosys.crane.contracts.access.ownable.OwnableRepo");

    struct Storage {
        address owner;
        address pendingOwner;
        bool pendingOwnerConfirmed;
        uint256 ownershipBufferPeriod;
        uint256 bufferPeriodEnd;
    }

    function _layout() internal pure returns (Storage storage layout) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            layout.slot := slot
        }
    }

    function _initialize(Storage storage layout, address initialOwner, uint256 ownershipBufferPeriod)
        internal
    {
        layout.owner = initialOwner;
        layout.ownershipBufferPeriod = ownershipBufferPeriod;
    }

    function _initialize(address initialOwner, uint256 ownershipBufferPeriod) internal {
        _initialize(_layout(), initialOwner, ownershipBufferPeriod);
    }

    function _onlyOwner(Storage storage layout) internal view {
        if (msg.sender != layout.owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
    }

    function _onlyOwner() internal view {
        _onlyOwner(_layout());
    }

    function _onlyPendingOwner(Storage storage layout) internal view {
        if (msg.sender != layout.pendingOwner) {
            revert IMultiStepOwnable.NotPending(msg.sender);
        }
    }

    function _onlyPendingOwner() internal view {
        _onlyPendingOwner(_layout());
    }

    function _initiateOwnershipTransfer(Storage storage layout, address pendingOwner) internal {
        address owner = layout.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        layout.bufferPeriodEnd = block.timestamp + layout.ownershipBufferPeriod;
        layout.pendingOwner = pendingOwner;
        emit IMultiStepOwnable.OwnershipTransferInitiated(owner, pendingOwner);
    }

    function _initiateOwnershipTransfer(address pendingOwner) internal {
        _initiateOwnershipTransfer(_layout(), pendingOwner);
    }

    function _confirmOwnershipTransfer(Storage storage layout, address pendingOwner) internal {
        address owner = layout.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        if (block.timestamp < layout.bufferPeriodEnd) {
            revert IMultiStepOwnable.BufferPeriodNotElapsed(block.timestamp, layout.bufferPeriodEnd);
        }
        address expectedPendingOwner = layout.pendingOwner;
        if (pendingOwner != expectedPendingOwner) {
            revert IMultiStepOwnable.NotPending(pendingOwner);
        }
        layout.pendingOwnerConfirmed = true;
        emit IMultiStepOwnable.OwnershipTransferConfirmed(owner, layout.pendingOwner);
    }

    function _confirmOwnershipTransfer(address pendingOwner) internal {
        _confirmOwnershipTransfer(_layout(), pendingOwner);
    }

    function _cancelPendingOwnershipTransfer(Storage storage layout) internal {
        address owner = layout.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        delete layout.pendingOwner;
        delete layout.pendingOwnerConfirmed;
        delete layout.bufferPeriodEnd;
    }

    function _cancelPendingOwnershipTransfer() internal {
        _cancelPendingOwnershipTransfer(_layout());
    }

    function _acceptOwnershipTransfer(Storage storage layout) internal {
        address pendingOwner = layout.pendingOwner;
        if (msg.sender != pendingOwner) {
            revert IMultiStepOwnable.NotPending(msg.sender);
        }
        address previousOwner = layout.owner;
        layout.owner = pendingOwner;
        delete layout.pendingOwner;
        delete layout.pendingOwnerConfirmed;
        delete layout.bufferPeriodEnd;
        emit IMultiStepOwnable.OwnershipTransferred(previousOwner, pendingOwner);
    }

    function _acceptOwnershipTransfer() internal {
        _acceptOwnershipTransfer(_layout());
    }

    function _owner(Storage storage layout) internal view returns (address) {
        return layout.owner;
    }

    function _owner() internal view returns (address) {
        return _owner(_layout());
    }

    function _pendingOwner(Storage storage layout) internal view returns (address) {
        return layout.pendingOwner;
    }

    function _pendingOwner() internal view returns (address) {
        return _pendingOwner(_layout());
    }

    function _preConfirmedOwner(Storage storage layout) internal view returns (address) {
        if (!layout.pendingOwnerConfirmed) {
            return address(0);
        }
        return layout.pendingOwner;
    }

    function _preConfirmedOwner() internal view returns (address) {
        return _preConfirmedOwner(_layout());
    }

    function _ownershipBufferPeriod(Storage storage layout) internal view returns (uint256) {
        return layout.ownershipBufferPeriod;
    }

    function _ownershipBufferPeriod() internal view returns (uint256) {
        return _ownershipBufferPeriod(_layout());
    }
}
