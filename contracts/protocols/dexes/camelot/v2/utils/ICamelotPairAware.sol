// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotFactory} from "../ICamelotFactory.sol";
import {ICamelotPair} from "../ICamelotPair.sol";
import {ICamelotV2Router} from "../ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "../../../../../token/ERC20/BetterIERC20.sol";

interface ICamelotPairAware {

    struct CamelotPair {
        ICamelotPair pool;
        IERC20 token0;
        uint256 token0Reserve;
        uint256 token0SaleFee;
        IERC20 token1;
        uint256 token1Reserve;
        uint256 token1SaleFee;
    }

    function camelotFactory() external view returns (ICamelotFactory);

    function camV2Router() external view returns (ICamelotV2Router);

    function camV2Pair() external view returns (ICamelotPair);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function opTokenOfToken(IERC20 token) external view returns (IERC20);

    function loadPair() external view returns (CamelotPair memory pair);
    
}