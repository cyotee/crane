//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@crane/contracts/external/openzeppelin-contracts/utils/Pausable.sol";
import "@crane/contracts/external/openzeppelin-contracts/access/Ownable.sol";
import "@crane/contracts/external/openzeppelin-contracts/access/AccessControl.sol";

contract DummyToken is ERC20Permit, ERC20Burnable, Ownable {
    constructor() 
      Ownable()
      ERC20("DummyToken", "DUM") 
      ERC20Permit("DummyToken") {
    }

    function mint(address to, uint256 amount) external onlyOwner {
      _mint(to, amount);
    }
}
