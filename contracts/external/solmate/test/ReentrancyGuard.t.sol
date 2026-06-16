// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.35;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";

import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

contract RiskyContract is ReentrancyGuard {
    uint256 public enterTimes;

    function unprotectedCall() public {
        enterTimes++;

        if (enterTimes > 1) return;

        this.protectedCall();
    }

    function protectedCall() public nonReentrant {
        enterTimes++;

        if (enterTimes > 1) return;

        this.protectedCall();
    }

    function overprotectedCall() public nonReentrant {}
}

contract ReentrancyGuardTest is DSTestPlus {
    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    RiskyContract riskyContract;

    function setUp() public {
        riskyContract = new RiskyContract();
    }

    function invariantReentrancyStatusAlways1() public {
        assertEq(uint256(vm.load(address(riskyContract), 0)), 1);
    }

    function testUnprotectedCall() public {
        riskyContract.unprotectedCall();

        // Unprotected allows reentrancy (enterTimes incremented in both unprotected and the inner protected call).
        assertEq(riskyContract.enterTimes(), 2);
    }

    function testProtectedCall() public {
        vm.expectRevert("REENTRANCY");
        riskyContract.protectedCall();
    }

    function testNoReentrancy() public {
        riskyContract.overprotectedCall();
    }
}
