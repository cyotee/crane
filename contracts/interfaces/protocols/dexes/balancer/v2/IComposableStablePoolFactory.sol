// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IRateProvider
} from "../common/IRateProvider.sol";
import {
    IBasePool
} from "./IBasePool.sol";
import {
    BetterIERC20 as IERC20
} from "../../../../BetterIERC20.sol";

// 

interface IComposableStablePoolFactory {

    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amplificationParameter,
        IRateProvider[] memory rateProviders,
        uint256[] memory tokenRateCacheDurations,
        bool exemptFromYieldProtocolFeeFlag,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns (IBasePool);
    
}