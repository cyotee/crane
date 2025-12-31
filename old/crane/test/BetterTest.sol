// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {Test} from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {AddressSet} from 
// AddressSetRepo
"@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import "contracts/crane/constants/FoundryConstants.sol";
// import { BetterFuzzing } from "./fuzzing/BetterFuzzing.sol";
// import { Behavior_Crane } from "./behaviors/Behavior_Crane.sol";

contract BetterTest is
    CommonBase,
    ScriptBase,
    TestBase,
    StdAssertions,
    StdChains,
    StdCheatsSafe,
    StdCheats,
    StdInvariant,
    StdUtils,
    Script,
    BetterScript,
    Test
{
    // using AddressSetRepo for AddressSet;

    constructor() {
        // declareAddr(address(0));
        // declareAddr(address(VM_ADDRESS));
        // declareAddr(address(0x4e59b44847b379578588920cA78FbF26c0B4956C));
        // declareAddr(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
        // declareAddr(address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f));
        // declareAddr(address(0x000000000000000000636F6e736F6c652e6c6f67));
        // declareAddr(address(0x4200000000000000000000000000000000000000));
        // declareAddr(address(0x0000000000000000000000000000000000000064));
        // declareAddr(address(0x0100000000000000000000000000000000000000));
        // declareAddr(address(0x0200000000000000000000000000000000000000));
        // declareAddr(address(0x0300000000000000000000000000000000000000));
    }

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

    modifier onlyNotUsed(address addr) {
        assumeNotPrecompile(addr);
        assumeNotZeroAddress(addr);
        assumeNotForgeAddress(addr);
        vm.assume(!isUsed(addr));
        vm.assume(addr != address(this));
        vm.assume(addr != address(msg.sender));
        vm.assume(addr != address(tx.origin));
        vm.assume(addr != dev0());
        vm.assume(addr != dev1());
        vm.assume(addr != dev2());
        vm.assume(addr != dev3());
        vm.assume(addr != dev4());
        vm.assume(addr != dev5());
        vm.assume(addr != dev6());
        vm.assume(addr != dev7());
        vm.assume(addr != dev8());
        vm.assume(addr != dev9());
        _;
    }

    function isUsed(address addr) public view returns (bool) {
        return isDeclared(addr);
    }

    VmSafe.Wallet internal _dev0Wallet;

    function dev0Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev0Wallet.addr == address(0)) {
            _dev0Wallet = vm.createWallet(WALLET_0_KEY);
            vm.rememberKey(_dev0Wallet.privateKey);
        }
        return _dev0Wallet;
    }

    function dev0() public returns (address) {
        return dev0Wallet().addr;
    }

    VmSafe.Wallet internal _dev1Wallet;

    function dev1Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev1Wallet.addr == address(0)) {
            _dev1Wallet = vm.createWallet(WALLET_1_KEY);
            vm.rememberKey(_dev1Wallet.privateKey);
        }
        return _dev1Wallet;
    }

    function dev1() public returns (address) {
        return dev1Wallet().addr;
    }

    VmSafe.Wallet internal _dev2Wallet;

    function dev2Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev2Wallet.addr == address(0)) {
            _dev2Wallet = vm.createWallet(WALLET_2_KEY);
            vm.rememberKey(_dev2Wallet.privateKey);
        }
        return _dev2Wallet;
    }

    function dev2() public returns (address) {
        return dev2Wallet().addr;
    }

    VmSafe.Wallet internal _dev3Wallet;

    function dev3Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev3Wallet.addr == address(0)) {
            _dev3Wallet = vm.createWallet(WALLET_3_KEY);
            vm.rememberKey(_dev3Wallet.privateKey);
        }
        return _dev3Wallet;
    }

    function dev3() public returns (address) {
        return dev3Wallet().addr;
    }

    VmSafe.Wallet internal _dev4Wallet;

    function dev4Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev4Wallet.addr == address(0)) {
            _dev4Wallet = vm.createWallet(WALLET_4_KEY);
            vm.rememberKey(_dev4Wallet.privateKey);
        }
        return _dev4Wallet;
    }

    function dev4() public returns (address) {
        return dev4Wallet().addr;
    }

    VmSafe.Wallet internal _dev5Wallet;

    function dev5Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev5Wallet.addr == address(0)) {
            _dev5Wallet = vm.createWallet(WALLET_5_KEY);
            vm.rememberKey(_dev5Wallet.privateKey);
        }
        return _dev5Wallet;
    }

    function dev5() public returns (address) {
        return dev5Wallet().addr;
    }

    VmSafe.Wallet internal _dev6Wallet;

    function dev6Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev6Wallet.addr == address(0)) {
            _dev6Wallet = vm.createWallet(WALLET_6_KEY);
            vm.rememberKey(_dev6Wallet.privateKey);
        }
        return _dev6Wallet;
    }

    function dev6() public returns (address) {
        return dev6Wallet().addr;
    }

    VmSafe.Wallet internal _dev7Wallet;

    function dev7Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev7Wallet.addr == address(0)) {
            _dev7Wallet = vm.createWallet(WALLET_7_KEY);
            vm.rememberKey(_dev7Wallet.privateKey);
        }
        return _dev7Wallet;
    }

    function dev7() public returns (address) {
        return dev7Wallet().addr;
    }

    VmSafe.Wallet internal _dev8Wallet;

    function dev8Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev8Wallet.addr == address(0)) {
            _dev8Wallet = vm.createWallet(WALLET_8_KEY);
            vm.rememberKey(_dev8Wallet.privateKey);
        }
        return _dev8Wallet;
    }

    function dev8() public returns (address) {
        return dev8Wallet().addr;
    }

    VmSafe.Wallet internal _dev9Wallet;

    function dev9Wallet() public returns (VmSafe.Wallet memory) {
        if (_dev9Wallet.addr == address(0)) {
            _dev9Wallet = vm.createWallet(WALLET_9_KEY);
            vm.rememberKey(_dev9Wallet.privateKey);
        }
        return _dev9Wallet;
    }

    function dev9() public returns (address) {
        return dev9Wallet().addr;
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
