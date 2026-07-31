// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@crane/contracts/external/openzeppelin-contracts-v5/access/Ownable.sol";

/// @notice ERC20 token with owner-only mint, and a burn function
contract OwnedERC20 is ERC20Burnable, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_
    ) ERC20(name_, symbol_) Ownable(initialOwner_) {}

    /// @notice Mint tokens to the specified address
    /// @dev    Only the owner can mint tokens
    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }
}
