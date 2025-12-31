// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";

import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {ICamelotPairAware} from "contracts/crane/interfaces/ICamelotPairAware.sol";
import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {CamelotPairAwareTarget} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotPairAwareTarget.sol";

/**
 * @title CamelotV2AwareFacet
 * @dev Facet implementation of ICamelotPairAware interface for Diamond proxies
 * @dev Provides access to Camelot V2 factory, router, and pair instances with variable fee support
 */
contract CamelotV2AwareFacet is Create3AwareContract, CamelotPairAwareTarget, IFacet {
    constructor(CREATE3InitData memory initData_) Create3AwareContract(initData_) {}

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICamelotPairAware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](7);
        funcs[0] = ICamelotPairAware.camelotFactory.selector;
        funcs[1] = ICamelotPairAware.camV2Router.selector;
        funcs[2] = ICamelotPairAware.camV2Pair.selector;
        funcs[3] = ICamelotPairAware.token0.selector;
        funcs[4] = ICamelotPairAware.token1.selector;
        funcs[5] = ICamelotPairAware.opTokenOfToken.selector;
        funcs[6] = ICamelotPairAware.loadPair.selector;
    }

    /* ---------------------------------------------------------------------- */
    /*                           ICamelotPairAware                            */
    /* ---------------------------------------------------------------------- */

    // function camelotFactory() external view returns (ICamelotFactory) {
    //     return _camV2Factory();
    // }

    // function camV2Router() external view returns (ICamelotV2Router) {
    //     return _camV2Router();
    // }

    // function camV2Pair() external view returns (ICamelotPair) {
    //     return _camV2Pair();
    // }

    // function token0() external view returns (IERC20) {
    //     return _token0();
    // }

    // function token1() external view returns (IERC20) {
    //     return _token1();
    // }

    // function opTokenOfToken(IERC20 token) external view returns (IERC20) {
    //     return _opTokenOfToken(token);
    // }

    // function loadPair() external view returns (CamelotPair memory pair) {
    //     return _loadPair();
    // }
}
