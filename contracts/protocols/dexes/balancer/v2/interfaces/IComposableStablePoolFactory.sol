pragma solidity ^0.8.20;

import {
    IRateProvider
} from "../../common/interfaces/IRateProvider.sol";
import {
    IBasePool
} from "./IBasePool.sol";
import {
    IERC20
} from "../../../../../tokens/erc20/interfaces/IERC20.sol";

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