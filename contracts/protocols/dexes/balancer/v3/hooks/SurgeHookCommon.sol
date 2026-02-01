// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {ISurgeHookCommon} from "@balancer-labs/v3-interfaces/contracts/pool-hooks/ISurgeHookCommon.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    HookFlags,
    LiquidityManagement,
    RemoveLiquidityKind,
    TokenConfig,
    PoolSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {SingletonAuthentication} from "@balancer-labs/v3-vault/contracts/SingletonAuthentication.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {Version} from "@balancer-labs/v3-solidity-utils/contracts/helpers/Version.sol";

import {BaseHooksTarget} from "./BaseHooksTarget.sol";

/* -------------------------------------------------------------------------- */
/*                             SurgeHookCommon                                */
/* -------------------------------------------------------------------------- */

/**
 * @title SurgeHookCommon
 * @notice Base contract for surge hook implementations (StableSurgeHook, ECLPSurgeHook).
 * @dev Implements dynamic fee calculation based on pool imbalance thresholds.
 *
 * Surge pricing formula:
 *   surgeFee = staticFee + (maxFee - staticFee) * (imbalance - threshold) / (1 - threshold)
 *
 * This creates a linear fee increase from staticFee at threshold to maxFee as imbalance approaches 100%.
 *
 * Derived contracts must implement:
 * - `_isSurgingSwap`: Determines if a swap causes surge pricing
 * - `_isSurgingUnbalancedLiquidity`: Determines if add/remove causes surge
 *
 * @custom:security-contact security@example.com
 */
