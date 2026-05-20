// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ERC20MinterMock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
