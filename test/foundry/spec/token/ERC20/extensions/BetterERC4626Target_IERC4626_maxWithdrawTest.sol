// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_maxWithdrawTest
 * @dev Test suite for the maxWithdraw function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_maxWithdrawTest is BetterERC4626TargetTest {
    // Setup some deposits for testing
    function setUp() public override {
        super.setUp();
        
        // Deposit some initial assets
        uint256 depositAmount = 500 * 10**UNDERLYING_DECIMALS;
        
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();
    }
    
    function test_IERC4626_maxWithdraw() public view {
        // maxWithdraw should equal convertToAssets(balanceOf(owner))
        address owner = DEPOSITOR;
        uint256 expected = vault.convertToAssets(vault.balanceOf(owner));
        
        assertEq(vault.maxWithdraw(owner), expected);
        
        // For address with no shares, maxWithdraw should be 0
        address noShares = address(123);
        assertEq(vault.maxWithdraw(noShares), 0);
    }
} 