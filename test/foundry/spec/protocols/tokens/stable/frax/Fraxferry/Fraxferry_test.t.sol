// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Fraxferry/Fraxferry-test.js` (core embark/depart/disembark).

import {Test} from "forge-std/Test.sol";
import {Fraxferry} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/Fraxferry.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";
contract Fraxferry_test is Test {
    uint256 internal constant REDUCED_DECIMALS = 1e10;

    address internal owner;
    address internal user;
    address internal captain;
    address internal firstOfficer;
    address internal crewmember;

    DummyToken internal token0;
    DummyToken internal token1;
    Fraxferry internal ferryAB;
    Fraxferry internal ferryBA;

    function setUp() public {
        owner = address(this);
        user = makeAddr("ferryUser");
        captain = makeAddr("captain");
        firstOfficer = makeAddr("firstOfficer");
        crewmember = makeAddr("crewmember");

        token0 = new DummyToken();
        token1 = new DummyToken();

        token0.mint(owner, 1e30);
        token1.mint(owner, 1e30);
        token0.mint(user, 1e30);
        token1.mint(user, 1e30);

        ferryAB = new Fraxferry(address(token0), 0, address(token1), 1);
        ferryBA = new Fraxferry(address(token1), 1, address(token0), 0);

        token0.mint(address(ferryAB), 1e30);
        token1.mint(address(ferryBA), 1e30);

        ferryAB.setCaptain(captain);
        ferryAB.setFirstOfficer(firstOfficer);
        ferryAB.setCrewmember(crewmember, true);

        ferryBA.setCaptain(captain);
        ferryBA.setFirstOfficer(firstOfficer);
        ferryBA.setCrewmember(crewmember, true);
    }

    function test_setupContracts() public view {
        assertTrue(address(ferryAB) != address(0));
        assertTrue(address(ferryBA) != address(0));
    }

    function test_embark() public {
        uint256 bridgeAmount = 1000e18;
        uint256 userBefore = token0.balanceOf(user);
        uint256 ferryBefore = token0.balanceOf(address(ferryAB));

        vm.startPrank(user);
        token0.approve(address(ferryAB), bridgeAmount);
        ferryAB.embark(bridgeAmount);
        vm.stopPrank();

        assertEq(token0.balanceOf(user), userBefore - bridgeAmount);
        assertEq(token0.balanceOf(address(ferryAB)), ferryBefore + bridgeAmount);
        assertEq(ferryAB.noTransactions(), 1);

        uint256 fee = _fee(bridgeAmount);
        (address txUser, uint64 amount, uint32 timestamp) = _transaction(ferryAB, 0);
        assertEq(txUser, user);
        assertEq(uint256(amount) * REDUCED_DECIMALS, bridgeAmount - fee);
        assertEq(timestamp, uint32(block.timestamp));
    }

    function test_embark_checks() public {
        uint256 bridgeAmount = 1000e18;

        vm.startPrank(user);
        vm.expectRevert();
        ferryAB.embark(bridgeAmount);

        token0.approve(address(ferryAB), bridgeAmount);
        vm.expectRevert("Amount too low");
        ferryAB.embark(1000);

        vm.expectRevert("Amount too high");
        ferryAB.embark(1e39);
        vm.stopPrank();
    }

    function test_depart() public {
        bytes32 hash = bytes32(uint256(1));

        vm.prank(captain);
        ferryBA.depart(0, 0, hash);

        assertEq(ferryBA.noBatches(), 1);
        (uint64 start, uint64 end, uint64 departureTime, uint64 status, bytes32 batchHash) = ferryBA.batches(0);
        assertEq(start, 0);
        assertEq(end, 0);
        assertEq(departureTime, uint64(block.timestamp));
        assertEq(status, 0);
        assertEq(batchHash, hash);
    }

    function test_depart_checks() public {
        bytes32 hash = bytes32(uint256(1));

        vm.prank(captain);
        vm.expectRevert("Wrong start");
        ferryBA.depart(1, 2, hash);

        vm.expectRevert("Not captain");
        ferryBA.depart(0, 0, hash);

        vm.prank(captain);
        ferryBA.depart(0, 0, hash);

        vm.prank(captain);
        vm.expectRevert("Wrong start");
        ferryBA.depart(0, 0, hash);
    }

    function test_disembark() public {
        uint256 bridgeAmount = 1000e18;

        vm.startPrank(user);
        token0.approve(address(ferryAB), bridgeAmount);
        ferryAB.embark(bridgeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 3601);
        bytes32 hash = ferryAB.getTransactionsHash(0, 0);
        Fraxferry.BatchData memory batch = ferryAB.getBatchData(0, 0);

        vm.prank(captain);
        ferryBA.depart(0, 0, hash);

        vm.warp(block.timestamp + 79201);

        uint256 fee = _fee(bridgeAmount);
        uint256 userBefore = token1.balanceOf(user);
        uint256 ferryBefore = token1.balanceOf(address(ferryBA));

        vm.prank(firstOfficer);
        ferryBA.disembark(batch);

        assertEq(ferryBA.executeIndex(), 1);
        assertEq(token1.balanceOf(user), userBefore + bridgeAmount - fee);
        assertEq(token1.balanceOf(address(ferryBA)), ferryBefore - (bridgeAmount - fee));
    }

    function _fee(uint256 amount) internal view returns (uint256) {
        uint256 fee = amount * ferryAB.FEE_RATE() / 10_000;
        if (fee < ferryAB.FEE_MIN()) fee = ferryAB.FEE_MIN();
        if (fee > ferryAB.FEE_MAX()) fee = ferryAB.FEE_MAX();
        return fee;
    }

    function _transaction(Fraxferry ferry, uint256 index)
        internal
        view
        returns (address txUser, uint64 amount, uint32 timestamp)
    {
        Fraxferry.BatchData memory data = ferry.getBatchData(index, index);
        Fraxferry.Transaction memory t = data.transactions[0];
        return (t.user, t.amount, t.timestamp);
    }
}