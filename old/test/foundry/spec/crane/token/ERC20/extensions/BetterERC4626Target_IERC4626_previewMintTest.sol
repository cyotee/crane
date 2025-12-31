// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_previewMintTest
 * @dev Test suite for the previewMint function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_previewMintTest is BetterERC4626TargetTest {
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

    function test_IERC4626_previewMint_BetterERC4626Target() public view {
        uint256 shares = 100 * 10 ** UNDERLYING_DECIMALS;

        // previewMint should be consistent with actual mint behavior
        // Calling mint with the result of previewMint should give exactly the requested shares
        assertEq(vault.previewMint(shares), vault.convertToAssets(shares));
    }
}
