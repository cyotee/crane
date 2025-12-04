// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
// import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
// import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
// import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";

abstract contract TestBase_Weth9 is Test {

    IWETH weth;

    function setUp() public virtual {
        if (address(weth) == address(0)) {
            weth = new WETH9();
        }
    }
}