pragma solidity ^0.8.13;

import "@crane/contracts/external/openzeppelin-contracts-v4/token/ERC20/IERC20.sol";

interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint wad) external;
}