// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {MockERC20} from '@crane/contracts/test/mocks/MockERC20.sol';

contract TestERC20 is MockERC20 {
  constructor(string memory name, string memory symbol, uint8 decimals) MockERC20(name, symbol, decimals) {
  }
}
