// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {OsToken} from "@crane/contracts/external/stakewise/tokens/OsToken.sol";
import {OsTokenVaultController} from "@crane/contracts/external/stakewise/tokens/OsTokenVaultController.sol";

/// @notice Proves vendored StakeWise OsToken domain compiles and mint/burn path works.
contract OsToken_DomainTest is Test {
    OsToken internal osToken;
    address internal owner = address(0xA11CE);
    address internal controller = address(0xC0);

    function setUp() public {
        // vaultController address is immutable controller of mint/burn
        osToken = new OsToken(owner, controller, "Staked ETH", "osETH");
    }

    function test_Domain_MintBurn_ByController() public {
        vm.prank(controller);
        osToken.mint(address(this), 1e18);
        assertEq(osToken.balanceOf(address(this)), 1e18);
        vm.prank(controller);
        osToken.burn(address(this), 0.4e18);
        assertEq(osToken.balanceOf(address(this)), 0.6e18);
    }

    function test_Domain_ControllerRejectsStranger() public {
        vm.expectRevert();
        osToken.mint(address(this), 1);
    }
}
