// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_assetTest
 * @dev Test suite for the asset function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_assetTest is BetterERC4626TargetTest {
    function test_IERC4626_asset_BetterERC4626Target() public view {
        assertEq(vault.asset(), address(underlying));
    }
}
