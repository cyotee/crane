// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC4626TargetTest.sol";

/**
 * @title BetterERC4626Target_IERC4626_maxMintTest
 * @dev Test suite for the maxMint function of BetterERC4626Target
 */
contract BetterERC4626Target_IERC4626_maxMintTest is BetterERC4626TargetTest {
    function test_IERC4626_maxMint_BetterERC4626Target() public view {
        // maxMint should return max uint256 by default
        assertEq(vault.maxMint(address(0)), type(uint256).max);
        assertEq(vault.maxMint(DEPOSITOR), type(uint256).max);
    }
}
