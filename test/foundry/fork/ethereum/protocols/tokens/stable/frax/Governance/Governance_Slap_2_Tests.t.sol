// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Governance_Slap_2.js` (timelock admin handoff to comptroller).

import {Test} from "forge-std/Test.sol";
import {Timelock} from "@crane/contracts/protocols/tokens/stable/frax/Governance/Timelock.sol";
import {TestBase_FraxEthereumFork, FraxEthereumAddresses} from "../TestBase_FraxEthereumFork.sol";

contract Governance_Slap_2_Tests is Test, TestBase_FraxEthereumFork {
    Timelock internal timelock;

    address internal constant TIMELOCK_ADMIN = 0x510B35338c8e3b53F12aa109C38995Acd9127aE0;

    function setUp() public {
        _forkEthereum();
        timelock = Timelock(FraxEthereumAddresses.TIMELOCK);
    }

    function test_timelockAdminHandoffToComptroller() public {
        address adminBefore = timelock.admin();
        address pendingBefore = timelock.pendingAdmin();

        if (adminBefore == FraxEthereumAddresses.COMPTROLLER) {
            assertEq(pendingBefore, address(0));
            return;
        }

        assertEq(adminBefore, TIMELOCK_ADMIN);

        uint256 eta = block.timestamp + timelock.delay() + 300;
        bytes memory data = abi.encode(FraxEthereumAddresses.COMPTROLLER);

        vm.prank(TIMELOCK_ADMIN);
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", data, eta);

        vm.warp(eta + 1);

        vm.prank(TIMELOCK_ADMIN);
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", data, eta);

        assertEq(timelock.pendingAdmin(), FraxEthereumAddresses.COMPTROLLER);

        vm.prank(FraxEthereumAddresses.COMPTROLLER);
        timelock.acceptAdmin();

        assertEq(timelock.admin(), FraxEthereumAddresses.COMPTROLLER);
        assertEq(timelock.pendingAdmin(), address(0));
    }
}
