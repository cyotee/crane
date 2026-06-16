// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CallTargetRegistryRepo} from "@crane/contracts/registries/target/CallTargetRegistryRepo.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";

contract CallTargetRegistryQueryTarget is ICallTargetRegistryQuery {
    function defaultCallTargetForID(bytes4 interfaceId) external view returns (address callTarget_) {
        return CallTargetRegistryRepo._defaultCallTargetForID(interfaceId);
    }

    function callTargetForIDForCaller(bytes4 interfaceId, address caller) external view returns (address callTarget_) {
        return CallTargetRegistryRepo._callTargetForIDForCaller(interfaceId, caller);
    }
}
