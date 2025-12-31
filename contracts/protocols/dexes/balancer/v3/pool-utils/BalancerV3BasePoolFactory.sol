// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from"@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IBalancerV3BasePoolFactory} from "@crane/contracts/interfaces/IBalancerV3BasePoolFactory.sol";
import {IAuthentication} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IAuthentication.sol";
import {IFactoryWidePauseWindow} from "@crane/contracts/interfaces/IFactoryWidePauseWindow.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenType,
    TokenConfig
} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {BalancerV3BasePoolFactoryRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {DiamondPackageFactoryAwareRepo} from "@crane/contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3AuthenticationModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationModifiers.sol";

abstract contract BalancerV3BasePoolFactory is BalancerV3AuthenticationModifiers, IAuthentication, IBalancerV3BasePoolFactory, IFactoryWidePauseWindow {

    /* -------------------------------------------------------------------------- */
    /*                              IBasePoolFactory                              */
    /* -------------------------------------------------------------------------- */

    function isPoolFromFactory(address pool) public view virtual returns (bool) {
        return BalancerV3BasePoolFactoryRepo._isPoolFromFactory(pool);
    }

    function getPoolCount() public view virtual returns (uint256) {
        return BalancerV3BasePoolFactoryRepo._getPoolCount();
    }

    function getPools() public view virtual returns (address[] memory) {
        return BalancerV3BasePoolFactoryRepo._getPools();
    }

    function getDeploymentAddress(
        bytes memory constructorArgs,
        bytes32 // salt
    )
        public
        view
        virtual
        returns (address)
    {
        return _diamondPkgFactory().calcAddress(_poolDFPkg(), constructorArgs);
    }

    function isDisabled() public view virtual returns (bool) {
        return BalancerV3BasePoolFactoryRepo._isDisabled();
    }

    function disable() external authenticate(address(this)) {
        BalancerV3BasePoolFactoryRepo._ensureEnabled();

        BalancerV3BasePoolFactoryRepo._disable();

        emit FactoryDisabled();
    }

    function getPoolsInRange(uint256 start, uint256 count) public view virtual returns (address[] memory) {
        return BalancerV3BasePoolFactoryRepo._getPoolsInRange(start, count);
    }

    /* -------------------------------------------------------------------------- */
    /*                         IBalancerV3BasePoolFactory                         */
    /* -------------------------------------------------------------------------- */

    function tokenConfigs(address pool) public view returns (TokenConfig[] memory) {
        return BalancerV3BasePoolFactoryRepo._getTokenConfigs(pool);
    }

    /* -------------------------------------------------------------------------- */
    /*                               IAuthentication                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IAuthentication
     */
    function getActionId(bytes4 selector) public view returns (bytes32) {
        return BalancerV3AuthenticationRepo._getActionId(selector);
    }

    /* -------------------------------------------------------------------------- */
    /*                           IFactoryWidePauseWindow                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getPauseWindowDuration() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowDuration();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getOriginalPauseWindowEndTime() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowEndTime();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getNewPoolPauseWindowEndTime() public view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._getNewPoolPauseWindowEndTime();
    }

    function _diamondPkgFactory() internal view virtual returns (IDiamondPackageCallBackFactory);

    function _poolDFPkg() internal view virtual returns (IDiamondFactoryPackage);

    function _registerPoolWithBalV3Vault(
        address pool,
        TokenConfig[] memory tokens,
        uint256 swapFeePercentage,
        bool protocolFeeExempt,
        PoolRoleAccounts memory roleAccounts,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) internal {
        BalancerV3BasePoolFactoryRepo._addPool(pool);
        BalancerV3VaultAwareRepo._balancerV3Vault()
            .registerPool(
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