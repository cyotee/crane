// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_convertToSharesTest
 * @dev Test suite for the convertToShares function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_convertToSharesTest is BetterERC4626TargetTest {
    function test_IERC4626_convertToShares_BetterERC4626Target() public view {
        // With no assets in the vault, 1:1 conversion (1e18 assets = 1e18 shares)
        uint256 assets = 1e18;
        uint256 expectedShares = assets;

        assertEq(vault.convertToShares(assets), expectedShares);
    }

    function test_IERC4626_convertToShares_withExistingAssets_BetterERC4626Target() public {
        uint256 initialDeposit = 10 * 10 ** UNDERLYING_DECIMALS;

        // First deposit to establish a non-1:1 ratio
        vm.startPrank(DEPOSITOR);
        underlying.approve(address(vault), initialDeposit);
        vault.deposit(initialDeposit, DEPOSITOR);

        // Simulate yield by transferring more tokens to vault directly
        uint256 yield = 5 * 10 ** UNDERLYING_DECIMALS;
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        underlying.transfer(address(vault), yield);
        vm.stopPrank();

        // Now we have:
        // 10 shares outstanding
        // 15 total assets (10 initial + 5 yield)
        // So 1 asset = 10/15 = 2/3 shares

        uint256 additionalAssets = 3 * 10 ** UNDERLYING_DECIMALS;
        uint256 expectedShares = (additionalAssets * vault.totalSupply()) / vault.totalAssets();

        assertEq(vault.convertToShares(additionalAssets), expectedShares);
    }
}
