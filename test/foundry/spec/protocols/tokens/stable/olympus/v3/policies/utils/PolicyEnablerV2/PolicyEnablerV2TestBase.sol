// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

import {Test} from "forge-std/Test.sol";

// Contracts
import {Kernel, Actions} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {OlympusRoles} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/OlympusRoles.sol";
import {RolesAdmin} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/RolesAdmin.sol";
import {MockPolicyEnablerV2} from "@crane/test/foundry/spec/protocols/tokens/stable/olympus/v3/policies/utils/PolicyEnablerV2/MockPolicyEnablerV2.sol";

import {ADMIN_ROLE, EMERGENCY_ROLE, MANAGER_ROLE} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/utils/RoleDefinitions.sol";

/// @notice Shared test base for `PolicyEnablerV2`. Wires the `OlympusRoles`
///         module, activates a `RolesAdmin` policy, then activates the mock
///         policy so that the role-gated entry points have a working roles
///         registry to consult. Defines named actors for each role and a
///         random caller, plus assertion helpers shared across the policy
///         tests.
contract PolicyEnablerV2TestBase is Test {
    // ========== EVENTS ========== //

    event Enabled();
    event Disabled();
    event Transition(address indexed by, bool indexed enable, bytes data, uint48 at);

    // ========== ACTORS ========== //

    address internal admin;
    address internal emergency;
    address internal manager;

    // ========== TIMING ========== //

    uint48 internal constant START_TIMESTAMP = 1_000_000;

    // ========== STATE ========== //

    Kernel internal kernel;
    OlympusRoles internal roles;
    RolesAdmin internal rolesAdmin;
    MockPolicyEnablerV2 internal policy;

    // ========== SETUP ========== //

    function setUp() public virtual {
        vm.warp(START_TIMESTAMP);

        admin = makeAddr("admin");
        emergency = makeAddr("emergency");
        manager = makeAddr("manager");

        kernel = new Kernel();
        vm.label(address(kernel), "Kernel");
        roles = new OlympusRoles(kernel);
        vm.label(address(roles), "OlympusRoles");
        rolesAdmin = new RolesAdmin(kernel);
        vm.label(address(rolesAdmin), "RolesAdmin");
        policy = new MockPolicyEnablerV2(kernel);
        vm.label(address(policy), "MockPolicyEnablerV2");

        kernel.executeAction(Actions.InstallModule, address(roles));
        kernel.executeAction(Actions.ActivatePolicy, address(rolesAdmin));
        kernel.executeAction(Actions.ActivatePolicy, address(policy));

        rolesAdmin.grantRole(ADMIN_ROLE, admin);
        rolesAdmin.grantRole(EMERGENCY_ROLE, emergency);
        rolesAdmin.grantRole(MANAGER_ROLE, manager);
    }

    // ========== HELPERS ========== //

    modifier givenEnabled() {
        vm.prank(admin);
        policy.enable("");
        _;
    }
}
