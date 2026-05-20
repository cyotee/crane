// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/FraxferryV2/FerryV2-test.js`.
/// @dev L1⇄L2 proof paths (`eth_getProof`) run in fork integration; local suite covers L2⇒L1 captain disembark.

import {Test} from "forge-std/Test.sol";
import {FerryOnL1} from "@crane/contracts/protocols/tokens/stable/frax/FraxferryV2/FerryOnL1.sol";
import {FerryOnL2} from "@crane/contracts/protocols/tokens/stable/frax/FraxferryV2/FerryOnL2.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";
import {DummyStateRootOracle} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/DummyStateRootOracle.sol";

contract FerryV2_test is Test {
    address internal owner;
    address internal user1;

    DummyToken internal tokenL1;
    DummyToken internal tokenL2;
    DummyStateRootOracle internal dummyStateRootOracle;
    FerryOnL1 internal ferryOnL1;
    FerryOnL2 internal ferryOnL2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("ferryUser1");

        tokenL1 = new DummyToken();
        tokenL2 = new DummyToken();
        tokenL1.mint(owner, 1e30);
        tokenL2.mint(owner, 1e30);
        tokenL1.mint(user1, 1000e18);
        tokenL2.mint(user1, 1000e18);

        dummyStateRootOracle = new DummyStateRootOracle();
        ferryOnL1 = new FerryOnL1(address(tokenL1));
        ferryOnL2 = new FerryOnL2(address(tokenL2), address(ferryOnL1), dummyStateRootOracle);
    }

    function test_setupContracts() public view {
        assertTrue(address(ferryOnL1) != address(0));
        assertTrue(address(ferryOnL2) != address(0));
    }

    /// @dev Matches upstream `L2 -> L1` (captain disembarks on L1).
    function test_L2_to_L1() public {
        uint32 deadline = uint32(block.timestamp + 1 hours);

        vm.startPrank(user1);
        tokenL2.approve(address(ferryOnL2), 10e18);
        ferryOnL2.embarkWithRecipient(10e18, 0, user1, deadline);
        vm.stopPrank();

        tokenL1.approve(address(ferryOnL1), 10e18);
        uint256 userBalBefore = tokenL1.balanceOf(user1);
        ferryOnL1.disembark(10e18, user1, 0, owner, deadline);
        assertEq(tokenL1.balanceOf(user1) - userBalBefore, 10e18);
    }

    function test_L2_embark_increases_l2_balance() public {
        uint32 deadline = uint32(block.timestamp + 1 hours);
        uint256 ferryBefore = tokenL2.balanceOf(address(ferryOnL2));

        vm.startPrank(user1);
        tokenL2.approve(address(ferryOnL2), 10e18);
        ferryOnL2.embarkWithRecipient(10e18, 0, user1, deadline);
        vm.stopPrank();

        assertEq(tokenL2.balanceOf(address(ferryOnL2)), ferryBefore + 10e18);
    }
}