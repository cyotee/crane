// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CallTargetRegistryRepo} from "@crane/contracts/registries/target/CallTargetRegistryRepo.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";

contract CallTargetRegistryManagementTarget is MultiStepOwnableModifiers, ICallTargetRegistryManagement {
    function setDefaultCallTargetForID(bytes4 interfaceId, address callTarget)
        external
        onlyOwner
        returns (bool success_)
    {
        CallTargetRegistryRepo._setDefaultCallTargetForID(interfaceId, callTarget);
        success_ = true;
    }

    function setCallTargetForIDForCaller(bytes4 interfaceId, address caller, address callTarget)
        external
        onlyOwner
        returns (bool success_)
    {
        CallTargetRegistryRepo._setCallTargetForIDForCaller(interfaceId, caller, callTarget);
        success_ = true;
    }
}
