// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {
    Behavior_ICallTargetRegistryManagement
} from "@crane/contracts/registries/target/Behavior_ICallTargetRegistryManagement.sol";

contract Handler_ICallTargetRegistryManagement {
    function recInvariant_setDefaultCallTargetForID(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address callTarget,
        bool expectedSuccess
    ) public {
        Behavior_ICallTargetRegistryManagement.expect_setDefaultCallTargetForID(
            subject, interfaceId, callTarget, expectedSuccess
        );
    }

    function recInvariant_setCallTargetForIDForCaller(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address caller,
        address callTarget,
        bool expectedSuccess
    ) public {
        Behavior_ICallTargetRegistryManagement.expect_setCallTargetForIDForCaller(
            subject, interfaceId, caller, callTarget, expectedSuccess
        );
    }

    function hasValid_setDefaultCallTargetForID(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address callTarget,
        bool expected
    ) public returns (bool) {
        return Behavior_ICallTargetRegistryManagement.hasValid_setDefaultCallTargetForID(
            subject, interfaceId, callTarget, expected
        );
    }

    function hasValid_setCallTargetForIDForCaller(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address caller,
        address callTarget,
        bool expected
    ) public returns (bool) {
        return Behavior_ICallTargetRegistryManagement.hasValid_setCallTargetForIDForCaller(
            subject, interfaceId, caller, callTarget, expected
        );
    }
}
