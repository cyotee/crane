// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IWeETH} from "@crane/contracts/protocols/staking/ethereum/etherfi/interfaces/IWeETH.sol";
import {IStakingRateProvider} from "@crane/contracts/protocols/staking/ethereum/common/rate/IStakingRateProvider.sol";

/**
 * @title WeETHRateProvider
 * @notice IRateProvider for weETH via getRate().
 */
contract WeETHRateProvider is IStakingRateProvider {
    IWeETH public immutable WE_ETH;

    constructor(IWeETH weETH_) {
        require(address(weETH_) != address(0), "zero");
        WE_ETH = weETH_;
    }

    function getRate() external view returns (uint256) {
        return WE_ETH.getRate();
    }
}
