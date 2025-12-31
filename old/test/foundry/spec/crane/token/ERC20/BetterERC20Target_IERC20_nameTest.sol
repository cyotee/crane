// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20TargetTest.sol";

/**
 * @title BetterERC20Target_IERC20_nameTest
 * @dev Test suite for the name function of BetterERC20Target
 */
contract BetterERC20Target_IERC20_nameTest is BetterERC20TargetTest {
    function test_IERC20Metadata_name_BetterERC20Target() public view {
        assertEq(token.name(), NAME);
    }
}
