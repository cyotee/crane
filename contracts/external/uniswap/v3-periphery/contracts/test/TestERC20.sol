// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;

import '@crane/contracts/external/openzeppelin-contracts-v4/token/ERC20/extensions/draft-ERC20Permit.sol';

contract TestERC20 is ERC20Permit {
    constructor(uint256 amountToMint) ERC20('Test ERC20', 'TEST') ERC20Permit('Test ERC20') {
        _mint(msg.sender, amountToMint);
    }
}
