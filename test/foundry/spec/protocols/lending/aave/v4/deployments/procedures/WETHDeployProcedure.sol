// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH9} from '@crane/contracts/protocols/lending/aave/v4/dependencies/weth/WETH9.sol';

contract WETHDeployProcedure {
  function _deployWETH() internal returns (address) {
    return address(new WETH9());
  }
}
