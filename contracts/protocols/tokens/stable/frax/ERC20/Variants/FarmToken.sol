// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;
import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

// Mock Farm token
contract FarmToken is ERC20("FARM Reward Token", "FARM") {}
