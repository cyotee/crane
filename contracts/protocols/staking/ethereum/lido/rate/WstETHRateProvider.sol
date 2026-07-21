// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IWstETH} from "@crane/contracts/protocols/staking/ethereum/lido/interfaces/IWstETH.sol";
import {IStakingRateProvider} from "@crane/contracts/protocols/staking/ethereum/common/rate/IStakingRateProvider.sol";

/**
 * @title WstETHRateProvider
 * @notice IRateProvider for wstETH via stEthPerToken().
 */
contract WstETHRateProvider is IStakingRateProvider {
    IWstETH public immutable WST_ETH;

    constructor(IWstETH wstETH_) {
        require(address(wstETH_) != address(0), "zero");
        WST_ETH = wstETH_;
    }

    function getRate() external view returns (uint256) {
        return WST_ETH.stEthPerToken();
    }
}
