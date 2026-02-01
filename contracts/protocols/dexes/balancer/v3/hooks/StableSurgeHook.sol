// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {ScalingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {StablePool} from "@balancer-labs/v3-pool-stable/contracts/StablePool.sol";

import {SurgeHookCommon} from "./SurgeHookCommon.sol";
import {ISurgeHookCommon} from "@balancer-labs/v3-interfaces/contracts/pool-hooks/ISurgeHookCommon.sol";
import {StableSurgeMedianMath} from "./utils/StableSurgeMedianMath.sol";

/* -------------------------------------------------------------------------- */
/*                             StableSurgeHook                                */
/* -------------------------------------------------------------------------- */

/**
 * @title StableSurgeHook
 * @notice Hook that charges surge fees on swaps that push stable pools into imbalance.
 * @dev Uses median-based imbalance calculation for multi-token stable pools.
 *
 * The surge fee increases linearly from the static fee at the threshold to
 * the max fee as the pool approaches complete imbalance.
 *
 * Example scenario with 30% threshold and 95% max fee:
 * - At 30% imbalance: static fee applies
 * - At 35% imbalance: ~8.2% fee
 * - At 50% imbalance: ~44% fee
 * - At 99% imbalance: ~94% fee (approaching max)
 *
 * @custom:security-contact security@example.com
 */
contract StableSurgeHook is SurgeHookCommon {
    /* ========================================================================== */
    /*                                   EVENTS                                   */
    /* ========================================================================== */

    /**
     * @notice Emitted when this hook is successfully registered for a pool.
     * @param pool The pool address.
     * @param factory The factory that created the pool.
     */
    event StableSurgeHookRegistered(address indexed pool, address indexed factory);

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new StableSurgeHook.
     * @param vault_ The Balancer V3 Vault.
     * @param defaultMaxSurgeFeePercentage_ Default max surge fee (e.g., 95e16 = 95%).
     * @param defaultSurgeThresholdPercentage_ Default threshold (e.g., 30e16 = 30%).
     * @param version_ Contract version string.
     */
    constructor(
        IVault vault_,
        uint256 defaultMaxSurgeFeePercentage_,
        uint256 defaultSurgeThresholdPercentage_,
        string memory version_
    )
        SurgeHookCommon(
            vault_,
            defaultMaxSurgeFeePercentage_,
            defaultSurgeThresholdPercentage_,
            version_
        )
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc SurgeHookCommon
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory tokenConfig,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool success) {
        success = super.onRegister(factory, pool, tokenConfig, liquidityManagement);

        emit StableSurgeHookRegistered(pool, factory);
    }

    /* ========================================================================== */
    /*                            SURGE IMPLEMENTATION                            */
    /* ========================================================================== */

    /// @inheritdoc SurgeHookCommon
    function _isSurgingSwap(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage,
        ISurgeHookCommon.SurgeFeeData memory surgeFeeData
    ) internal view override returns (bool isSurging, uint256 newTotalImbalance) {
        // If max surge fee <= static fee, no point calculating
        if (surgeFeeData.maxSurgeFeePercentage < staticSwapFeePercentage) {
            return (false, 0);
        }

        // Simulate the swap to get the calculated amount
        uint256 amountCalculatedScaled18 = StablePool(pool).onSwap(params);

        // Create new balances array after swap
        uint256[] memory newBalancesScaled18 = new uint256[](params.balancesScaled18.length);
        ScalingHelpers.copyToArray(params.balancesScaled18, newBalancesScaled18);

        if (params.kind == SwapKind.EXACT_IN) {
            newBalancesScaled18[params.indexIn] += params.amountGivenScaled18;
            newBalancesScaled18[params.indexOut] -= amountCalculatedScaled18;
        } else {
            newBalancesScaled18[params.indexIn] += amountCalculatedScaled18;
            newBalancesScaled18[params.indexOut] -= params.amountGivenScaled18;
        }

        uint256 oldTotalImbalance = StableSurgeMedianMath.calculateImbalance(params.balancesScaled18);
        newTotalImbalance = StableSurgeMedianMath.calculateImbalance(newBalancesScaled18);

        isSurging = _isSurging(surgeFeeData.thresholdPercentage, oldTotalImbalance, newTotalImbalance);
    }

    /// @inheritdoc SurgeHookCommon
    function _isSurgingUnbalancedLiquidity(
        address pool,
        uint256[] memory oldBalancesScaled18,
        uint256[] memory balancesScaled18
    ) internal view override returns (bool isSurging) {
        ISurgeHookCommon.SurgeFeeData memory surgeFeeData = _surgeFeePoolData[pool];

        uint256 oldTotalImbalance = StableSurgeMedianMath.calculateImbalance(oldBalancesScaled18);
        uint256 newTotalImbalance = StableSurgeMedianMath.calculateImbalance(balancesScaled18);

        isSurging = _isSurging(surgeFeeData.thresholdPercentage, oldTotalImbalance, newTotalImbalance);
    }

    /* ========================================================================== */
    /*                              LEGACY FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Computes the surge fee percentage for a given swap.
     * @dev Deprecated: use `computeSwapSurgeFeePercentage` instead.
     * @param params The swap parameters.
     * @param pool The pool address.
     * @param staticSwapFeePercentage The pool's static swap fee.
     * @return surgeFeePercentage The calculated surge fee percentage.
     */
    function getSurgeFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view returns (uint256 surgeFeePercentage) {
        return computeSwapSurgeFeePercentage(params, pool, staticSwapFeePercentage);
    }
}
