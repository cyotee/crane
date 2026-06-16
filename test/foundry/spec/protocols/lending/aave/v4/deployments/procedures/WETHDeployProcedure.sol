// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";

contract WETHDeployProcedure {
    function _deployWETH() internal returns (address) {
        return address(new WETH9());
    }
}
