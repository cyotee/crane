// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.20;

import {PolicyEnablerTest} from "./PolicyEnablerTest.sol";

import {IERC165} from "@crane/contracts/external/openzeppelin-contracts-v5/interfaces/IERC165.sol";
import {IEnabler} from "@crane/contracts/protocols/tokens/stable/olympus/v3/periphery/interfaces/IEnabler.sol";
import {IERC20} from "@crane/contracts/protocols/tokens/stable/olympus/v3/interfaces/IERC20.sol";
import {ERC165Helper} from "@crane/test/foundry/spec/protocols/tokens/stable/olympus/v3/lib/ERC165.sol";

contract PolicyEnablerSupportsInterfaceTest is PolicyEnablerTest {
    function test_supportsInterface() public view {
        ERC165Helper.validateSupportsInterface(address(policyEnabler));
        assertEq(
            policyEnabler.supportsInterface(type(IERC165).interfaceId),
            true,
            "IERC165 mismatch"
        );
        assertEq(
            policyEnabler.supportsInterface(type(IEnabler).interfaceId),
            true,
            "IEnabler mismatch"
        );

        // Test non-implemented interfaces (should be false)
        assertEq(
            policyEnabler.supportsInterface(type(IERC20).interfaceId),
            false,
            "Should not support IERC20"
        );
    }
}
