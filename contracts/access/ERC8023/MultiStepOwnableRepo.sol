// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";

// tag::MultiStepOwnableRepo[]
/**
 * @title MultiStepOwnableRepo
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage library for EIP-8023 two-step ownership transfer.
 * @dev Implements the Repo tier of Facet-Target-Repo. All functions have dual overloads:
 *      parameterized (taking explicit `Storage storage layoutStruct`) and default (using internal slot).
 *      Guard logic lives in _only* functions; duals delegate. Models OperableRepo + ERC2535Repo gold standard
 *      for NatSpec (@dev on Storage param = "The Storage struct to operate on."), tags, and ERC1967 slot form.
 * @dev This library is intended for internal use by MultiStepOwnableTarget/Facet and Modifiers.
 *      Initialization is typically performed once via package initAccount delegatecall.
 */
library MultiStepOwnableRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.8023"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, FacetRegistryRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.8023"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Storage layout for EIP-8023 Multi-Step Ownable.
     *      Owner is the current owner. pendingOwner / pendingOwnerConfirmed / bufferPeriodEnd support the
     *      two-step + buffer period confirmation flow defined by IMultiStepOwnable.
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
     * @dev Parameterized _layoutStruct allowing custom slot (for testing or special cases).
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-address-uint256)[]
    /**
     * @dev Parameterized initializer. Sets initial owner and buffer period.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param initialOwner_ First owner of the contract.
     * @param ownershipBufferPeriod_ Period (seconds) that must elapse between initiate and confirm.
     */
    function _initialize(Storage storage layoutStruct, address initialOwner_, uint256 ownershipBufferPeriod_) internal {
        layoutStruct.owner = initialOwner_;
        layoutStruct.ownershipBufferPeriod = ownershipBufferPeriod_;
    }

    // end::_initialize(Storage-address-uint256)[]

    // tag::_initialize(address-uint256)[]
    /**
     * @dev Default initializer. Delegates to parameterized form using _layoutStruct().
     * @param initialOwner_ First owner of the contract.
     * @param ownershipBufferPeriod_ Period (seconds) that must elapse between initiate and confirm.
     */
    function _initialize(address initialOwner_, uint256 ownershipBufferPeriod_) internal {
        _initialize(_layoutStruct(), initialOwner_, ownershipBufferPeriod_);
    }

    // end::_initialize(address-uint256)[]

    // tag::_onlyOwner(Storage)[]
    /**
     * @dev Guard: reverts with NotOwner if caller is not current owner.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     */
    function _onlyOwner(Storage storage layoutStruct) internal view {
        if (msg.sender != layoutStruct.owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
    }

    // end::_onlyOwner(Storage)[]

    // tag::_onlyOwner()[]
    /**
     * @dev Default guard delegating to _onlyOwner(_layoutStruct()).
     */
    function _onlyOwner() internal view {
        _onlyOwner(_layoutStruct());
    }

    // end::_onlyOwner()[]

    // tag::_onlyPendingOwner(Storage)[]
    /**
     * @dev Guard: reverts with NotPending if caller is not the current pendingOwner.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     */
    function _onlyPendingOwner(Storage storage layoutStruct) internal view {
        if (msg.sender != layoutStruct.pendingOwner) {
            revert IMultiStepOwnable.NotPending(msg.sender);
        }
    }

    // end::_onlyPendingOwner(Storage)[]

    // tag::_onlyPendingOwner()[]
    /**
     * @dev Default guard delegating to _onlyPendingOwner(_layoutStruct()).
     */
    function _onlyPendingOwner() internal view {
        _onlyPendingOwner(_layoutStruct());
    }

    // end::_onlyPendingOwner()[]

    // tag::_initiateOwnershipTransfer(Storage-address)[]
    /**
     * @dev Initiate two-step transfer (must be called by current owner).
     *      Sets buffer end and pendingOwner. Emits OwnershipTransferInitiated.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pendingOwner_ Address of the proposed new owner.
     */
    function _initiateOwnershipTransfer(Storage storage layoutStruct, address pendingOwner_) internal {
        address owner = layoutStruct.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        layoutStruct.bufferPeriodEnd = block.timestamp + layoutStruct.ownershipBufferPeriod;
        layoutStruct.pendingOwner = pendingOwner_;
        emit IMultiStepOwnable.OwnershipTransferInitiated(owner, pendingOwner_);
    }

    // end::_initiateOwnershipTransfer(Storage-address)[]

    // tag::_initiateOwnershipTransfer(address)[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @param pendingOwner_ Address of the proposed new owner.
     */
    function _initiateOwnershipTransfer(address pendingOwner_) internal {
        _initiateOwnershipTransfer(_layoutStruct(), pendingOwner_);
    }

    // end::_initiateOwnershipTransfer(address)[]

    // tag::_confirmOwnershipTransfer(Storage-address)[]
    /**
     * @dev Confirm a previously initiated transfer (owner only, after buffer elapsed, exact pending match).
     *      Sets pendingOwnerConfirmed. Emits OwnershipTransferConfirmed.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param pendingOwner_ Address of the proposed new owner to confirm (must match pending).
     */
    function _confirmOwnershipTransfer(Storage storage layoutStruct, address pendingOwner_) internal {
        address owner = layoutStruct.owner;
        if (msg.sender != owner) {
            revert IMultiStepOwnable.NotOwner(msg.sender);
        }
        if (block.timestamp < layoutStruct.bufferPeriodEnd) {
            revert IMultiStepOwnable.BufferPeriodNotElapsed(block.timestamp, layoutStruct.bufferPeriodEnd);
        }
        address expectedPendingOwner = layoutStruct.pendingOwner;
        if (pendingOwner_ != expectedPendingOwner) {
            revert IMultiStepOwnable.NotPending(pendingOwner_);
        }
        layoutStruct.pendingOwnerConfirmed = true;
        emit IMultiStepOwnable.OwnershipTransferConfirmed(owner, layoutStruct.pendingOwner);
    }

    // end::_confirmOwnershipTransfer(Storage-address)[]

    // tag::_confirmOwnershipTransfer(address)[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @param pendingOwner_ Address of the proposed new owner to confirm.
     */
    function _confirmOwnershipTransfer(address pendingOwner_) internal {
        _confirmOwnershipTransfer(_layoutStruct(), pendingOwner_);
    }

    // end::_confirmOwnershipTransfer(address)[]

    // tag::_cancelPendingOwnershipTransfer(Storage)[]
    /**
     * @dev Cancel a pending transfer (owner only). Clears pendingOwner, confirmed flag and buffer.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
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
     * @dev Default form delegating to parameterized using _layoutStruct().
     */
    function _cancelPendingOwnershipTransfer() internal {
        _cancelPendingOwnershipTransfer(_layoutStruct());
    }

    // end::_cancelPendingOwnershipTransfer()[]

    // tag::_acceptOwnershipTransfer(Storage)[]
    /**
     * @dev Accept pending ownership (must be called by the pendingOwner after confirmation).
     *      Transfers owner, clears pending state. Emits OwnershipTransferred.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
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
     * @dev Default form delegating to parameterized using _layoutStruct().
     */
    function _acceptOwnershipTransfer() internal {
        _acceptOwnershipTransfer(_layoutStruct());
    }

    // end::_acceptOwnershipTransfer()[]

    // tag::_owner(Storage)[]
    /**
     * @dev Returns the current owner.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return owner_ Current owner address.
     */
    function _owner(Storage storage layoutStruct) internal view returns (address owner_) {
        return layoutStruct.owner;
    }

    // end::_owner(Storage)[]

    // tag::_owner()[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @return owner_ Current owner address.
     */
    function _owner() internal view returns (address owner_) {
        return _owner(_layoutStruct());
    }

    // end::_owner()[]

    // tag::_pendingOwner(Storage)[]
    /**
     * @dev Returns the current pendingOwner (may be zero if none set).
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return pendingOwner_ Current pending owner address.
     */
    function _pendingOwner(Storage storage layoutStruct) internal view returns (address pendingOwner_) {
        return layoutStruct.pendingOwner;
    }

    // end::_pendingOwner(Storage)[]

    // tag::_pendingOwner()[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @return pendingOwner_ Current pending owner address.
     */
    function _pendingOwner() internal view returns (address pendingOwner_) {
        return _pendingOwner(_layoutStruct());
    }

    // end::_pendingOwner()[]

    // tag::_preConfirmedOwner(Storage)[]
    /**
     * @dev Returns pendingOwner only if the transfer has been confirmed by current owner; else address(0).
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return preConfirmedOwner_ The pre-confirmed pending owner or zero.
     */
    function _preConfirmedOwner(Storage storage layoutStruct) internal view returns (address preConfirmedOwner_) {
        if (!layoutStruct.pendingOwnerConfirmed) {
            return address(0);
        }
        return layoutStruct.pendingOwner;
    }

    // end::_preConfirmedOwner(Storage)[]

    // tag::_preConfirmedOwner()[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @return preConfirmedOwner_ The pre-confirmed pending owner or zero.
     */
    function _preConfirmedOwner() internal view returns (address preConfirmedOwner_) {
        return _preConfirmedOwner(_layoutStruct());
    }

    // end::_preConfirmedOwner()[]

    // tag::_ownershipBufferPeriod(Storage)[]
    /**
     * @dev Returns the configured buffer period (seconds) required between initiate and confirm.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return ownershipBufferPeriod_ The buffer period in seconds.
     */
    function _ownershipBufferPeriod(Storage storage layoutStruct)
        internal
        view
        returns (uint256 ownershipBufferPeriod_)
    {
        return layoutStruct.ownershipBufferPeriod;
    }

    // end::_ownershipBufferPeriod(Storage)[]

    // tag::_ownershipBufferPeriod()[]
    /**
     * @dev Default form delegating to parameterized using _layoutStruct().
     * @return ownershipBufferPeriod_ The buffer period in seconds.
     */
    function _ownershipBufferPeriod() internal view returns (uint256 ownershipBufferPeriod_) {
        return _ownershipBufferPeriod(_layoutStruct());
    }
    // end::_ownershipBufferPeriod()[]
}
// end::MultiStepOwnableRepo[]
