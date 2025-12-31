// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IPoolInfo} from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import {PoolConfig, TokenInfo} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3VaultAware} from "contracts/crane/interfaces/IBalancerV3VaultAware.sol";
import {
    BalancerV3VaultAwareStorage
} from "contracts/crane/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

contract DefaultPoolInfoFacet is Create3AwareContract, BalancerV3VaultAwareStorage, IFacet, IPoolInfo {
    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPoolInfo).interfaceId;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = IPoolInfo.getTokens.selector;
        funcs[1] = IPoolInfo.getTokenInfo.selector;
        funcs[2] = IPoolInfo.getCurrentLiveBalances.selector;
        funcs[3] = IPoolInfo.getStaticSwapFeePercentage.selector;
        funcs[4] = IPoolInfo.getAggregateFeePercentages.selector;
    }

    /// @inheritdoc IPoolInfo
    function getTokens() external view returns (IERC20[] memory tokens) {
        return _balV3Vault().getPoolTokens(address(this));
    }

    /// @inheritdoc IPoolInfo
    function getTokenInfo()
        external
        view
        returns (
            IERC20[] memory tokens,
            TokenInfo[] memory tokenInfo,
            uint256[] memory balancesRaw,
            uint256[] memory lastBalancesLiveScaled18
        )
    {
        return _balV3Vault().getPoolTokenInfo(address(this));
    }

    /// @inheritdoc IPoolInfo
    function getCurrentLiveBalances() external view returns (uint256[] memory balancesLiveScaled18) {
        return _balV3Vault().getCurrentLiveBalances(address(this));
    }

    /// @inheritdoc IPoolInfo
    function getStaticSwapFeePercentage() external view returns (uint256) {
        return _balV3Vault().getStaticSwapFeePercentage((address(this)));
    }

    /// @inheritdoc IPoolInfo
    function getAggregateFeePercentages()
        external
        view
        returns (uint256 aggregateSwapFeePercentage, uint256 aggregateYieldFeePercentage)
    {
        PoolConfig memory poolConfig = _balV3Vault().getPoolConfig(address(this));

        aggregateSwapFeePercentage = poolConfig.aggregateSwapFeePercentage;
        aggregateYieldFeePercentage = poolConfig.aggregateYieldFeePercentage;
    }
}
