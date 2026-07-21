// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {IsfrxETH} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IsfrxETH.sol";
import {IStakingRateProvider} from "@crane/contracts/protocols/staking/ethereum/common/rate/IStakingRateProvider.sol";

/**
 * @title SfrxETHRateProvider
 * @notice IRateProvider for sfrxETH via convertToAssets(1e18).
 */
contract SfrxETHRateProvider is IStakingRateProvider {
    IsfrxETH public immutable SFRX_ETH;

    constructor(IsfrxETH sfrxETH_) {
        require(address(sfrxETH_) != address(0), "zero");
        SFRX_ETH = sfrxETH_;
    }

    /// @notice Returns frxETH per 1e18 sfrxETH shares (18-decimal rate).
    function getRate() external view returns (uint256) {
        return SFRX_ETH.convertToAssets(1e18);
    }
}
