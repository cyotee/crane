// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IPoolInfo} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IAuthentication} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IAuthentication.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";

import {PoolConfig, TokenInfo} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {BalancerV3PoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3PoolRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3AuthenticationRepo.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3VaultAwareRepo.sol";
import {BalancerV3AuthenticationService} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3AuthenticationService.sol";
import {VaultGuardModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/VaultGuardModifiers.sol";
import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";

contract BalancerV3PoolTarget is VaultGuardModifiers, IERC20, IBalancerPoolToken, IPoolInfo, IUnbalancedLiquidityInvariantRatioBounds, IAuthentication {

    /* -------------------------------------------------------------------------- */
    /*                                   IERC20                                   */
    /* -------------------------------------------------------------------------- */

    function approve(address spender, uint256 amount) external returns (bool) {
        BalancerV3VaultAwareRepo._balancerV3Vault().approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        BalancerV3VaultAwareRepo._balancerV3Vault().transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
        BalancerV3VaultAwareRepo._balancerV3Vault().transferFrom(msg.sender, owner, recipient, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().totalSupply(address(this));
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().balanceOf(address(this), account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().allowance(address(this), owner, spender);
    }

    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    // /**
    //  * @inheritdoc IERC20Metadata
    //  */
    // function name() external view returns (string memory) {
    //     return ERC20Repo._name();
    // }

    // /**
    //  * @inheritdoc IERC20Metadata
    //  */
    // function symbol() external view returns (string memory) {
    //     return ERC20Repo._symbol();
    // }

    // /**
    //  * @inheritdoc IERC20Metadata
    //  */
    // function decimals() external view returns (uint8) {
    //     return ERC20Repo._decimals();
    // }

    /* -------------------------------------------------------------------------- */
    /*                                IRateProvider                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the BPT rate, which is defined as: pool invariant/total supply.
     * @dev The VaultExtension contract defines a default implementation (`getBptRate`) to calculate the rate
     * of any given pool, which should be sufficient in nearly all cases.
     *
     * @return rate Rate of the pool's BPT
     */
    function getRate() public view virtual returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getBptRate(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                             IBalancerPoolToken                             */
    /* -------------------------------------------------------------------------- */

    /// @dev Emit the Transfer event. This function can only be called by the MultiToken.
    function emitTransfer(address from, address to, uint256 amount) external onlyVault() {
        emit IERC20.Transfer(from, to, amount);
    }

    /// @dev Emit the Approval event. This function can only be called by the MultiToken.
    function emitApproval(address owner, address spender, uint256 amount) external onlyVault() {
        emit IERC20.Approval(owner, spender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  IPoolInfo                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IPoolInfo
    function getTokens() external view returns (IERC20[] memory tokens) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getPoolTokens(address(this));
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
        return BalancerV3VaultAwareRepo._balancerV3Vault().getPoolTokenInfo(address(this));
    }

    /// @inheritdoc IPoolInfo
    function getCurrentLiveBalances() external view returns (uint256[] memory balancesLiveScaled18) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getCurrentLiveBalances(address(this));
    }

    /// @inheritdoc IPoolInfo
    function getStaticSwapFeePercentage() external view returns (uint256) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getStaticSwapFeePercentage((address(this)));
    }

    /// @inheritdoc IPoolInfo
    function getAggregateFeePercentages()
        external
        view
        returns (uint256 aggregateSwapFeePercentage, uint256 aggregateYieldFeePercentage)
    {
        PoolConfig memory poolConfig = BalancerV3VaultAwareRepo._balancerV3Vault().getPoolConfig(address(this));

        aggregateSwapFeePercentage = poolConfig.aggregateSwapFeePercentage;
        aggregateYieldFeePercentage = poolConfig.aggregateYieldFeePercentage;
    }
    /* -------------------------------------------------------------------------- */
    /*                          ISwapFeePercentageBounds                          */
    /* -------------------------------------------------------------------------- */

    //The minimum swap fee percentage for a pool
    function getMinimumSwapFeePercentage() external view returns (uint256) {
        return BalancerV3PoolRepo._minimumSwapFeePercentage();
    }

    // The maximum swap fee percentage for a pool
    function getMaximumSwapFeePercentage() external view returns (uint256) {
        return BalancerV3PoolRepo._maximumSwapFeePercentage();
    }
    /* -------------------------------------------------------------------------- */
    /*                  IUnbalancedLiquidityInvariantRatioBounds                  */
    /* -------------------------------------------------------------------------- */

    // Invariant shrink limit: non-proportional remove cannot cause the invariant to decrease by less than this ratio
    function getMinimumInvariantRatio() external view returns (uint256) {
        return BalancerV3PoolRepo._minimumInvariantRatio();
    }

    // Invariant growth limit: non-proportional add cannot cause the invariant to increase by more than this ratio
    function getMaximumInvariantRatio() external view returns (uint256) {
        return BalancerV3PoolRepo._maximumInvariantRatio();
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               IAuthentication                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IAuthentication
    function getActionId(bytes4 selector) public view returns (bytes32) {
        return BalancerV3AuthenticationRepo._getActionId(selector);
    }

}