// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_redeemTest
 * @dev Test suite for the redeem function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_redeemTest is BetterERC4626TargetTest {
    // Setup deposits for testing redemptions
    function setUp() public override {
        super.setUp();

        // Deposit some initial assets to test redemptions
        uint256 depositAmount = 500 * 10 ** UNDERLYING_DECIMALS;

        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();
    }

    function test_IERC4626_redeem_BetterERC4626Target() public {
        uint256 redeemAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        uint256 initialAssets = vault.totalAssets();
        uint256 initialShares = vault.balanceOf(DEPOSITOR);

        // Redeem shares
        vm.prank(DEPOSITOR);
        vault.redeem(redeemAmount, DEPOSITOR, DEPOSITOR);

        // Check post-redeem state
        assertEq(vault.totalAssets(), initialAssets - redeemAmount);
        assertEq(vault.balanceOf(DEPOSITOR), initialShares - redeemAmount);
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY - initialAssets + redeemAmount);
    }

    function test_IERC4626_redeem_differentReceiver_BetterERC4626Target() public {
        uint256 redeemAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address receiver = address(2);

        uint256 initialReceiverBalance = underlying.balanceOf(receiver);

        // Redeem shares to a different receiver
        vm.prank(DEPOSITOR);
        vault.redeem(redeemAmount, receiver, DEPOSITOR);

        // Check that assets were transferred to the receiver
        assertEq(underlying.balanceOf(receiver), initialReceiverBalance + redeemAmount);
    }

    function test_IERC4626_redeem_withApproval_BetterERC4626Target() public {
        uint256 redeemAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address owner = DEPOSITOR;
        address spender = address(4);

        // Approve spender
        vm.prank(owner);
        vault.approve(spender, redeemAmount);

        // Spender redeems on behalf of owner
        vm.prank(spender);
        vault.redeem(redeemAmount, spender, owner);

        // Check that shares were burned from owner and assets sent to spender
        assertEq(vault.balanceOf(owner), 500 * 10 ** UNDERLYING_DECIMALS - redeemAmount);
        assertEq(underlying.balanceOf(spender), redeemAmount);
    }

    function test_IERC4626_redeem_InsufficientShares_BetterERC4626Target() public {
        uint256 excessAmount = vault.balanceOf(DEPOSITOR) + 1;

        // Try to redeem more shares than owned
        vm.prank(DEPOSITOR);
        vm.expectRevert();
        vault.redeem(excessAmount, DEPOSITOR, DEPOSITOR);
    }

    function test_IERC4626_redeem_ZeroAmount_BetterERC4626Target() public {
        // Should be able to redeem zero shares
        vm.prank(DEPOSITOR);
        vault.redeem(0, DEPOSITOR, DEPOSITOR);

        // Balances should be unchanged
        assertEq(vault.balanceOf(DEPOSITOR), 500 * 10 ** UNDERLYING_DECIMALS);
    }
}
