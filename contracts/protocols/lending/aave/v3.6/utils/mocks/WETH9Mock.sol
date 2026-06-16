// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {Ownable} from "@crane/contracts/external/openzeppelin-contracts/access/Ownable.sol";

contract WETH9Mock is WETH9, Ownable {
    constructor(string memory mockName, string memory mockSymbol, address owner) Ownable(owner) {
        name = mockName;
        symbol = mockSymbol;
    }

    function mint(address account, uint256 value) public onlyOwner returns (bool) {
        balanceOf[account] += value;
        emit Transfer(address(0), account, value);
        return true;
    }
}
