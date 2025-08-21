// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";


/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondPackageCallBackFactory} from "contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";
import {Create2CallbackContract} from "contracts/factories/create2/callback/Create2CallbackContract.sol";
import {FactoryWidePauseWindowTarget} from "contracts/protocols/dexes/balancer/v3/solidity-utils/helpers/FactoryWidePauseWindowTarget.sol";
import {BalancerV3AuthenticationTarget} from "contracts/protocols/dexes/balancer/v3/solidity-utils/BalancerV3AuthenticationTarget.sol";
import {BalancerV3AuthenticationModifiers} from "contracts/protocols/dexes/balancer/v3/solidity-utils/utils/BalancerV3AuthenticationModifiers.sol";
import {BalancerV3BasePoolFactoryStorage} from "contracts/protocols/dexes/balancer/v3/pool-utils/utils/BalancerV3BasePoolFactoryStorage.sol";
import { IBalancerV3BasePoolFactory } from "contracts/interfaces/IBalancerV3BasePoolFactory.sol";

abstract contract BalancerV3BasePoolFactoryTarget
is
    BalancerV3BasePoolFactoryStorage,
    BalancerV3AuthenticationModifiers,
    BalancerV3AuthenticationTarget,
    FactoryWidePauseWindowTarget,
    IBasePoolFactory,
    IBalancerV3BasePoolFactory
{

    address immutable public SELF;

    constructor() {
        SELF = address(this);
    }

    function isPoolFromFactory(address pool) public view virtual returns (bool) {
        return _isPoolFromFactory(pool);
    }

    function getPoolCount() public view virtual returns (uint256) {
        return _getPoolCount();
    }

    function getPools() public view virtual returns (address[] memory) {
        return _getPools();
    }

    function getPoolsInRange(uint256 start, uint256 count) public view virtual returns (address[] memory) {
        return _getPoolsInRange(start, count);
    }

    function isDisabled() public view virtual returns (bool) {
        return _isDisabled();
    }

    function getDeploymentAddress(
        bytes memory constructorArgs,
        bytes32 // salt
    ) public view virtual returns (address) {
        return _diamondPkgFactory().calcAddress(
            _poolDFPkg(),
            constructorArgs
        );
    }

    function disable() external authenticate(SELF) {
        _ensureEnabled();

        _balV3PoolFactory().isDisabled = true;

        emit FactoryDisabled();
    }

    /// @notice A common place to retrieve a default hooks contract. Currently set to address(0) (i.e. no hooks).
    function getDefaultPoolHooksContract() public pure returns (address) {
        return address(0);
    }

    /**
     * @notice Convenience function for constructing a LiquidityManagement object.
     * @dev Users can call this to create a structure with all false arguments, then set the ones they need to true.
     * @return liquidityManagement Liquidity management flags, all initialized to false
     */
    function getDefaultLiquidityManagement() public pure returns (LiquidityManagement memory liquidityManagement) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function tokenConfigs(address pool) public view returns (TokenConfig[] memory) {
        return _getTokenConfigs(pool);
    }
    
    function _diamondPkgFactory()
    internal view virtual returns (IDiamondPackageCallBackFactory);
    
    function _poolDFPkg()
    internal view virtual returns (IDiamondFactoryPackage);
    
    function _registerPoolWithVault(
        address pool,
        TokenConfig[] memory tokens,
        uint256 swapFeePercentage,
        bool protocolFeeExempt,
        PoolRoleAccounts memory roleAccounts,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) internal {
        _addPool(pool);
        _balV3Vault().registerPool(
            pool,
            tokens,
            swapFeePercentage,
            getNewPoolPauseWindowEndTime(),
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

}