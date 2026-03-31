// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {Behavior_IERC165} from "@crane/contracts/introspection/ERC165/Behavior_IERC165.sol";

contract Handler_ERC165 {
    using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;

    AddressSet _subjects;
    // mapping(address subject => Bytes4Set interfaces) _interfaceOfSubject;

    function recInvariant_supportsInterface(IERC165 subject, bytes4[] memory expected) public {
        _subjects._add(address(subject));
        // _interfaceOfSubject[address(subject)]._add(expected);
        Behavior_IERC165.expect_IERC165_supportsInterface(subject, expected);
    }

    function recInvariant_supportsInterface(IERC165 subject, bytes4 expected) public {
        _subjects._add(address(subject));
        // _interfaceOfSubject[address(subject)]._add(expected);
        Behavior_IERC165.expect_IERC165_supportsInterface(subject, expected);
    }

    function assert_IERC165(IERC165 subject) public view {
        assert_supportsInterface(subject);
    }

    function assert_supportsInterface(IERC165 subject) public view {
        assert(Behavior_IERC165.hasValid_IERC165_supportsInterface(subject));
    }
}
