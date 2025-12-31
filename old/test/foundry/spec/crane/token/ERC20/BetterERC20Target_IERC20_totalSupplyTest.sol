// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "./BetterERC20TargetTest.sol";

/**
 * @title BetterERC20Target_IERC20_totalSupplyTest
 * @dev Test suite for the totalSupply function of BetterERC20Target
 */
contract BetterERC20Target_IERC20_totalSupplyTest is BetterERC20TargetTest {
    function test_IERC20_totalSupply_BetterERC20Target() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // Test with initial supply
    function test_IERC20_totalSupply_withInitialSupply_BetterERC20Target() public {
        uint256 supply = 1000 * 10 ** DECIMALS;
        address recipient = address(1);

        BetterERC20TargetStub tokenWithSupply = new BetterERC20TargetStub(NAME, SYMBOL, DECIMALS, supply, recipient);

        assertEq(tokenWithSupply.totalSupply(), supply);
    }
}
