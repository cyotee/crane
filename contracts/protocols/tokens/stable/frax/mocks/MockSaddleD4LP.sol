// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

/// @notice Minimal Saddle D4 LP stub for CommunalFarm tests
contract MockSaddleD4LP is ERC20 {
    constructor() ERC20("Mock Saddle D4", "sD4") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}