abstract contract SurgeHookCommon is
    ISurgeHookCommon,
    BaseHooksTarget,
    SingletonAuthentication,
    Version
{
    using FixedPoint for uint256;
    using SafeCast for *;

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice Default max surge fee percentage for new pools.
    uint256 private immutable _defaultMaxSurgeFeePercentage;

    /// @notice Default imbalance threshold for new pools.
    uint256 private immutable _defaultSurgeThresholdPercentage;

    /// @notice Per-pool surge configuration.
    mapping(address pool => SurgeFeeData data) internal _surgeFeePoolData;

    /* ========================================================================== */
    /*                                  MODIFIERS                                 */
    /* ========================================================================== */

    modifier withValidPercentage(uint256 percentageValue) {
        _ensureValidPercentage(percentageValue);
        _;
    }

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new SurgeHookCommon.
     * @param vault_ The Balancer V3 Vault.
     * @param defaultMaxSurgeFeePercentage_ Default max surge fee (18-decimal FP).
     * @param defaultSurgeThresholdPercentage_ Default surge threshold (18-decimal FP).
     * @param version_ Contract version string.
     */
    constructor(
        IVault vault_,
        uint256 defaultMaxSurgeFeePercentage_,
        uint256 defaultSurgeThresholdPercentage_,
        string memory version_
    )
        BaseHooksTarget(vault_)
        SingletonAuthentication(vault_)
        Version(version_)
    {
        _ensureValidPercentage(defaultMaxSurgeFeePercentage_);
        _ensureValidPercentage(defaultSurgeThresholdPercentage_);

        _defaultMaxSurgeFeePercentage = defaultMaxSurgeFeePercentage_;
        _defaultSurgeThresholdPercentage = defaultSurgeThresholdPercentage_;
    }

    /* ========================================================================== */
    /*                            ABSTRACT FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Determines if a swap triggers surge pricing.
     * @dev Must be implemented by derived contracts (StableSurgeHook, ECLPSurgeHook).
     * @param params The swap parameters.
     * @param pool The pool address.
     * @param staticSwapFeePercentage The pool's static swap fee.
     * @param surgeFeeData The pool's surge configuration.
     * @return isSurging True if surge pricing should apply.
     * @return newTotalImbalance The imbalance after the swap.
     */
    function _isSurgingSwap(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage,
        SurgeFeeData memory surgeFeeData
    ) internal view virtual returns (bool isSurging, uint256 newTotalImbalance);

    /**
     * @notice Determines if an add/remove liquidity triggers surge pricing.
     * @dev Must be implemented by derived contracts.
     * @param pool The pool address.
     * @param oldBalancesScaled18 Balances before the operation.
     * @param balancesScaled18 Balances after the operation.
     * @return isSurging True if operation should be blocked.
     */
    function _isSurgingUnbalancedLiquidity(
        address pool,
        uint256[] memory oldBalancesScaled18,
        uint256[] memory balancesScaled18
    ) internal view virtual returns (bool isSurging);

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc BaseHooksTarget
    function getHookFlags() public pure virtual override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
    }

    /// @inheritdoc BaseHooksTarget
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public virtual override onlyVault returns (bool) {
        // Set default surge parameters for new pools
        _setMaxSurgeFeePercentage(pool, _defaultMaxSurgeFeePercentage);
        _setSurgeThresholdPercentage(pool, _defaultSurgeThresholdPercentage);

        return true;
    }

    /// @inheritdoc BaseHooksTarget
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view virtual override returns (bool, uint256) {
        return (true, computeSwapSurgeFeePercentage(params, pool, staticSwapFeePercentage));
    }

    /// @inheritdoc BaseHooksTarget
    function onAfterAddLiquidity(
        address,
        address pool,
        AddLiquidityKind kind,
        uint256[] memory amountsInScaled18,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public view virtual override returns (bool success, uint256[] memory hookAdjustedAmountsInRaw) {
        // Proportional adds are always allowed
        if (kind == AddLiquidityKind.PROPORTIONAL) {
            return (true, amountsInRaw);
        }

        // Rebuild old balances
        uint256[] memory oldBalancesScaled18 = new uint256[](balancesScaled18.length);
        for (uint256 i = 0; i < balancesScaled18.length; ++i) {
            oldBalancesScaled18[i] = balancesScaled18[i] - amountsInScaled18[i];
        }

        bool isSurging = _isSurgingUnbalancedLiquidity(pool, oldBalancesScaled18, balancesScaled18);

        // Block if surging, allow otherwise
        return (isSurging == false, amountsInRaw);
    }

    /// @inheritdoc BaseHooksTarget
    function onAfterRemoveLiquidity(
        address,
        address pool,
        RemoveLiquidityKind kind,
        uint256,
        uint256[] memory amountsOutScaled18,
        uint256[] memory amountsOutRaw,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public view virtual override returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw) {
        // Proportional removes are always allowed
        if (kind == RemoveLiquidityKind.PROPORTIONAL) {
            return (true, amountsOutRaw);
        }

        // Rebuild old balances
        uint256[] memory oldBalancesScaled18 = new uint256[](balancesScaled18.length);
        for (uint256 i = 0; i < balancesScaled18.length; ++i) {
            oldBalancesScaled18[i] = balancesScaled18[i] + amountsOutScaled18[i];
        }

        bool isSurging = _isSurgingUnbalancedLiquidity(pool, oldBalancesScaled18, balancesScaled18);

        // Block if surging, allow otherwise
        return (isSurging == false, amountsOutRaw);
    }

    /* ========================================================================== */
    /*                            SURGE FEE COMPUTATION                           */
    /* ========================================================================== */

    /// @inheritdoc ISurgeHookCommon
    function computeSwapSurgeFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view returns (uint256 surgeFeePercentage) {
        SurgeFeeData memory surgeFeeData = _surgeFeePoolData[pool];

        (bool isSurging, uint256 newTotalImbalance) = _isSurgingSwap(
            params,
            pool,
            staticSwapFeePercentage,
            surgeFeeData
        );

        if (isSurging) {
            // surgeFee = staticFee + (maxFee - staticFee) * (imbalance - threshold) / (1 - threshold)
            surgeFeePercentage =
                staticSwapFeePercentage +
                (surgeFeeData.maxSurgeFeePercentage - staticSwapFeePercentage).mulDown(
                    (newTotalImbalance - surgeFeeData.thresholdPercentage).divDown(
                        uint256(surgeFeeData.thresholdPercentage).complement()
                    )
                );
        } else {
            surgeFeePercentage = staticSwapFeePercentage;
        }
    }

    /// @inheritdoc ISurgeHookCommon
    function isSurgingSwap(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) external view returns (bool isSurging) {
        SurgeFeeData memory surgeFeeData = _surgeFeePoolData[pool];
        (isSurging, ) = _isSurgingSwap(params, pool, staticSwapFeePercentage, surgeFeeData);
    }

    /* ========================================================================== */
    /*                            GETTERS AND SETTERS                             */
    /* ========================================================================== */

    /// @inheritdoc ISurgeHookCommon
    function getDefaultMaxSurgeFeePercentage() external view returns (uint256) {
        return _defaultMaxSurgeFeePercentage;
    }

    /// @inheritdoc ISurgeHookCommon
    function getDefaultSurgeThresholdPercentage() external view returns (uint256) {
        return _defaultSurgeThresholdPercentage;
    }

    /// @inheritdoc ISurgeHookCommon
    function getMaxSurgeFeePercentage(address pool) external view returns (uint256) {
        return _surgeFeePoolData[pool].maxSurgeFeePercentage;
    }

    /// @inheritdoc ISurgeHookCommon
    function getSurgeThresholdPercentage(address pool) external view returns (uint256) {
        return _surgeFeePoolData[pool].thresholdPercentage;
    }

    /// @inheritdoc ISurgeHookCommon
    function setMaxSurgeFeePercentage(
        address pool,
        uint256 newMaxSurgeSurgeFeePercentage
    ) external withValidPercentage(newMaxSurgeSurgeFeePercentage) onlySwapFeeManagerOrGovernance(pool) {
        _setMaxSurgeFeePercentage(pool, newMaxSurgeSurgeFeePercentage);
    }

    /// @inheritdoc ISurgeHookCommon
    function setSurgeThresholdPercentage(
        address pool,
        uint256 newSurgeThresholdPercentage
    ) external withValidPercentage(newSurgeThresholdPercentage) onlySwapFeeManagerOrGovernance(pool) {
        _setSurgeThresholdPercentage(pool, newSurgeThresholdPercentage);
    }

    /* ========================================================================== */
    /*                              INTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Determines if pool is surging based on imbalance change.
     * @param thresholdPercentage The surge threshold.
     * @param oldTotalImbalance Imbalance before operation.
     * @param newTotalImbalance Imbalance after operation.
     * @return isSurging True if surging conditions are met.
     */
    function _isSurging(
        uint64 thresholdPercentage,
        uint256 oldTotalImbalance,
        uint256 newTotalImbalance
    ) internal pure virtual returns (bool isSurging) {
        // Perfectly balanced = no surge
        if (newTotalImbalance == 0) {
            return false;
        }

        // Surge if imbalance increased AND we're above threshold
        return (newTotalImbalance > oldTotalImbalance && newTotalImbalance > thresholdPercentage);
    }

    function _setMaxSurgeFeePercentage(address pool, uint256 newMaxSurgeFeePercentage) internal {
        _surgeFeePoolData[pool].maxSurgeFeePercentage = newMaxSurgeFeePercentage.toUint64();
        emit MaxSurgeFeePercentageChanged(pool, newMaxSurgeFeePercentage);
    }

    function _setSurgeThresholdPercentage(address pool, uint256 newSurgeThresholdPercentage) internal {
        _surgeFeePoolData[pool].thresholdPercentage = newSurgeThresholdPercentage.toUint64();
        emit ThresholdSurgePercentageChanged(pool, newSurgeThresholdPercentage);
    }

    function _ensureValidPercentage(uint256 percentage) private pure {
        if (percentage > FixedPoint.ONE) {
            revert InvalidPercentage();
        }
    }
}
