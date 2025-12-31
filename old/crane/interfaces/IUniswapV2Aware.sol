// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IUniswapV2Factory} from "./protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "./protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

interface IUniswapV2Aware {
    /**
     * @custom:selector 0x3da04b87
     */
    function uniV2Factory() external view returns (IUniswapV2Factory);

    /**
     * @custom:selector 0x958c2e52
     */
    function uniV2Router() external view returns (IUniswapV2Router);
}
