// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Vm} from "forge-std/Vm.sol";
import {
    Kernel,
    Module,
    Policy,
    Keycode,
    Actions
} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";

// tag::Behavior_IKernel[]
/**
 * @title Behavior_IKernel - Validation helpers for Olympus Kernel consumer surface.
 * @author Crane
 */
library Behavior_IKernel {
    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    function _Behavior_IKernelName() internal pure returns (string memory) {
        return type(Behavior_IKernel).name;
    }

    // tag::isValid_IKernel_moduleInstalled[]
    /**
     * @notice Module for keycode must match expected address.
     */
    function isValid_IKernel_moduleInstalled(
        Kernel subject,
        Keycode keycode,
        address expectedModule,
        address actualModule
    ) internal view returns (bool valid) {
        valid = expectedModule == actualModule && address(subject.getModuleForKeycode(keycode)) == expectedModule;
        if (!valid) {
            // solhint-disable-next-line no-console
        }
        return valid;
    }
    // end::isValid_IKernel_moduleInstalled[]

    // tag::isValid_IKernel_policyActive[]
    function isValid_IKernel_policyActive(Kernel subject, Policy policy, bool expectedActive)
        internal
        view
        returns (bool valid)
    {
        valid = subject.isPolicyActive(policy) == expectedActive;
        return valid;
    }
    // end::isValid_IKernel_policyActive[]

    // tag::isValid_IKernel_permission[]
    function isValid_IKernel_permission(
        Kernel subject,
        Keycode keycode,
        Policy policy,
        bytes4 selector,
        bool expected
    ) internal view returns (bool valid) {
        valid = subject.modulePermissions(keycode, policy, selector) == expected;
        return valid;
    }
    // end::isValid_IKernel_permission[]

    // tag::areValid_IKernel_installState[]
    /**
     * @notice After InstallModule: keycode maps both ways and module address matches.
     */
    function areValid_IKernel_installState(Kernel subject, Module module) internal view returns (bool valid) {
        Keycode keycode = module.KEYCODE();
        valid = address(subject.getModuleForKeycode(keycode)) == address(module)
            && Keycode.unwrap(subject.getKeycodeForModule(module)) == Keycode.unwrap(keycode);
        return valid;
    }
    // end::areValid_IKernel_installState[]
}
// end::Behavior_IKernel[]
