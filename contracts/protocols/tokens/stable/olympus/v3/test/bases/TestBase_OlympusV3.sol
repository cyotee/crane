// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";

import {
    Kernel,
    Actions,
    Module,
    Policy,
    toKeycode,
    Keycode
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {OlympusERC20Token} from "@crane/contracts/protocols/tokens/stable/olympus/v3/external/OlympusERC20.sol";
import {OlympusMinter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/MINTR/OlympusMinter.sol";
import {OlympusRoles} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/OlympusRoles.sol";
import {RolesAdmin} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/RolesAdmin.sol";
import {Minter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/policies/Minter.sol";
import {
    MockLegacyAuthorityV2
} from "@crane/test/foundry/spec/protocols/tokens/stable/olympus/v3/mocks/MockLegacyAuthority.sol";
import {
    OlympusKernelService
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/services/OlympusKernelService.sol";

// tag::TestBase_OlympusV3[]
/**
 * @title TestBase_OlympusV3 - Hermetic Kernel + MINTR + ROLES + RolesAdmin + Minter graph.
 * @author Crane
 * @dev Deploys real ported contracts only (no SUT mocks). Executor/admin is this contract.
 */
abstract contract TestBase_OlympusV3 is Test {
    Kernel internal kernel;
    MockLegacyAuthorityV2 internal authority;
    OlympusERC20Token internal ohm;
    OlympusMinter internal mintr;
    OlympusRoles internal roles;
    RolesAdmin internal rolesAdmin;
    Minter internal minterPolicy;

    address internal recipient;
    bytes32 internal constant MINTER_ADMIN_ROLE = "minter_admin";
    bytes32 internal constant DEFAULT_MINT_CATEGORY = "dao_ms";

    function setUp() public virtual {
        recipient = makeAddr("recipient");

        // Kernel executor = this TestBase (msg.sender of constructor)
        kernel = new Kernel();
        authority = new MockLegacyAuthorityV2(address(this), address(this), address(this), address(0));
        ohm = new OlympusERC20Token(address(authority));
        mintr = new OlympusMinter(kernel, address(ohm));
        roles = new OlympusRoles(kernel);
        // OHM onlyVault: vault must be MINTR for mints
        authority.setVault(address(mintr));

        rolesAdmin = new RolesAdmin(kernel);
        minterPolicy = new Minter(kernel);

        vm.label(address(kernel), "Kernel");
        vm.label(address(ohm), "OHM");
        vm.label(address(mintr), "MINTR");
        vm.label(address(roles), "ROLES");
        vm.label(address(rolesAdmin), "RolesAdmin");
        vm.label(address(minterPolicy), "MinterPolicy");
        vm.label(recipient, "recipient");

        _bootstrapCore();
    }

    /// @dev Install MINTR/ROLES, activate RolesAdmin + Minter, grant minter_admin, approve mint category.
    function _bootstrapCore() internal virtual {
        OlympusKernelService._installModule(kernel, Module(address(mintr)));
        OlympusKernelService._installModule(kernel, Module(address(roles)));
        OlympusKernelService._activatePolicy(kernel, Policy(address(rolesAdmin)));
        OlympusKernelService._activatePolicy(kernel, Policy(address(minterPolicy)));

        // RolesAdmin.admin is constructor msg.sender (this)
        OlympusKernelService._grantRole(rolesAdmin, MINTER_ADMIN_ROLE, address(this));
        OlympusKernelService._addMintCategory(minterPolicy, DEFAULT_MINT_CATEGORY);
    }

    function _assertModuleInstalled(Keycode keycode_, address expected_) internal view {
        assertEq(address(kernel.getModuleForKeycode(keycode_)), expected_, "module install mismatch");
    }
}
// end::TestBase_OlympusV3[]
