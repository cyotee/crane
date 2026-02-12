// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {Test_Crane} from "@crane/contracts/crane/test/Test_Crane.sol";
// import { IFacet } from "@crane/contracts/crane/interfaces/IFacet.sol";
import {Behavior_IERC165} from "@crane/contracts/introspection/ERC165/Behavior_IERC165.sol";

abstract contract TestBase_IERC165 is Test {
    /// @dev ERC165 interface ID (0x01ffc9a7)
    bytes4 internal constant ERC165_INTERFACE_ID = type(IERC165).interfaceId;

    IERC165 erc165TestSubject;

    function setUp() public virtual {
        erc165TestSubject = erc165_subject();
        Behavior_IERC165.expect_IERC165_supportsInterface(erc165TestSubject, expected_IERC165_interfaces());
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function erc165_subject() public virtual returns (IERC165 subject_);

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IERC165_interfaces() public virtual returns (bytes4[] memory expectedInterfaces_);

    function test_IERC165_supportsInterface() public virtual {
        // Verify ERC165 self-support (0x01ffc9a7) - required by ERC165 spec
        assertTrue(
            erc165TestSubject.supportsInterface(ERC165_INTERFACE_ID),
            "Contract must support ERC165 interface (0x01ffc9a7)"
        );

        // Validate all expected interfaces using Behavior library
        assertTrue(
            Behavior_IERC165.hasValid_IERC165_supportsInterface(erc165TestSubject),
            "ERC165 interface support validation failed"
        );
    }
}
