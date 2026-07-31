// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.24;

import {Kernel} from "@crane/contracts/protocols/tokens/stable/olympus/v2/Kernel.sol";

import {IMockPolicyAdmin} from "./IMockPolicyAdmin.sol";
import {MockPolicyAdmin} from "./MockPolicyAdmin.sol";
import {PolicyAdminOnlyEmergencyOrAdminRoleTests} from "./PolicyAdminOnlyEmergencyOrAdminRoleTests.sol";

/// @notice Runs the shared `onlyEmergencyOrAdminRole` tests against the `PolicyAdmin` mix-in.
contract PolicyAdmin_OnlyEmergencyOrAdminRoleTest is PolicyAdminOnlyEmergencyOrAdminRoleTests {
    function _deployPolicyAdmin(Kernel kernel_) internal override returns (IMockPolicyAdmin) {
        return new MockPolicyAdmin(kernel_);
    }
}
