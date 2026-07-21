// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRETH} from "@crane/contracts/protocols/staking/ethereum/rocket-pool/interfaces/IRETH.sol";
import {IStakingRateProvider} from "@crane/contracts/protocols/staking/ethereum/common/rate/IStakingRateProvider.sol";

/**
 * @title RETHRateProvider
 * @notice IRateProvider for rETH via getExchangeRate().
 */
contract RETHRateProvider is IStakingRateProvider {
    IRETH public immutable R_ETH;

    constructor(IRETH rETH_) {
        require(address(rETH_) != address(0), "zero");
        R_ETH = rETH_;
    }

    function getRate() external view returns (uint256) {
        return R_ETH.getExchangeRate();
    }
}
