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
 * @dev Typically only required in packages to initialize owner.
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

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _initialize to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to initialize.
     * @param initialOwner First owner of the contract.
     * @param ownershipBufferPeriod Period new ownership transfers must wait before confirmation.
     */
    function _initialize(Storage storage layoutStruct, address initialOwner, uint256 ownershipBufferPeriod) internal {
        layoutStruct.owner = initialOwner;
        layoutStruct.ownershipBufferPeriod = ownershipBufferPeriod;
    }
    // end::_initialize(Storage-address-uint256)[]

    // tag::_initialize(address-uint256)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param initialOwner First owner of the contract.
     * @param ownershipBufferPeriod Period new ownership transfers must wait before confirmation.
     */
    function _initialize(address initialOwner, uint256 ownershipBufferPeriod) internal {
        _initialize(_layoutStruct(), initialOwner, ownershipBufferPeriod);
    }
    // end::_initialize(address-uint256)[]

    // tag::_onlyOwner(Storage)[]
    /**
     * @dev Revert if msg.sender is not the current owner.
     * @param layoutStruct Storage pointer to Storage struct to check.
     */
    function _onlyOwner(Storage storage layoutStruct) internal view {
        if (msg.sender != layoutStruct.owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
    }
    // end::_onlyOwner(Storage)[]

    // tag::_onlyOwner()[]
    /**
     * @dev Default version of _onlyOwner binding to the standard STORAGE_SLOT.
     */
    function _onlyOwner() internal view {
        _onlyOwner(_layoutStruct());
    }
    // end::_onlyOwner()[]

    // tag::_onlyPendingOwner(Storage)[]
    /**
     * @dev Revert if msg.sender is not the current pending owner.
     * @param layoutStruct Storage pointer to Storage struct to check.
     */
    function _onlyPendingOwner(Storage storage layoutStruct) internal view {
        if (msg.sender != layoutStruct.pendingOwner) {
            revert IMultiStepOwnable.NotPending(msg.sender);
        }
    }
    // end::_onlyPendingOwner(Storage)[]

    // tag::_onlyPendingOwner()[]
    /**
     * @dev Default version of _onlyPendingOwner binding to the standard STORAGE_SLOT.
     */
    function _onlyPendingOwner() internal view {
        _onlyPendingOwner(_layoutStruct());
    }
    // end::_onlyPendingOwner()[]

    // tag::_initiateOwnershipTransfer(Storage-address)[]
    /**
     * @dev Argumented version of _initiateOwnershipTransfer to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to update.
     * @param pendingOwner Address of the proposed new owner.
     */
    function _initiateOwnershipTransfer(Storage storage layoutStruct, address pendingOwner) internal {
        address owner = layoutStruct.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        layoutStruct.bufferPeriodEnd = block.timestamp + layoutStruct.ownershipBufferPeriod;
        layoutStruct.pendingOwner = pendingOwner;
        emit IMultiStepOwnable.OwnershipTransferInitiated(owner, pendingOwner);
    }
    // end::_initiateOwnershipTransfer(Storage-address)[]

    // tag::_initiateOwnershipTransfer(address)[]
    /**
     * @dev Default version of _initiateOwnershipTransfer binding to the standard STORAGE_SLOT.
     * @param pendingOwner Address of the proposed new owner.
     */
    function _initiateOwnershipTransfer(address pendingOwner) internal {
        _initiateOwnershipTransfer(_layoutStruct(), pendingOwner);
    }
    // end::_initiateOwnershipTransfer(address)[]

    // tag::_confirmOwnershipTransfer(Storage-address)[]
    /**
     * @dev Argumented version of _confirmOwnershipTransfer to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to update.
     * @param pendingOwner Address of the proposed new owner to confirm.
     */
    function _confirmOwnershipTransfer(Storage storage layoutStruct, address pendingOwner) internal {
        address owner = layoutStruct.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        if (block.timestamp < layoutStruct.bufferPeriodEnd) {
            revert IMultiStepOwnable.BufferPeriodNotElapsed(block.timestamp, layoutStruct.bufferPeriodEnd);
        }
        address expectedPendingOwner = layoutStruct.pendingOwner;
        if (pendingOwner != expectedPendingOwner) {
            revert IMultiStepOwnable.NotPending(pendingOwner);
        }
        layoutStruct.pendingOwnerConfirmed = true;
        emit IMultiStepOwnable.OwnershipTransferConfirmed(owner, layoutStruct.pendingOwner);
    }
    // end::_confirmOwnershipTransfer(Storage-address)[]

    // tag::_confirmOwnershipTransfer(address)[]
    /**
     * @dev Default version of _confirmOwnershipTransfer binding to the standard STORAGE_SLOT.
     * @param pendingOwner Address of the proposed new owner to confirm.
     */
    function _confirmOwnershipTransfer(address pendingOwner) internal {
        _confirmOwnershipTransfer(_layoutStruct(), pendingOwner);
    }
    // end::_confirmOwnershipTransfer(address)[]

    // tag::_cancelPendingOwnershipTransfer(Storage)[]
    /**
     * @dev Argumented version of _cancelPendingOwnershipTransfer to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to update.
     */
    function _cancelPendingOwnershipTransfer(Storage storage layoutStruct) internal {
        address owner = layoutStruct.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        delete layoutStruct.pendingOwner;
        delete layoutStruct.pendingOwnerConfirmed;
        delete layoutStruct.bufferPeriodEnd;
    }
    // end::_cancelPendingOwnershipTransfer(Storage)[]

    // tag::_cancelPendingOwnershipTransfer()[]
    /**
     * @dev Default version of _cancelPendingOwnershipTransfer binding to the standard STORAGE_SLOT.
     */
    function _cancelPendingOwnershipTransfer() internal {
        _cancelPendingOwnershipTransfer(_layoutStruct());
    }
    // end::_cancelPendingOwnershipTransfer()[]

    // tag::_acceptOwnershipTransfer(Storage)[]
    /**
     * @dev Argumented version of _acceptOwnershipTransfer to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to update.
     */
    function _acceptOwnershipTransfer(Storage storage layoutStruct) internal {
        address pendingOwner = layoutStruct.pendingOwner;
        if (msg.sender != pendingOwner) {
            revert IMultiStepOwnable.NotPending(msg.sender);
        }
        address previousOwner = layoutStruct.owner;
        layoutStruct.owner = pendingOwner;
        delete layoutStruct.pendingOwner;
        delete layoutStruct.pendingOwnerConfirmed;
        delete layoutStruct.bufferPeriodEnd;
        emit IMultiStepOwnable.OwnershipTransferred(previousOwner, pendingOwner);
    }
    // end::_acceptOwnershipTransfer(Storage)[]

    // tag::_acceptOwnershipTransfer()[]
    /**
     * @dev Default version of _acceptOwnershipTransfer binding to the standard STORAGE_SLOT.
     */
    function _acceptOwnershipTransfer() internal {
        _acceptOwnershipTransfer(_layoutStruct());
    }
    // end::_acceptOwnershipTransfer()[]

    // tag::_owner(Storage)[]
    /**
     * @dev Argumented version of _owner to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to read.
     */
    function _owner(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.owner;
    }
    // end::_owner(Storage)[]

    // tag::_owner()[]
    /**
     * @dev Default version of _owner binding to the standard STORAGE_SLOT.
     */
    function _owner() internal view returns (address) {
        return _owner(_layoutStruct());
    }
    // end::_owner()[]

    // tag::_pendingOwner(Storage)[]
    /**
     * @dev Argumented version of _pendingOwner to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to read.
     */
    function _pendingOwner(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.pendingOwner;
    }
    // end::_pendingOwner(Storage)[]

    // tag::_pendingOwner()[]
    /**
     * @dev Default version of _pendingOwner binding to the standard STORAGE_SLOT.
     */
    function _pendingOwner() internal view returns (address) {
        return _pendingOwner(_layoutStruct());
    }
    // end::_pendingOwner()[]

    // tag::_preConfirmedOwner(Storage)[]
    /**
     * @dev Argumented version of _preConfirmedOwner to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to read.
     */
    function _preConfirmedOwner(Storage storage layoutStruct) internal view returns (address) {
        if (!layoutStruct.pendingOwnerConfirmed) {
            return address(0);
        }
        return layoutStruct.pendingOwner;
    }
    // end::_preConfirmedOwner(Storage)[]

    // tag::_preConfirmedOwner()[]
    /**
     * @dev Default version of _preConfirmedOwner binding to the standard STORAGE_SLOT.
     */
    function _preConfirmedOwner() internal view returns (address) {
        return _preConfirmedOwner(_layoutStruct());
    }

    // end::_preConfirmedOwner()[]

    // tag::_ownershipBufferPeriod(Storage)[]
    /**
     * @dev Argumented version of _ownershipBufferPeriod to allow for custom storage slot usage.
     * @param layoutStruct Storage pointer to Storage struct to read.
     */
    function _ownershipBufferPeriod(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.ownershipBufferPeriod;
    }
    // end::_ownershipBufferPeriod(Storage)[]

    // tag::_ownershipBufferPeriod()[]
    /**
     * @dev Default version of _ownershipBufferPeriod binding to the standard STORAGE_SLOT.
     */
    function _ownershipBufferPeriod() internal view returns (uint256) {
        return _ownershipBufferPeriod(_layoutStruct());
    }
    // end::_ownershipBufferPeriod()[]
}
// end::MultiStepOwnableRepo[]
