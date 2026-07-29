// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;

import '@crane/contracts/external/openzeppelin-contracts-v4/token/ERC20/extensions/draft-ERC20Permit.sol';

contract TestERC20Metadata is ERC20Permit {
    constructor(
        uint256 amountToMint,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, amountToMint);
    }
}
