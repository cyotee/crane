// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Test_Crane } from "../Test_Crane.sol";
import { IFacet } from "../../interfaces/IFacet.sol";
import { Behavior_IERC165 } from "../behaviors/Behavior_IERC165.sol";

abstract contract TestBase_IERC165 is Test_Crane, Behavior_IERC165 {

    function setUp() public virtual override {
        expect_IERC165_supportsInterface(
            erc165_subject(),
            expected_IERC165_interfaces()
        );
    }

    function erc165_subject() public virtual returns(IERC165 subject_);

    function expected_IERC165_interfaces() public virtual returns(bytes4[] memory expectedInterfaces_);

    function test_IERC165_supportsInterface() public virtual {
        hasValid_IERC165_supportsInterface(erc165_subject());
    }

}