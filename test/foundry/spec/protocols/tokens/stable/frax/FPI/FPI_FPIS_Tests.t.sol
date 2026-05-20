// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/FPI-FPIS-Tests.js`
/// @dev Local deploy parity (upstream fixture uses mainnet `FPI.at` / `FPIS.at`).

import {Test} from "forge-std/Test.sol";
import {FPI} from "@crane/contracts/protocols/tokens/stable/frax/FPI/FPI.sol";
import {FPIS} from "@crane/contracts/protocols/tokens/stable/frax/FPI/FPIS.sol";
import {ERC20PermissionedMint} from "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20PermissionedMint.sol";

contract FPI_FPIS_Tests is Test {
    uint256 internal constant MINT_AMOUNT = 100e18;
    uint256 internal constant TRANSFER_AMOUNT = 5e18;
    uint256 internal constant BURN_AMOUNT = 1e18;

    address internal collateralOwner;
    address internal investor;
    address internal timelock;

    FPI internal fpi;
    FPIS internal fpis;

    function setUp() public {
        collateralOwner = makeAddr("collateralOwner");
        investor = makeAddr("investor");
        timelock = makeAddr("timelock");

        fpi = new FPI(collateralOwner, timelock);
        fpis = new FPIS(collateralOwner, timelock, address(fpi));
    }

    function test_Main_uniformAndPermissionFailures() public {
        // Uniform tests (from JS "Main test")
        vm.startPrank(collateralOwner);
        fpi.addMinter(collateralOwner);
        fpis.addMinter(collateralOwner);

        fpi.transfer(investor, TRANSFER_AMOUNT);
        fpis.transfer(investor, TRANSFER_AMOUNT);

        fpi.approve(investor, TRANSFER_AMOUNT);
        fpis.approve(investor, TRANSFER_AMOUNT);
        vm.stopPrank();

        vm.prank(investor);
        fpi.transferFrom(collateralOwner, investor, TRANSFER_AMOUNT);
        vm.prank(investor);
        fpis.transferFrom(collateralOwner, investor, TRANSFER_AMOUNT);

        vm.prank(collateralOwner);
        fpi.minter_mint(collateralOwner, MINT_AMOUNT);
        vm.prank(collateralOwner);
        fpis.minter_mint(collateralOwner, MINT_AMOUNT);

        vm.prank(collateralOwner);
        fpi.burn(BURN_AMOUNT);
        vm.prank(collateralOwner);
        fpis.burn(BURN_AMOUNT);

        vm.startPrank(collateralOwner);
        fpi.approve(collateralOwner, BURN_AMOUNT);
        fpis.approve(collateralOwner, BURN_AMOUNT);
        fpi.minter_burn_from(collateralOwner, BURN_AMOUNT);
        fpis.minter_burn_from(collateralOwner, BURN_AMOUNT);

        fpi.removeMinter(collateralOwner);
        fpis.removeMinter(collateralOwner);
        vm.stopPrank();

        // Permission fail tests
        vm.prank(investor);
        vm.expectRevert("Only minters");
        fpi.minter_mint(investor, MINT_AMOUNT);
        vm.prank(investor);
        vm.expectRevert("Only minters");
        fpis.minter_mint(investor, MINT_AMOUNT);

        vm.prank(investor);
        vm.expectRevert();
        fpi.transferFrom(collateralOwner, investor, TRANSFER_AMOUNT);
        vm.prank(investor);
        vm.expectRevert();
        fpis.transferFrom(collateralOwner, investor, TRANSFER_AMOUNT);

        vm.prank(investor);
        vm.expectRevert();
        fpi.burnFrom(investor, BURN_AMOUNT);
        vm.prank(investor);
        vm.expectRevert();
        fpis.burnFrom(investor, BURN_AMOUNT);
    }

    function test_FPIS_linksFpiToken() public view {
        assertEq(address(fpis.FPI_TKN()), address(fpi));
    }
}