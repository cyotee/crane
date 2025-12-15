// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";

// tag::MultiStepOwnableRepo[]
/**
 * @title MultiStepOwnableRepo - Storage logic for MultiStepOwnable functionality.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Library to be used by contracts implementing multi-step ownership transfer.
 * @dev Typically direct usage is not required.
 * @dev All required functionality should be available in the Modifiers and Facet contracts.
 * @dev You may reuse by inheriting MultiStepOwnableModifiers and composing MultiStepOwnableFacet into your proxy.
 */
library MultiStepOwnableRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for EIP-8023 Multi-Step Ownable data.
     */
    bytes32 internal constant STORAGE_SLOT = keccak256("eip.erc.8023");
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for EIP-8023 Multi-Step Ownable data.
     */
    struct Storage {
        address owner;
        address pendingOwner;
        bool pendingOwnerConfirmed;
        uint256 ownershipBufferPeriod;
        uint256 bufferPeriodEnd;
    }
    // end::Storage[]

    // tag::_layout(bytes32)[]
    /**
     * @dev Argumented version of _layout to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layout The bound Storage struct.
     */
    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }
    // end::_layout(bytes32)[]

    // tag::_layout()[]
    /**
     * @dev Default version of _layout binding to the standard STORAGE_SLOT.
     * @return layout The bound Storage struct.
     */
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }
    // end::_layout()[]

    // tag::_initialize(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _initialize to allow for custom storage slot usage.
     * @param layout Storage pointer to Storage struct to initialize.
     * @param initialOwner First owner of the contract.
     * @param ownershipBufferPeriod Period new ownership transfers must wait before confirmation.
     */
    function _initialize(Storage storage layout, address initialOwner, uint256 ownershipBufferPeriod)
        internal
    {
        layout.owner = initialOwner;
        layout.ownershipBufferPeriod = ownershipBufferPeriod;
    }
    // end::_initialize(Storage-address-uint256)[]

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
// end::MultiStepOwnableRepo[]