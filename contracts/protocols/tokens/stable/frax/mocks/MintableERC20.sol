// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

/// @notice Mintable ERC20 for Frax port Foundry tests
contract MintableERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
