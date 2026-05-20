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

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _isApprovedSender(Storage storage layoutStruct, address recipient, address sender) internal view returns (bool) {
        return layoutStruct.isApprovedSenderForRecipient[recipient][sender];
    }

    function _isApprovedSender(address recipient, address sender) internal view returns (bool) {
        return _isApprovedSender(_layoutStruct(), recipient, sender);
    }

    function _allApprovedSenders(Storage storage layoutStruct, address recipient) internal view returns (address[] memory) {
        return layoutStruct.approvedSendersForRecipient[recipient]._values();
    }

    function _allApprovedSenders(address recipient) internal view returns (address[] memory) {
        return _allApprovedSenders(_layoutStruct(), recipient);
    }

    function _approveSender(Storage storage layoutStruct, address recipient, address sender) internal {
        layoutStruct.isApprovedSenderForRecipient[recipient][sender] = true;
        layoutStruct.approvedSendersForRecipient[recipient]._add(sender);
    }

    function _approveSender(address recipient, address sender) internal {
        _approveSender(_layoutStruct(), recipient, sender);
    }
}