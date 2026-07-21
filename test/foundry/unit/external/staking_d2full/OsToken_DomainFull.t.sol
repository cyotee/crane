// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {OsToken} from "@crane/contracts/external/stakewise/tokens/OsToken.sol";

/// @notice Domain test against FULL vendored StakeWise OsToken (D2-FULL).
contract OsToken_DomainFullTest is Test {
    OsToken internal osToken;
    address internal owner = address(this);
    address internal controller = address(0xC0);
    address internal user = address(0xBEEF);

    function setUp() public {
        osToken = new OsToken(owner, controller, "Staked ETH", "osETH");
    }

    function test_Domain_MintBurn_ByController() public {
        vm.prank(controller);
        osToken.mint(user, 1 ether);
        assertEq(osToken.balanceOf(user), 1 ether);
        vm.prank(controller);
        osToken.burn(user, 0.4 ether);
        assertEq(osToken.balanceOf(user), 0.6 ether);
    }

    function test_Domain_ControllerRejectsStranger() public {
        vm.expectRevert();
        osToken.mint(user, 1);
    }
}
