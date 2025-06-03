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

import "../../../../constants/FoundryConstants.sol";

contract DevWallets is CommonBase {

    VmSafe.Wallet internal _dev0Wallet;

    function dev0Wallet()
    public returns(VmSafe.Wallet memory) {
        if(_dev0Wallet.addr == address(0)) {
            _dev0Wallet = vm.createWallet(WALLET_0_KEY);
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
            _dev1Wallet = vm.createWallet(WALLET_1_KEY);
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
            _dev2Wallet = vm.createWallet(WALLET_2_KEY);
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
            _dev3Wallet = vm.createWallet(WALLET_3_KEY);
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
            _dev4Wallet = vm.createWallet(WALLET_4_KEY);
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
            _dev5Wallet = vm.createWallet(WALLET_5_KEY);
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
            _dev6Wallet = vm.createWallet(WALLET_6_KEY);
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
            _dev7Wallet = vm.createWallet(WALLET_7_KEY);
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
            _dev8Wallet = vm.createWallet(WALLET_8_KEY);
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
            _dev9Wallet = vm.createWallet(WALLET_9_KEY);
            vm.rememberKey(_dev9Wallet.privateKey);
        }
        return _dev9Wallet;
    }

    function dev9()
    public returns(address) {
        return dev9Wallet().addr;
    }

}