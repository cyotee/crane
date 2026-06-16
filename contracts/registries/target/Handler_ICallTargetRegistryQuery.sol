// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {
    Behavior_ICallTargetRegistryQuery
} from "@crane/contracts/registries/target/Behavior_ICallTargetRegistryQuery.sol";

contract Handler_ICallTargetRegistryQuery {
    function recInvariant_defaultCallTargetForID(ICallTargetRegistryQuery subject, bytes4 interfaceId, address expected)
        public
    {
        Behavior_ICallTargetRegistryQuery.expect_defaultCallTargetForID(subject, interfaceId, expected);
    }

    function recInvariant_callTargetForIDForCaller(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expected
    ) public {
        Behavior_ICallTargetRegistryQuery.expect_callTargetForIDForCaller(subject, interfaceId, caller, expected);
    }

    function hasValid_ICallTargetRegistryQuery(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expectedDefault,
        address expectedForCaller
    ) public returns (bool) {
        return Behavior_ICallTargetRegistryQuery.hasValid_ICallTargetRegistryQuery(
            subject, interfaceId, caller, expectedDefault, expectedForCaller
        );
    }
}
