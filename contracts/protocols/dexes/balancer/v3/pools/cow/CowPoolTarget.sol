// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {ICowPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowPool.sol";
import {ICowPoolFactory} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowPoolFactory.sol";
import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AfterSwapParams,
    HookFlags,
    LiquidityManagement,
    PoolConfig,
    PoolSwapParams,
    RemoveLiquidityKind,
    TokenConfig
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3WeightedPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.sol";
import {CowPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolRepo.sol";

/**
 * @title CowPoolTarget
 * @notice Implementation contract for Balancer V3 CoW Pool functionality.
 * @dev CoW Pools are weighted pools that integrate with CoW Protocol for MEV protection.
 * They restrict swaps to a trusted router and enable donation-based liquidity additions.
 *
 * Key features:
 * - Extends weighted pool math (via BalancerV3WeightedPoolTarget)
 * - Implements IHooks for access control on swaps and liquidity
 * - Only allows swaps from trusted CoW Router
 * - Enables donations for MEV surplus redistribution
 *
 * Storage dependencies:
 * - CowPoolRepo: trusted router and factory references
 * - BalancerV3WeightedPoolRepo: normalized weights
 * - BalancerV3VaultAwareRepo: vault reference
 */
contract CowPoolTarget is ICowPool, IHooks, BalancerV3WeightedPoolTarget {
    /* -------------------------------------------------------------------------- */
    /*                              Trusted Router                                */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICowPool
    function getTrustedCowRouter() external view returns (address) {
        return CowPoolRepo._getTrustedCowRouter();
    }

    /// @inheritdoc ICowPool
    function refreshTrustedCowRouter() external {
        address factory = CowPoolRepo._getCowPoolFactory();
        address newRouter = ICowPoolFactory(factory).getTrustedCowRouter();
        CowPoolRepo._setTrustedCowRouter(newRouter);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Dynamic and Immutable Data                        */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICowPool
    function getCowPoolDynamicData() external view returns (CoWPoolDynamicData memory data) {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();
        address pool = address(this);

        data.balancesLiveScaled18 = vault.getCurrentLiveBalances(pool);
        (, data.tokenRates) = vault.getPoolTokenRates(pool);
        data.staticSwapFeePercentage = vault.getStaticSwapFeePercentage(pool);
        data.totalSupply = IERC20(pool).totalSupply();
        data.trustedCowRouter = CowPoolRepo._getTrustedCowRouter();

        PoolConfig memory poolConfig = vault.getPoolConfig(pool);
        data.isPoolInitialized = poolConfig.isPoolInitialized;
        data.isPoolPaused = poolConfig.isPoolPaused;
        data.isPoolInRecoveryMode = poolConfig.isPoolInRecoveryMode;
    }

    /// @inheritdoc ICowPool
    function getCowPoolImmutableData() external view returns (CoWPoolImmutableData memory data) {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();
        address pool = address(this);

        data.tokens = vault.getPoolTokens(pool);
        (data.decimalScalingFactors,) = vault.getPoolTokenRates(pool);
        data.normalizedWeights = getNormalizedWeights();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Hooks                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public view virtual returns (bool) {
        // Verify registration conditions:
        // 1. Pool is registering itself (pool == this)
        // 2. Factory is our factory
        // 3. Donations are enabled (for MEV surplus)
        // 4. Unbalanced liquidity is disabled (prevents bypassing swap logic)
        return pool == address(this) && factory == CowPoolRepo._getCowPoolFactory()
            && liquidityManagement.enableDonation == true && liquidityManagement.disableUnbalancedLiquidity == true;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure virtual returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallBeforeSwap = true;
        hookFlags.shouldCallBeforeAddLiquidity = true;
    }

    /// @inheritdoc IHooks
    function onBeforeSwap(PoolSwapParams calldata params, address) public view virtual returns (bool) {
        // Only allow swaps from the trusted CoW Router for MEV protection
        return params.router == CowPoolRepo._getTrustedCowRouter();
    }

    /// @inheritdoc IHooks
    function onBeforeAddLiquidity(
        address router,
        address,
        AddLiquidityKind kind,
        uint256[] memory,
        uint256,
        uint256[] memory,
        bytes memory
    ) public view virtual returns (bool success) {
        // Donations from routers that are not the trusted CoW AMM Router should be blocked.
        // Any other liquidity operation is allowed from any router.
        // However, the factory of this pool also disables unbalanced liquidity operations.
        return kind != AddLiquidityKind.DONATION || router == CowPoolRepo._getTrustedCowRouter();
    }

    /* -------------------------------------------------------------------------- */
    /*                          Default Hook Implementations                      */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IHooks
    function onBeforeInitialize(uint256[] memory, bytes memory) public virtual returns (bool) {
        return true;
    }

    /// @inheritdoc IHooks
    function onAfterInitialize(uint256[] memory, uint256, bytes memory) public virtual returns (bool) {
        return true;
    }

    /// @inheritdoc IHooks
    function onAfterAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool, uint256[] memory) {
        return (true, amountsInRaw);
    }

    /// @inheritdoc IHooks
    function onBeforeRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool) {
        return true;
    }

    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool, uint256[] memory) {
        return (true, amountsOutRaw);
    }

    /// @inheritdoc IHooks
    function onAfterSwap(AfterSwapParams calldata) public virtual returns (bool, uint256) {
        return (true, 0);
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(PoolSwapParams calldata, address, uint256 staticSwapFeePercentage)
        public
        view
        virtual
        returns (bool, uint256)
    {
        // Use static fee, no dynamic fee computation
        return (true, staticSwapFeePercentage);
    }
}
