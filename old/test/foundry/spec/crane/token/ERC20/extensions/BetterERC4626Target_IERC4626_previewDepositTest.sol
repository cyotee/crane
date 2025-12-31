// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_previewDepositTest
 * @dev Test suite for the previewDeposit function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_previewDepositTest is BetterERC4626TargetTest {
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

    function test_IERC4626_previewDeposit_BetterERC4626Target() public view {
        uint256 assets = 100 * 10 ** UNDERLYING_DECIMALS;

        // previewDeposit should match convertToShares
        assertEq(vault.previewDeposit(assets), vault.convertToShares(assets));
    }

    function test_IERC4626_previewDepositRounding_BetterERC4626Target() public {
        // Create a scenario where rounding would apply

        // Introduce imbalance
        vm.startPrank(DEPOSITOR);
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        underlying.transfer(address(vault), 2 * 10 ** UNDERLYING_DECIMALS); // Create imbalance
        vm.stopPrank();

        // Now the price ratio is no longer 1:1
        // Verify previewDeposit rounds shares down (in favor of vault)
        uint256 assets = 3 * 10 ** UNDERLYING_DECIMALS;
        uint256 expectedShares = vault.convertToShares(assets);

        assertEq(vault.previewDeposit(assets), expectedShares);
        // Verify shares are at most assets (rounding down or equal)
        assert(expectedShares <= assets);
    }
}
