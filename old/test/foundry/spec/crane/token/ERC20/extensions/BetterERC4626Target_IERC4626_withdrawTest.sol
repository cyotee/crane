// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_withdrawTest
 * @dev Test suite for the withdraw function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_withdrawTest is BetterERC4626TargetTest {
    // Setup deposits for testing withdrawals
    function setUp() public override {
        super.setUp();

        // Deposit some initial assets to test withdrawals
        uint256 depositAmount = 500 * 10 ** UNDERLYING_DECIMALS;

        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();
    }

    // Withdraw function tests
    function test_IERC4626_withdraw_BetterERC4626Target() public {
        uint256 withdrawAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        uint256 initialShares = vault.balanceOf(DEPOSITOR);
        uint256 initialAssets = vault.totalAssets();

        // Withdraw assets
        vm.prank(DEPOSITOR);
        vault.withdraw(withdrawAmount, DEPOSITOR, DEPOSITOR);

        // Check post-withdraw state
        assertEq(vault.totalAssets(), initialAssets - withdrawAmount);
        assertEq(vault.balanceOf(DEPOSITOR), initialShares - withdrawAmount);
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY - initialAssets + withdrawAmount);
    }

    function test_IERC4626_withdraw_differentReceiver_BetterERC4626Target() public {
        uint256 withdrawAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address receiver = address(2);

        uint256 initialReceiverBalance = underlying.balanceOf(receiver);

        // Withdraw assets to a different receiver
        vm.prank(DEPOSITOR);
        vault.withdraw(withdrawAmount, receiver, DEPOSITOR);

        // Check that assets were transferred to the receiver
        assertEq(underlying.balanceOf(receiver), initialReceiverBalance + withdrawAmount);
    }

    function test_IERC4626_withdraw_fromCaller_BetterERC4626Target() public {
        uint256 withdrawAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address caller = address(3);

        // First, transfer some shares to the caller
        vm.prank(DEPOSITOR);
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        vault.transfer(caller, withdrawAmount);

        // Caller withdraws on their own behalf
        vm.prank(caller);
        vault.withdraw(withdrawAmount, caller, caller);

        // Check that assets were transferred correctly
        assertEq(vault.balanceOf(caller), 0);
        assertEq(underlying.balanceOf(caller), withdrawAmount);
    }

    function test_IERC4626_withdraw_InsufficientAssets_BetterERC4626Target() public {
        uint256 excessAmount = vault.totalAssets() + 1;

        // Try to withdraw more than available assets
        vm.prank(DEPOSITOR);
        vm.expectRevert();
        vault.withdraw(excessAmount, DEPOSITOR, DEPOSITOR);
    }

    function test_IERC4626_withdraw_ZeroAmount_BetterERC4626Target() public {
        // Should be able to withdraw zero assets
        vm.prank(DEPOSITOR);
        vault.withdraw(0, DEPOSITOR, DEPOSITOR);

        // Balances should be unchanged
        assertEq(vault.balanceOf(DEPOSITOR), 500 * 10 ** UNDERLYING_DECIMALS);
    }
}
