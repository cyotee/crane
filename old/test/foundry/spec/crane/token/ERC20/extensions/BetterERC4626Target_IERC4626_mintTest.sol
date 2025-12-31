// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_mintTest
 * @dev Test suite for the mint function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_mintTest is BetterERC4626TargetTest {
    // Mint function tests
    function test_IERC4626_mint_BetterERC4626Target() public {
        uint256 mintAmount = 100 * 10 ** UNDERLYING_DECIMALS;

        // Pre-mint state
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.balanceOf(DEPOSITOR), 0);

        // Approve and mint shares
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), mintAmount);
        vault.mint(mintAmount, DEPOSITOR);
        vm.stopPrank();

        // Post-mint state
        assertEq(vault.totalAssets(), mintAmount);
        assertEq(vault.totalSupply(), mintAmount);
        assertEq(vault.balanceOf(DEPOSITOR), mintAmount);
        assertEq(underlying.balanceOf(address(vault)), mintAmount);
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY - mintAmount);
    }

    function test_IERC4626_mint_differentReceiver_BetterERC4626Target() public {
        uint256 mintAmount = 100 * 10 ** UNDERLYING_DECIMALS;
        address receiver = address(2);

        // Approve and mint shares
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), mintAmount);
        vault.mint(mintAmount, receiver);
        vm.stopPrank();

        // Check that shares were correctly minted to receiver
        assertEq(vault.totalSupply(), mintAmount);
        assertEq(vault.balanceOf(receiver), mintAmount);
        assertEq(vault.balanceOf(DEPOSITOR), 0);
    }

    function test_IERC4626_mint_ZeroAmount_BetterERC4626Target() public {
        // Should be able to mint zero shares
        vm.prank(DEPOSITOR);
        vault.mint(0, DEPOSITOR);

        // Balances should be unchanged
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.balanceOf(DEPOSITOR), 0);
    }
}
