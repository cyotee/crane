// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_totalAssetsTest
 * @dev Test suite for the totalAssets function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_totalAssetsTest is BetterERC4626TargetTest {
    function test_IERC4626_totalAssets_BetterERC4626Target() public view {
        // Initially the vault should have 0 assets
        assertEq(vault.totalAssets(), 0);
    }

    function test_IERC4626_totalAssets_afterDeposit_BetterERC4626Target() public {
        uint256 depositAmount = 100 * 10 ** UNDERLYING_DECIMALS;

        // Approve and deposit tokens
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, DEPOSITOR);
        vm.stopPrank();

        // Check that totalAssets equals the deposit amount
        assertEq(vault.totalAssets(), depositAmount);
    }
}
