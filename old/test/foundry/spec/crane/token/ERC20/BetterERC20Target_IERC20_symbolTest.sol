// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20TargetTest.sol";

/**
 * @title BetterERC20Target_IERC20_symbolTest
 * @dev Test suite for the symbol function of BetterERC20Target
 */
contract BetterERC20Target_IERC20_symbolTest is BetterERC20TargetTest {
    function test_IERC20Metadata_symbol_BetterERC20Target() public view {
        assertEq(token.symbol(), SYMBOL);
    }
}
