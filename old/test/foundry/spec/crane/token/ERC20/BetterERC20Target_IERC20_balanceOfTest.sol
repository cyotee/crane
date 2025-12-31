// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20TargetTest.sol";

/**
 * @title BetterERC20Target_IERC20_balanceOfTest
 * @dev Test suite for the balanceOf function of BetterERC20Target
 */
contract BetterERC20Target_IERC20_balanceOfTest is BetterERC20TargetTest {
    function test_IERC20_balanceOf_BetterERC20Target() public view {
        // Initial balance of addresses should be zero when no supply is minted
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(1)), 0);
        assertEq(token.balanceOf(RECIPIENT), INITIAL_SUPPLY);
    }
}
