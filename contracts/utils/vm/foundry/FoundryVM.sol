// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   FOUNDRY                                  */
/* -------------------------------------------------------------------------- */

import {VmSafe} from "forge-std/Vm.sol";
import {CommonBase} from "forge-std/Base.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {LOCAL} from "../../../networks/LOCAL.sol";

import {betterconsole as console} from "./tools/betterconsole.sol";

import {terminal as term} from "./tools/terminal.sol";

import {DevWallets} from "./tools/DevWallets.sol";

/**
 * @title FoundryVM - Utility functions for Foundry VM
 * @author cyotee doge <doge.cyotee>
 */
contract FoundryVM
is
DevWallets
{


    error FunctionNotSupportedInConext(VmSafe.ForgeContext context, string functionSig);

    /**
     * @dev Error thrown when a function is not supported in the current context.
     * @param context The context in which the function is not supported.
     * @param contractName The name of the contract that is not supported.
     */
    error ContractNotSupportedInConext(VmSafe.ForgeContext context, string contractName);

    /**
     * @dev Modifier to revert state after execution.
     */
    modifier dirtiesState() {
        // Take a snapshot of the state before executing the function.
        uint256 snapShot = vm.snapshotState();
        _;
        // Revert to the snapshot after executing the function.
        vm.revertToState(snapShot);
    }

    // /**
    //  * @dev Modifier to revert if the function is called in a context that is not in the TestGroup.
    //  * @param contractName The name of the contract that is not supported.
    //  */
    // modifier onlyAnyTest(string memory contractName) {
    //     if(!isAnyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
    //     }
    //     _;
    // }

    // /**
    //  * 
    //  */
    // modifier neverAnyTest(string memory contractName) {
    //     if(isAnyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
    //     }
    //     _;
    // }

    function isAnyTest()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.TestGroup);
    }

    // modifier onlyTest(string memory contractName) {
    //     if(!isOnlyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyTest(string memory contractName) {
    //     if(isOnlyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
    //     }
    //     _;
    // }

    function isOnlyTest()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Test);
    }

    // modifier onlyCoverage(string memory contractName) {
    //     if(!isOnlyCoverage()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
    //     }
    //     _;
    // }

    // modifier neverAnyCoverage(string memory contractName) {
    //     if(isOnlyCoverage()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
    //     }
    //     _;
    // }

    function isOnlyCoverage()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Coverage);
    }

    // modifier onlySnapshot(string memory contractName) {
    //     if(!isOnlySnapshot()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
    //     }
    //     _;
    // }

    // modifier neverSnapshot(string memory contractName) {
    //     if(isOnlySnapshot()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
    //     }
    //     _;
    // }

    function isOnlySnapshot()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Snapshot);
    }

    // modifier onlyScriptGroup(string memory contractName) {
    //     if(!isAnyScript()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
    //     }
    //     _;
    // }

    // modifier neverAnyScript(string memory contractName) {
    //     if(isAnyScript()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
    //     }
    //     _;
    // }

    function isAnyScript()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptGroup);
    }

    // modifier onlyDryRun(string memory contractName) {
    //     if(!isOnlyDryRun()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyDryRun(string memory contractName) {
    //     if(isOnlyDryRun()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
    //     }
    //     _;
    // }

    function isOnlyDryRun()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptDryRun);
    }

    // modifier onlyBroadcast(string memory contractName) {
    //     if(!isOnlyBroadcast()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyBroadcast(string memory contractName) {
    //     if(isOnlyBroadcast()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
    //     }
    //     _;
    // }

    function isOnlyBroadcast()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast);
    }

    // modifier onlyResume(string memory contractName) {
    //     if(!isOnlyResume()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyResume(string memory contractName) {
    //     if(isOnlyResume()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
    //     }
    //     _;
    // }

    function isOnlyResume()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptResume);
    }

    function contextNotSupported(string memory contractName) public view {
        if(vm.isContext(VmSafe.ForgeContext.TestGroup)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.Test)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.Coverage)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.Snapshot)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.ScriptGroup)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.ScriptDryRun)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
        } else
        if(vm.isContext(VmSafe.ForgeContext.ScriptResume)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
        }
    }

    // function startAs(
    //     address actor
    // ) public returns (bool) {
    //     CallerMode callerMode;
    //     address msgSender;
    //     address txOrigin;

    //     // Example 1
    //     (callerMode, msgSender, txOrigin) = vm.readCallers();

    //     return true;
    // }

    // function asNone()
    // public view returns(bool) {
    // }

    // function asBroadCast(
    //     address actor,
    //     address txOrigin,
    //     address msgSender
    // ) public returns(bool) {
    //     vm.stopBroadcast();
    //     vm.startBroadcast(actor);
    //     return true;
    // }

}