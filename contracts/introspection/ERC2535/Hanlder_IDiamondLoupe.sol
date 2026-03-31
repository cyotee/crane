// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Behavior_IDiamondLoupe} from "@crane/contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol";

contract Hanlder_IDiamondLoupe {
    AddressSet _subjects;

    function recInvariant_IDiamondLoupe(IDiamondLoupe subject) public {
        Behavior_IDiamondLoupe.expect_IDiamondLoupe(subject, subject.facets());
    }

    function assert_IDiamondLoupe(IDiamondLoupe subject) public {
        assert(Behavior_IDiamondLoupe.hasValid_IDiamondLoupe(subject));
    }
}
