// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {Test} from "forge-std/Test.sol";

import {Behavior_IERC165} from "@crane/contracts/introspection/ERC165/Behavior_IERC165.sol";

contract Behavior_Stub_PartialIERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract Behavior_IERC165_Behavior_Test is Test {
    function test_IERC165_supportsInterface_full() public {
        Behavior_Stub_PartialIERC165 subject = new Behavior_Stub_PartialIERC165();

        bytes4[] memory expected = new bytes4[](1);
        expected[0] = type(IERC165).interfaceId;

        Behavior_IERC165.expect_IERC165_supportsInterface(IERC165(address(subject)), expected);

        bool ok = Behavior_IERC165.hasValid_IERC165_supportsInterface(IERC165(address(subject)));
        assertTrue(ok, "Behavior should report valid when all expected interfaces are supported");
    }

    function test_IERC165_supportsInterface_missing() public {
        Behavior_Stub_PartialIERC165 subject = new Behavior_Stub_PartialIERC165();

        bytes4[] memory expected = new bytes4[](2);
        expected[0] = type(IERC165).interfaceId;
        expected[1] = 0xdeadbeef;

        Behavior_IERC165.expect_IERC165_supportsInterface(IERC165(address(subject)), expected);

        bool ok = Behavior_IERC165.hasValid_IERC165_supportsInterface(IERC165(address(subject)));
        assertTrue(!ok, "Behavior should report missing interface (expected invalid)");
    }
}
