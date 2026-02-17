// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OperableModifiers} from '@crane/contracts/access/operable/OperableModifiers.sol';
import {ApprovedMessageSenderRegistryRepo} from "@crane/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryRepo.sol";
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';

contract ApprovedMessageSenderRegistryTarget is OperableModifiers, IApprovedMessageSenderRegistry {
    function isApprovedSender(address recipient, address sender) external view returns (bool) {
        return ApprovedMessageSenderRegistryRepo._isApprovedSender(recipient, sender);
    }
    function allApprovedSenders(address recipient) external view returns (address[] memory) {
        return ApprovedMessageSenderRegistryRepo._allApprovedSenders(recipient);
    }
    function approveSender(address recipient, address sender) external onlyOwnerOrOperator returns (bool) {
        ApprovedMessageSenderRegistryRepo._approveSender(recipient, sender);
        return true;
    }
}