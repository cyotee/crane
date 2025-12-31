// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_maxRedeemTest
 * @dev Test suite for the maxRedeem function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_maxRedeemTest is BetterERC4626TargetTest {
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

    function test_IERC4626_maxRedeem_BetterERC4626Target() public view {
        // maxRedeem should equal balanceOf(owner)
        address owner = DEPOSITOR;

        assertEq(vault.maxRedeem(owner), vault.balanceOf(owner));

        // For address with no shares, maxRedeem should be 0
        address noShares = address(123);
        assertEq(vault.maxRedeem(noShares), 0);
    }
}
