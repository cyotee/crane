// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IECLPSurgeHook} from "@balancer-labs/v3-interfaces/contracts/pool-hooks/IECLPSurgeHook.sol";
import {IGyroECLPPool} from "@balancer-labs/v3-interfaces/contracts/pool-gyro/IGyroECLPPool.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {ScalingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {SignedFixedPoint} from "@balancer-labs/v3-pool-gyro/contracts/lib/SignedFixedPoint.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {GyroECLPMath} from "@balancer-labs/v3-pool-gyro/contracts/lib/GyroECLPMath.sol";

import {SurgeHookCommon} from "./SurgeHookCommon.sol";
import {ISurgeHookCommon} from "@balancer-labs/v3-interfaces/contracts/pool-hooks/ISurgeHookCommon.sol";

/* -------------------------------------------------------------------------- */
/*                              ECLPSurgeHook                                 */
/* -------------------------------------------------------------------------- */

/**
 * @title ECLPSurgeHook
 * @notice Hook that charges surge fees on swaps that push Gyro E-CLP pools into imbalance.
 * @dev Uses E-CLP specific imbalance calculation based on distance from peak price.
 *
 * The E-CLP (Ellipse Concentrated Liquidity Pool) has a peak liquidity price at
 * tan(rotation angle). This hook charges fees when trades move away from that peak.
 *
 * Requirements:
 * - Pool rotation angle must be between 30 and 60 degrees (sin/cos > 0.5)
 *
 * @custom:security-contact security@example.com
 */
