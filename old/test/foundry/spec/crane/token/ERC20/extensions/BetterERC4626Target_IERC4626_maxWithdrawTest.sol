// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
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
        uint256 depositAmount = 500 * 10 ** UNDERLYING_DECIMALS;

        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();
    }

    function test_IERC4626_maxWithdraw_BetterERC4626Target() public view {
        uint256 expected = type(uint256).max;

        assertEq(vault.maxWithdraw(DEPOSITOR), expected);

        // For address with no shares, maxWithdraw should still be max uint256
        address noShares = address(123);
        assertEq(vault.maxWithdraw(noShares), expected);
    }
}
