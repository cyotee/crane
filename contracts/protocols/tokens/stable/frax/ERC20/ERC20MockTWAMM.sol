// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ERC20MockTWAMM is ERC20 {
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }
}