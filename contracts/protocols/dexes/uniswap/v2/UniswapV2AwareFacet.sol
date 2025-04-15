// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { IFacet } from "../../../../interfaces/IFacet.sol";
import { IUniswapV2Aware } from "../../../../interfaces/IUniswapV2Aware.sol";
import { IUniswapV2Factory } from "../../../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import { IUniswapV2Router } from "../../../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import { UniswapV2AwareStorage } from "./utils/UniswapV2AwareStorage.sol";
import { Create3AwareContract } from "../../../../factories/create2/aware/Create3AwareContract.sol";

/**
 * @title UniswapV2AwareFacet
 * @dev Facet implementation of IUniswapV2Aware interface for Diamond proxies
 * @dev Provides access to UniswapV2 factory and router instances
 */
contract UniswapV2AwareFacet is UniswapV2AwareStorage, Create3AwareContract, IUniswapV2Aware, IFacet {

    constructor(CREATE3InitData memory initData_)
    Create3AwareContract(initData_) {}

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUniswapV2Aware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IUniswapV2Aware.uniV2Factory.selector;
        funcs[1] = IUniswapV2Aware.uniV2Router.selector;
    }

    /* ---------------------------------------------------------------------- */
    /*                            IUniswapV2Aware                             */
    /* ---------------------------------------------------------------------- */

    function uniV2Factory() external view returns (IUniswapV2Factory) {
        return _uniV2Factory();
    }

    function uniV2Router() external view returns (IUniswapV2Router) {
        return _uniV2Router();
    }
} 