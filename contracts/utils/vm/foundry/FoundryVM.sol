// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   FOUNDRY                                  */
/* -------------------------------------------------------------------------- */

// import "forge-std/Vm.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {CommonBase} from "forge-std/Base.sol";

import {LOCAL} from "../../../networks/LOCAL.sol";

import {betterconsole as console} from "./tools/console/betterconsole.sol";

import {terminal as term} from "./tools/terminal/terminal.sol";

contract FoundryVM
is
CommonBase
{

    modifier dirtiesState() {
        uint256 snapShot = vm.snapshotState();
        _;
        vm.revertToState(snapShot);
    }

    function foundry()
    public virtual returns(FoundryVM) {
        return this;
    }

    VmSafe.Wallet internal _dev0Wallet;

    function dev0Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev0Wallet.addr == address(0)) {
            _dev0Wallet = vm.createWallet(LOCAL.WALLET_0_KEY);
            vm.rememberKey(_dev0Wallet.privateKey);
        }
        return _dev0Wallet;
    }

    function dev0()
    public returns(address) {
        return dev0Wallet().addr;
    }

    VmSafe.Wallet internal _dev1Wallet;

    function dev1Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev1Wallet.addr == address(0)) {
            _dev1Wallet = vm.createWallet(LOCAL.WALLET_1_KEY);
            vm.rememberKey(_dev1Wallet.privateKey);
        }
        return _dev1Wallet;
    }

    function dev1()
    public returns(address) {
        return dev1Wallet().addr;
    }

    VmSafe.Wallet internal _dev2Wallet;

    function dev2Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev2Wallet.addr == address(0)) {
            _dev2Wallet = vm.createWallet(LOCAL.WALLET_2_KEY);
            vm.rememberKey(_dev2Wallet.privateKey);
        }
        return _dev2Wallet;
    }

    function dev2()
    public returns(address) {
        return dev2Wallet().addr;
    }

    VmSafe.Wallet internal _dev3Wallet;

    function dev3Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev3Wallet.addr == address(0)) {
            _dev3Wallet = vm.createWallet(LOCAL.WALLET_3_KEY);
            vm.rememberKey(_dev3Wallet.privateKey);
        }
        return _dev3Wallet;
    }

    function dev3()
    public returns(address) {
        return dev3Wallet().addr;
    }

    VmSafe.Wallet internal _dev4Wallet;

    function dev4Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev4Wallet.addr == address(0)) {
            _dev4Wallet = vm.createWallet(LOCAL.WALLET_4_KEY);
            vm.rememberKey(_dev4Wallet.privateKey);
        }
        return _dev4Wallet;
    }

    function dev4()
    public returns(address) {
        return dev4Wallet().addr;
    }

    VmSafe.Wallet internal _dev5Wallet;

    function dev5Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev5Wallet.addr == address(0)) {
            _dev5Wallet = vm.createWallet(LOCAL.WALLET_5_KEY);
            vm.rememberKey(_dev5Wallet.privateKey);
        }
        return _dev5Wallet;
    }

    function dev5()
    public returns(address) {
        return dev5Wallet().addr;
    }

    VmSafe.Wallet internal _dev6Wallet;

    function dev6Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev6Wallet.addr == address(0)) {
            _dev6Wallet = vm.createWallet(LOCAL.WALLET_6_KEY);
            vm.rememberKey(_dev6Wallet.privateKey);
        }
        return _dev6Wallet;
    }

    function dev6()
    public returns(address) {
        return dev6Wallet().addr;
    }

    VmSafe.Wallet internal _dev7Wallet;

    function dev7Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev7Wallet.addr == address(0)) {
            _dev7Wallet = vm.createWallet(LOCAL.WALLET_7_KEY);
            vm.rememberKey(_dev7Wallet.privateKey);
        }
        return _dev7Wallet;
    }

    function dev7()
    public returns(address) {
        return dev7Wallet().addr;
    }

    VmSafe.Wallet internal _dev8Wallet;

    function dev8Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev8Wallet.addr == address(0)) {
            _dev8Wallet = vm.createWallet(LOCAL.WALLET_8_KEY);
            vm.rememberKey(_dev8Wallet.privateKey);
        }
        return _dev8Wallet;
    }

    function dev8()
    public returns(address) {
        return dev8Wallet().addr;
    }

    VmSafe.Wallet internal _dev9Wallet;

    function dev9Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev9Wallet.addr == address(0)) {
            _dev9Wallet = vm.createWallet(LOCAL.WALLET_9_KEY);
            vm.rememberKey(_dev9Wallet.privateKey);
        }
        return _dev9Wallet;
    }

    function dev9()
    public returns(address) {
        return dev9Wallet().addr;
    }

    function isAnyTest()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.TestGroup);
    }

    function isOnlyTest()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Test);
    }

    function isOnlyCoverage()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Coverage);
    }

    function isOnlySnapshot()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.Snapshot);
    }

    function isAnyScript()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptGroup);
    }

    function isOnlyDryRun()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptDryRun);
    }

    function isOnlyBroadcast()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast);
    }

    function isOnlyResume()
    public view returns(bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptResume);
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