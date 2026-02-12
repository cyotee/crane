// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {ERC20} from "@crane/contracts/tokens/ERC20/ERC20.sol";

/// @notice Crane-local port of Balancer's ERC20TestToken for testing purposes.
/// @dev This enables Crane to test without importing from upstream Balancer test contracts.
contract ERC20TestToken is ERC20 {
    uint8 private immutable _decimals;

    /// @dev Simulate tokens that don't allow zero transfers.
    error ZeroTransfer();

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external {
        _burn(sender, amount);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (value == 0) {
            revert ZeroTransfer();
        }

        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (value == 0) {
            revert ZeroTransfer();
        }

        return super.transferFrom(from, to, value);
    }
}
