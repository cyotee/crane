// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.15;

import {BasePeriodicTaskManager} from "@crane/contracts/protocols/tokens/stable/olympus/v3/bases/BasePeriodicTaskManager.sol";

import {Kernel, Policy, Keycode, toKeycode, Permissions} from "@crane/contracts/protocols/tokens/stable/olympus/v3/Kernel.sol";
import {ROLESv1} from "@crane/contracts/protocols/tokens/stable/olympus/v3/modules/ROLES/ROLES.v1.sol";

contract MockPeriodicTaskManager is Policy, BasePeriodicTaskManager {
    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](1);
        dependencies[0] = toKeycode("ROLES");

        ROLES = ROLESv1(getModuleAddress(toKeycode("ROLES")));
    }

    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {}

    function executeAllTasks() external {
        _executePeriodicTasks();
    }
}