contract ECLPSurgeHook is IECLPSurgeHook, SurgeHookCommon {
    using SignedFixedPoint for int256;
    using FixedPoint for uint256;
    using SafeCast for *;

    /* ========================================================================== */
    /*                                   STRUCTS                                  */
    /* ========================================================================== */

    /// @notice Per-pool imbalance slope configuration.
    struct ImbalanceSlopeData {
        uint128 imbalanceSlopeBelowPeak;
        uint128 imbalanceSlopeAbovePeak;
    }

    /* ========================================================================== */
    /*                                  CONSTANTS                                 */
    /* ========================================================================== */

    /// @notice Default imbalance slope (1.0 in 18-decimal FP).
    uint128 internal constant _DEFAULT_IMBALANCE_SLOPE = uint128(FixedPoint.ONE);

    /// @notice Minimum allowed imbalance slope (0.01).
    uint128 public constant MIN_IMBALANCE_SLOPE = 0.01e18;

    /// @notice Maximum allowed imbalance slope (100).
    uint128 public constant MAX_IMBALANCE_SLOPE = 100e18;

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice Per-pool imbalance slope data.
    mapping(address pool => ImbalanceSlopeData data) internal _imbalanceSlopePoolData;

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new ECLPSurgeHook.
     * @param vault_ The Balancer V3 Vault.
     * @param defaultMaxSurgeFeePercentage_ Default max surge fee.
     * @param defaultSurgeThresholdPercentage_ Default surge threshold.
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
        (IGyroECLPPool.EclpParams memory eclpParams, ) = IGyroECLPPool(pool).getECLPParams();

        // Validate rotation angle is between 30 and 60 degrees
        // sin(30°) = 0.5, cos(60°) = 0.5
        if (eclpParams.s < 50e16 || eclpParams.c < 50e16) {
            revert InvalidRotationAngle();
        }

        success = super.onRegister(factory, pool, tokenConfig, liquidityManagement);

        _setImbalanceSlopeBelowPeak(pool, _DEFAULT_IMBALANCE_SLOPE);
        _setImbalanceSlopeAbovePeak(pool, _DEFAULT_IMBALANCE_SLOPE);

        emit ECLPSurgeHookRegistered(pool, factory);
    }

    /* ========================================================================== */
    /*                            GETTERS AND SETTERS                             */
    /* ========================================================================== */

    /// @inheritdoc IECLPSurgeHook
    function getImbalanceSlopes(address pool) external view returns (uint256, uint256) {
        ImbalanceSlopeData memory data = _imbalanceSlopePoolData[pool];
        return (data.imbalanceSlopeBelowPeak, data.imbalanceSlopeAbovePeak);
    }

    /// @inheritdoc IECLPSurgeHook
    function setImbalanceSlopeBelowPeak(
        address pool,
        uint256 newImbalanceSlopeBelowPeak
    ) external onlySwapFeeManagerOrGovernance(pool) {
        _setImbalanceSlopeBelowPeak(pool, newImbalanceSlopeBelowPeak);
    }

    /// @inheritdoc IECLPSurgeHook
    function setImbalanceSlopeAbovePeak(
        address pool,
        uint256 newImbalanceSlopeAbovePeak
    ) external onlySwapFeeManagerOrGovernance(pool) {
        _setImbalanceSlopeAbovePeak(pool, newImbalanceSlopeAbovePeak);
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
        if (surgeFeeData.maxSurgeFeePercentage < staticSwapFeePercentage) {
            return (false, 0);
        }

        (
            IGyroECLPPool.EclpParams memory eclpParams,
            IGyroECLPPool.DerivedEclpParams memory derivedECLPParams
        ) = IGyroECLPPool(pool).getECLPParams();

        (uint256 amountCalculatedScaled18, int256 a, int256 b) = _computeSwap(
            params,
            eclpParams,
            derivedECLPParams
        );

        uint256[] memory newBalances = new uint256[](params.balancesScaled18.length);
        ScalingHelpers.copyToArray(params.balancesScaled18, newBalances);

        if (params.kind == SwapKind.EXACT_IN) {
            newBalances[params.indexIn] += params.amountGivenScaled18;
            newBalances[params.indexOut] -= amountCalculatedScaled18;
        } else {
            newBalances[params.indexIn] += amountCalculatedScaled18;
            newBalances[params.indexOut] -= params.amountGivenScaled18;
        }

        ImbalanceSlopeData memory imbalanceSlopeData = _imbalanceSlopePoolData[pool];

        uint256 oldTotalImbalance = _computeImbalance(
            params.balancesScaled18,
            eclpParams,
            a,
            b,
            imbalanceSlopeData
        );

        newTotalImbalance = _computeImbalance(newBalances, eclpParams, a, b, imbalanceSlopeData);
        isSurging = _isSurging(surgeFeeData.thresholdPercentage, oldTotalImbalance, newTotalImbalance);
    }

    /// @inheritdoc SurgeHookCommon
    function _isSurgingUnbalancedLiquidity(
        address pool,
        uint256[] memory oldBalancesScaled18,
        uint256[] memory balancesScaled18
    ) internal view override returns (bool isSurging) {
        ISurgeHookCommon.SurgeFeeData memory surgeFeeData = _surgeFeePoolData[pool];
        ImbalanceSlopeData memory imbalanceSlopeData = _imbalanceSlopePoolData[pool];

        (
            IGyroECLPPool.EclpParams memory eclpParams,
            IGyroECLPPool.DerivedEclpParams memory derivedECLPParams
        ) = IGyroECLPPool(pool).getECLPParams();

        (int256 a, int256 b) = GyroECLPMath.computeOffsetFromBalances(
            oldBalancesScaled18,
            eclpParams,
            derivedECLPParams
        );
        uint256 oldTotalImbalance = _computeImbalance(
            oldBalancesScaled18,
            eclpParams,
            a,
            b,
            imbalanceSlopeData
        );

        // Recompute offset for new balances (invariant changed)
        (a, b) = GyroECLPMath.computeOffsetFromBalances(balancesScaled18, eclpParams, derivedECLPParams);
        uint256 newTotalImbalance = _computeImbalance(
            balancesScaled18,
            eclpParams,
            a,
            b,
            imbalanceSlopeData
        );

        isSurging = _isSurging(surgeFeeData.thresholdPercentage, oldTotalImbalance, newTotalImbalance);
    }

    /* ========================================================================== */
    /*                              INTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Simulates E-CLP swap to get output amount and curve parameters.
     * @dev Mirrors E-CLP's onSwap but exposes a, b parameters for imbalance calculation.
     */
    function _computeSwap(
        PoolSwapParams memory request,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedECLPParams
    ) internal pure returns (uint256 amountCalculated, int256 a, int256 b) {
        bool tokenInIsToken0 = request.indexIn == 0;

        (int256 currentInvariant, int256 invErr) = GyroECLPMath.calculateInvariantWithError(
            request.balancesScaled18,
            eclpParams,
            derivedECLPParams
        );

        IGyroECLPPool.Vector2 memory invariant = IGyroECLPPool.Vector2(
            currentInvariant + 2 * invErr,
            currentInvariant
        );

        if (request.kind == SwapKind.EXACT_IN) {
            (amountCalculated, a, b) = GyroECLPMath.calcOutGivenIn(
                request.balancesScaled18,
                request.amountGivenScaled18,
                tokenInIsToken0,
                eclpParams,
                derivedECLPParams,
                invariant
            );
        } else {
            (amountCalculated, a, b) = GyroECLPMath.calcInGivenOut(
                request.balancesScaled18,
                request.amountGivenScaled18,
                tokenInIsToken0,
                eclpParams,
                derivedECLPParams,
                invariant
            );
        }
    }

    /**
     * @notice Computes pool imbalance based on distance from peak price.
     * @dev Imbalance ranges from 0 (at peak) to 1 (at price bounds).
     *
     * - currentPrice == peakPrice: imbalance = 0
     * - currentPrice < peakPrice: imbalance = belowSlope * (peak - current) / (peak - alpha)
     * - currentPrice > peakPrice: imbalance = aboveSlope * (current - peak) / (beta - peak)
     */
    function _computeImbalance(
        uint256[] memory balancesScaled18,
        IGyroECLPPool.EclpParams memory eclpParams,
        int256 a,
        int256 b,
        ImbalanceSlopeData memory imbalanceSlopeData
    ) internal pure returns (uint256 imbalance) {
        uint256 currentPrice = GyroECLPMath.computePrice(balancesScaled18, eclpParams, a, b);

        // Peak price = tan(rotation angle) = sin/cos
        uint256 peakPrice = eclpParams.s.divDownMag(eclpParams.c).toUint256();
        peakPrice = GyroECLPMath.clampPriceToPoolRange(peakPrice, eclpParams);

        if (currentPrice == peakPrice) {
            return 0;
        } else if (currentPrice < peakPrice) {
            imbalance =
                ((peakPrice - currentPrice) * imbalanceSlopeData.imbalanceSlopeBelowPeak) /
                (peakPrice - eclpParams.alpha.toUint256());
        } else {
            imbalance =
                ((currentPrice - peakPrice) * imbalanceSlopeData.imbalanceSlopeAbovePeak) /
                (eclpParams.beta.toUint256() - peakPrice);
        }

        return imbalance > FixedPoint.ONE ? FixedPoint.ONE : imbalance;
    }

    function _setImbalanceSlopeBelowPeak(address pool, uint256 newImbalanceSlopeBelowPeak) internal {
        _ensureValidImbalanceSlope(newImbalanceSlopeBelowPeak);
        uint128 newSlope = newImbalanceSlopeBelowPeak.toUint128();
        _imbalanceSlopePoolData[pool].imbalanceSlopeBelowPeak = newSlope;
        emit ImbalanceSlopeBelowPeakChanged(pool, newSlope);
    }

    function _setImbalanceSlopeAbovePeak(address pool, uint256 newImbalanceSlopeAbovePeak) internal {
        _ensureValidImbalanceSlope(newImbalanceSlopeAbovePeak);
        uint128 newSlope = newImbalanceSlopeAbovePeak.toUint128();
        _imbalanceSlopePoolData[pool].imbalanceSlopeAbovePeak = newSlope;
        emit ImbalanceSlopeAbovePeakChanged(pool, newSlope);
    }

    function _ensureValidImbalanceSlope(uint256 newImbalanceSlope) internal pure {
        if (newImbalanceSlope > MAX_IMBALANCE_SLOPE || newImbalanceSlope < MIN_IMBALANCE_SLOPE) {
            revert InvalidImbalanceSlope();
        }
    }
}
