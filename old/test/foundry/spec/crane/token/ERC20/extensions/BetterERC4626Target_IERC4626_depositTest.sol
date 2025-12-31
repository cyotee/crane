// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_depositTest
 * @dev Test suite for the deposit function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_depositTest is BetterERC4626TargetTest {
    function test_IERC4626_deposit_BetterERC4626Target() public {
        uint256 depositAmount = 100 * 10 ** UNDERLYING_DECIMALS;

        // Pre-deposit state
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.balanceOf(DEPOSITOR), 0);

        // Approve and deposit tokens
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();

        // Post-deposit state
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.totalSupply(), depositAmount);
        assertEq(vault.balanceOf(DEPOSITOR), depositAmount);
        assertEq(underlying.balanceOf(address(vault)), depositAmount);
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY - depositAmount);
    }

    function test_IERC4626_deposit_differentReceiver_BetterERC4626Target() public {
        uint256 depositAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address receiver = address(2);

        // Approve and deposit tokens
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Check that tokens were correctly deposited and shares minted to receiver
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.totalSupply(), depositAmount);
        assertEq(vault.balanceOf(receiver), depositAmount);
        assertEq(vault.balanceOf(DEPOSITOR), 0);
    }

    function test_IERC4626_deposit_ZeroAmount_BetterERC4626Target() public {
        // Should be able to deposit zero assets
        vm.prank(DEPOSITOR);
        vault.deposit(0, DEPOSITOR);

        // Balances should be unchanged
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.balanceOf(DEPOSITOR), 0);
    }
}
