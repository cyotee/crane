// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_previewWithdrawTest
 * @dev Test suite for the previewWithdraw function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_previewWithdrawTest is BetterERC4626TargetTest {
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

    function test_IERC4626_previewWithdraw_BetterERC4626Target() public view {
        uint256 assets = 100 * 10 ** UNDERLYING_DECIMALS;

        // previewWithdraw should be consistent with actual withdraw behavior
        // Calling withdraw with the result of previewWithdraw should burn exactly the predicted shares
        assertEq(vault.previewWithdraw(assets), vault.convertToShares(assets));
    }
}
