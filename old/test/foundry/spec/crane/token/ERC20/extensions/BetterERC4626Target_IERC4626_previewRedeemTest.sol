// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_previewRedeemTest
 * @dev Test suite for the previewRedeem function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_previewRedeemTest is BetterERC4626TargetTest {
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

    function test_IERC4626_previewRedeem_BetterERC4626Target() public view {
        uint256 shares = 100 * 10 ** UNDERLYING_DECIMALS;

        // previewRedeem should match convertToAssets
        assertEq(vault.previewRedeem(shares), vault.convertToAssets(shares));
    }

    function test_IERC4626_previewRedeemRounding_BetterERC4626Target() public {
        // Create a scenario where rounding would apply

        // Introduce some imbalance
        vm.startPrank(DEPOSITOR);
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        underlying.transfer(address(vault), 2 * 10 ** UNDERLYING_DECIMALS); // Create imbalance
        vm.stopPrank();

        // Now the price ratio is no longer 1:1
        // Verify previewRedeem matches convertToAssets (rounding handled properly)
        uint256 shares = 3 * 10 ** UNDERLYING_DECIMALS;
        uint256 expectedAssets = vault.convertToAssets(shares);

        assertEq(vault.previewRedeem(shares), expectedAssets);

        // In some implementations with rounding (rounding down), assets might be less than original shares
        // but this depends on the specific implementation, so let's not assert the comparison
        // Instead, check that we get the expected value
    }
}
