// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IUniswapV2Aware} from "contracts/crane/interfaces/IUniswapV2Aware.sol";
import {IUniswapV2Factory} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {UniswapV2AwareRepo} from "old/crane/protocols/dexes/uniswap/v2/utils/UniswapV2AwareRepo.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";

/**
 * @title UniswapV2AwareFacet
 * @dev Facet implementation of IUniswapV2Aware interface for Diamond proxies
 * @dev Provides access to UniswapV2 factory and router instances
 */
contract UniswapV2AwareFacet is IUniswapV2Aware, IFacet {
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(UniswapV2AwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUniswapV2Aware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IUniswapV2Aware.uniV2Factory.selector;
        funcs[1] = IUniswapV2Aware.uniV2Router.selector;
    }

    function facetMetadata() external pure returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    /* ---------------------------------------------------------------------- */
    /*                            IUniswapV2Aware                             */
    /* ---------------------------------------------------------------------- */

    function uniV2Factory() external view returns (IUniswapV2Factory) {
        return UniswapV2AwareRepo._uniV2Factory();
    }

    function uniV2Router() external view returns (IUniswapV2Router) {
        return UniswapV2AwareRepo._uniV2Router();
    }
}
