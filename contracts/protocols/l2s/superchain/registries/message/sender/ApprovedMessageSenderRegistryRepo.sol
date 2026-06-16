// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

// tag::ApprovedMessageSenderRegistryRepo[]
/**
 * @title ApprovedMessageSenderRegistryRepo
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage library for approved message senders registry (per-recipient allowlist of senders).
 * @dev Implements the Repo tier of the Facet-Target-Repo pattern for ApprovedMessageSenderRegistry.
 *      All functions have dual overloads: parameterized (explicit `Storage storage layoutStruct`) and default
 *      (using the internal ERC1967 STORAGE_SLOT). Follows gold standards from ERC20Repo, OperableRepo,
 *      MultiStepOwnableRepo, ERC2535Repo, DeployedAddressesRepo.
 * @dev This library is intended for internal use by the corresponding Target/Facet and related services.
 *      Initialization is typically performed via package initAccount delegatecall (higher layers).
 */
library ApprovedMessageSenderRegistryRepo {
    using AddressSetRepo for AddressSet;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.registries.message.sender.approved"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC20Repo, MultiStepOwnableRepo, ERC2535Repo,
     *      FacetRegistryRepo, CallTargetRegistryRepo and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.registries.message.sender.approved"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Storage layout for approved message sender registry.
     *      approvedSendersForRecipient: set of approved senders per recipient (for enumeration).
     *      isApprovedSenderForRecipient: direct bool lookup per (recipient, sender).
     */
    struct Storage {
        mapping(address recipient => AddressSet approvedSenders) approvedSendersForRecipient;
        mapping(address recipient => mapping(address sender => bool)) isApprovedSenderForRecipient;
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

    // tag::_isApprovedSender(Storage-address-address)[]
    /**
     * @dev Argumented version of _isApprovedSender to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param recipient The recipient address.
     * @param sender The potential sender address to check.
     * @return True if sender is approved for the recipient.
     */
    function _isApprovedSender(Storage storage layoutStruct, address recipient, address sender)
        internal
        view
        returns (bool)
    {
        return layoutStruct.isApprovedSenderForRecipient[recipient][sender];
    }
    // end::_isApprovedSender(Storage-address-address)[]

    // tag::_isApprovedSender(address-address)[]
    /**
     * @dev Default version of _isApprovedSender binding to the standard STORAGE_SLOT.
     * @param recipient The recipient address.
     * @param sender The potential sender address to check.
     * @return True if sender is approved for the recipient.
     */
    function _isApprovedSender(address recipient, address sender) internal view returns (bool) {
        return _isApprovedSender(_layoutStruct(), recipient, sender);
    }
    // end::_isApprovedSender(address-address)[]

    // tag::_allApprovedSenders(Storage-address)[]
    /**
     * @dev Argumented version of _allApprovedSenders to allow direct Storage access.
     *      Returns the enumerated set via AddressSetRepo.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param recipient The recipient address.
     * @return The array of approved sender addresses.
     */
    function _allApprovedSenders(Storage storage layoutStruct, address recipient)
        internal
        view
        returns (address[] memory)
    {
        return layoutStruct.approvedSendersForRecipient[recipient]._values();
    }
    // end::_allApprovedSenders(Storage-address)[]

    // tag::_allApprovedSenders(address)[]
    /**
     * @dev Default version of _allApprovedSenders binding to the standard STORAGE_SLOT.
     * @param recipient The recipient address.
     * @return The array of approved sender addresses.
     */
    function _allApprovedSenders(address recipient) internal view returns (address[] memory) {
        return _allApprovedSenders(_layoutStruct(), recipient);
    }
    // end::_allApprovedSenders(address)[]

    // tag::_approveSender(Storage-address-address)[]
    /**
     * @dev Argumented version of _approveSender to allow direct Storage access.
     *      Marks as approved in the bool map and adds to the enumerable set.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param recipient The recipient address.
     * @param sender The sender address to approve.
     */
    function _approveSender(Storage storage layoutStruct, address recipient, address sender) internal {
        layoutStruct.isApprovedSenderForRecipient[recipient][sender] = true;
        layoutStruct.approvedSendersForRecipient[recipient]._add(sender);
    }
    // end::_approveSender(Storage-address-address)[]

    // tag::_approveSender(address-address)[]
    /**
     * @dev Default version of _approveSender binding to the standard STORAGE_SLOT.
     * @param recipient The recipient address.
     * @param sender The sender address to approve.
     */
    function _approveSender(address recipient, address sender) internal {
        _approveSender(_layoutStruct(), recipient, sender);
    }
    // end::_approveSender(address-address)[]
}
// end::ApprovedMessageSenderRegistryRepo[]
