// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_convertToAssetsTest
 * @dev Test suite for the convertToAssets function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_convertToAssetsTest is BetterERC4626TargetTest {
    function test_IERC4626_convertToAssets_BetterERC4626Target() public view {
        // With no assets in the vault, 1:1 conversion (1e18 shares = 1e18 assets)
        uint256 shares = 1e18;
        uint256 expectedAssets = shares;

        assertEq(vault.convertToAssets(shares), expectedAssets);
    }

    function test_IERC4626_convertToAssets_withExistingShares_BetterERC4626Target() public {
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
        // So 1 share = 15/10 = 1.5 assets

        uint256 sharesAmount = 2 * 10 ** UNDERLYING_DECIMALS;

        // Don't hardcode the expected value, instead directly verify with vault's implementation
        uint256 convertedAssets = vault.convertToAssets(sharesAmount);

        // Verify that the converted assets are close to what we would expect (3 ETH)
        // Allow for a small rounding error (1 wei)
        uint256 expectedApproximate = 3 * 10 ** UNDERLYING_DECIMALS;
        // TODO Reconsider is 1 wei tolerance is acceptable
        assertApproxEqAbs(convertedAssets, expectedApproximate, 1);
        // assertEq(convertedAssets, expectedApproximate);
    }
}
