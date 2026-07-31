// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_OlympusV3
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/test/bases/TestBase_OlympusV3.sol";
import {
    OlympusKernelService
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/services/OlympusKernelService.sol";
import {
    OlympusKernelAwareRepo
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/aware/OlympusKernelAwareRepo.sol";
import {
    Behavior_IKernel
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Behavior_IKernel.sol";
import {
    Kernel,
    Module,
    Policy,
    Actions,
    toKeycode,
    Keycode
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {OlympusMinter} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/MINTR/OlympusMinter.sol";
import {OlympusRoles} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/OlympusRoles.sol";
import {MINTRv1} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/MINTR/MINTR.v1.sol";

/**
 * @title OlympusKernelAwareHarness
 * @notice Exposes OlympusKernelAwareRepo for unit tests.
 */
contract OlympusKernelAwareHarness {
    function initialize(
        Kernel kernel_,
        address ohm_,
        OlympusMinter mintr_,
        OlympusRoles roles_
    ) external {
        OlympusKernelAwareRepo._initialize(kernel_, ohm_, mintr_, roles_);
    }

    function kernel() external view returns (Kernel) {
        return OlympusKernelAwareRepo._kernel();
    }

    function ohm() external view returns (address) {
        return OlympusKernelAwareRepo._ohm();
    }

    function mintr() external view returns (OlympusMinter) {
        return OlympusKernelAwareRepo._mintr();
    }

    function roles() external view returns (OlympusRoles) {
        return OlympusKernelAwareRepo._roles();
    }

    function storageSlot() external pure returns (bytes32) {
        return OlympusKernelAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title OlympusKernelService_Test
 * @notice Production-first Service/Aware/Behavior tests against real Kernel graph.
 */
contract OlympusKernelService_Test is TestBase_OlympusV3 {
    OlympusKernelAwareHarness internal awareHarness;

    function setUp() public override {
        TestBase_OlympusV3.setUp();
        awareHarness = new OlympusKernelAwareHarness();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Kernel bootstrap                              */
    /* -------------------------------------------------------------------------- */

    function test_Service_installAndActivate_matchDirectKernelState() public view {
        assertTrue(
            Behavior_IKernel.areValid_IKernel_installState(kernel, Module(address(mintr))),
            "MINTR install state"
        );
        assertTrue(
            Behavior_IKernel.areValid_IKernel_installState(kernel, Module(address(roles))),
            "ROLES install state"
        );
        assertTrue(
            Behavior_IKernel.isValid_IKernel_policyActive(kernel, Policy(address(rolesAdmin)), true),
            "RolesAdmin active"
        );
        assertTrue(
            Behavior_IKernel.isValid_IKernel_policyActive(kernel, Policy(address(minterPolicy)), true),
            "Minter active"
        );

        // Permissions granted to Minter for mint + increase approval
        assertTrue(
            Behavior_IKernel.isValid_IKernel_permission(
                kernel,
                toKeycode("MINTR"),
                Policy(address(minterPolicy)),
                MINTRv1.mintOhm.selector,
                true
            ),
            "mintOhm permission"
        );
        assertTrue(
            Behavior_IKernel.isValid_IKernel_permission(
                kernel,
                toKeycode("MINTR"),
                Policy(address(minterPolicy)),
                MINTRv1.increaseMintApproval.selector,
                true
            ),
            "increaseMintApproval permission"
        );
    }

    function test_Service_getModule_typedHelpers() public view {
        assertEq(address(OlympusKernelService._mintr(kernel)), address(mintr), "mintr helper");
        assertEq(address(OlympusKernelService._roles(kernel)), address(roles), "roles helper");
        assertEq(
            address(OlympusKernelService._getModule(kernel, "MINTR")),
            address(mintr),
            "getModule MINTR string"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              MINTR mint path                               */
    /* -------------------------------------------------------------------------- */

    function test_Service_mint_exactOhmDelta() public {
        uint256 amount = 1_000_000_000; // 1 OHM (9 decimals)
        uint256 beforeBal = ohm.balanceOf(recipient);

        OlympusKernelService._mint(minterPolicy, recipient, amount, DEFAULT_MINT_CATEGORY);

        uint256 afterBal = ohm.balanceOf(recipient);
        assertEq(afterBal - beforeBal, amount, "exact OHM mint delta");
        assertEq(afterBal, amount, "recipient total OHM");
    }

    function test_Service_mint_requiresCategory() public {
        bytes32 unapproved = "unapproved_cat";
        vm.expectRevert(abi.encodeWithSignature("Minter_CategoryNotApproved()"));
        minterPolicy.mint(recipient, 1, unapproved);
    }

    /* -------------------------------------------------------------------------- */
    /*                              ROLES path                                    */
    /* -------------------------------------------------------------------------- */

    function test_Service_grantRole_exactHasRole() public {
        bytes32 role = "strategy_ops";
        address wallet = makeAddr("wallet");

        assertFalse(roles.hasRole(wallet, role), "precondition no role");
        OlympusKernelService._grantRole(rolesAdmin, role, wallet);
        assertTrue(roles.hasRole(wallet, role), "role granted");
    }

    function test_Service_revokeRole_viaRolesAdmin() public {
        bytes32 role = "temp_role";
        address wallet = makeAddr("wallet2");
        OlympusKernelService._grantRole(rolesAdmin, role, wallet);
        assertTrue(roles.hasRole(wallet, role));

        rolesAdmin.revokeRole(role, wallet);
        assertFalse(roles.hasRole(wallet, role), "role revoked");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Unpermissioned module reverts                      */
    /* -------------------------------------------------------------------------- */

    function test_unpermissioned_mintOhm_reverts_Module_PolicyNotPermitted() public {
        address stranger = makeAddr("stranger");
        bytes memory err = abi.encodeWithSelector(Module.Module_PolicyNotPermitted.selector, stranger);
        vm.expectRevert(err);
        vm.prank(stranger);
        mintr.mintOhm(recipient, 1);
    }

    function test_unpermissioned_saveRole_reverts_Module_PolicyNotPermitted() public {
        address stranger = makeAddr("stranger");
        bytes memory err = abi.encodeWithSelector(Module.Module_PolicyNotPermitted.selector, stranger);
        vm.expectRevert(err);
        vm.prank(stranger);
        roles.saveRole("x", stranger);
    }

    function test_nonExecutor_installModule_reverts_Kernel_OnlyExecutor() public {
        address stranger = makeAddr("stranger");
        OlympusMinter extra = new OlympusMinter(kernel, address(ohm));
        // Cannot reinstall MINTR; use a fresh Kernel for onlyExecutor check
        Kernel k2 = new Kernel();
        // k2 executor is this contract; prank stranger
        bytes memory err = abi.encodeWithSignature("Kernel_OnlyExecutor(address)", stranger);
        vm.expectRevert(err);
        vm.prank(stranger);
        k2.executeAction(Actions.InstallModule, address(extra));
    }

    /* -------------------------------------------------------------------------- */
    /*                              AwareRepo                                     */
    /* -------------------------------------------------------------------------- */

    function test_AwareRepo_initialize_roundTrip() public {
        bytes32 expectedSlot =
            bytes32(uint256(keccak256(abi.encode("protocols.tokens.stable.olympus.v3.kernel.aware"))) - 1);
        assertEq(awareHarness.storageSlot(), expectedSlot, "slot");

        awareHarness.initialize(kernel, address(ohm), mintr, roles);
        assertEq(address(awareHarness.kernel()), address(kernel));
        assertEq(awareHarness.ohm(), address(ohm));
        assertEq(address(awareHarness.mintr()), address(mintr));
        assertEq(address(awareHarness.roles()), address(roles));
    }
}
