// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {AddressSet, AddressSetRepo} from '@crane/contracts/utils/collections/sets/AddressSetRepo.sol';

library ApprovedMessageSenderRegistryRepo {
    using AddressSetRepo for AddressSet;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("crane.registries.message.sender.approved"));

    struct Storage {
        mapping(address recipient => AddressSet approvedSenders) approvedSendersForRecipient;
        mapping(address recipient => mapping(address sender => bool)) isApprovedSenderForRecipient;
    }

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _isApprovedSender(Storage storage layout_, address recipient, address sender) internal view returns (bool) {
        return layout_.isApprovedSenderForRecipient[recipient][sender];
    }

    function _isApprovedSender(address recipient, address sender) internal view returns (bool) {
        return _isApprovedSender(_layout(), recipient, sender);
    }

    function _allApprovedSenders(Storage storage layout_, address recipient) internal view returns (address[] memory) {
        return layout_.approvedSendersForRecipient[recipient]._values();
    }

    function _allApprovedSenders(address recipient) internal view returns (address[] memory) {
        return _allApprovedSenders(_layout(), recipient);
    }

    function _approveSender(Storage storage layout_, address recipient, address sender) internal {
        layout_.isApprovedSenderForRecipient[recipient][sender] = true;
        layout_.approvedSendersForRecipient[recipient]._add(sender);
    }

    function _approveSender(address recipient, address sender) internal {
        _approveSender(_layout(), recipient, sender);
    }
}