// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {ERC20} from "@crane/contracts/tokens/ERC20/ERC20.sol";

/// @notice Crane-local port of Balancer's WETHTestToken for testing purposes.
/// @dev This enables Crane to test without importing from upstream Balancer test contracts.
///      Implements IWETH interface methods without explicit inheritance to avoid diamond conflicts.
contract WETHTestToken is ERC20 {
    // Events taken from actual WETH implementation in mainnet
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() ERC20("Wrapped Ether", "WETH") {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}
