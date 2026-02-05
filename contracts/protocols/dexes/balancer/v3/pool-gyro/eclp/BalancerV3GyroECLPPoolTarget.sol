// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";

import {PoolSwapParams, Rounding, SwapKind} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IGyroECLPPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyroECLPPool.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {GyroECLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/GyroECLPMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3GyroECLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3GyroECLPPool.sol";
import {BalancerV3GyroECLPPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolRepo.sol";

/**
 * @title Balancer V3 Gyro ECLP Pool Target
 * @notice Implementation contract for Balancer V3 Gyro ECLP pool functionality.
 * @dev ECLP pools use elliptic curve math for concentrated liquidity with customizable
 * price curves. The curve is defined by an ellipse with:
 * - Price range [alpha, beta]
 * - Rotation angle phi (stored as cos/sin: c, s)
 * - Stretching factor lambda
 *
 * Pool parameters are stored in BalancerV3GyroECLPPoolRepo and must be initialized before use.
 */
contract BalancerV3GyroECLPPoolTarget is IBalancerV3Pool, IBalancerV3GyroECLPPool {
    using FixedPoint for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;

    /* -------------------------------------------------------------------------- */
    /*                               Invariant                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Computes and returns the pool's invariant using ECLP math.
     * @dev Uses the stored ECLP parameters to calculate the invariant via GyroECLPMath.
     * The invariant includes an error bound for precision tracking.
     * @param balancesLiveScaled18 Token balances after applying decimal scaling and rates.
     * @param rounding Rounding direction for the invariant calculation.
     * @return invariant The calculated invariant, scaled to 18 decimals.
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding rounding)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 invariant)
    {
        (IGyroECLPPool.EclpParams memory eclpParams, IGyroECLPPool.DerivedEclpParams memory derivedECLPParams) =
            BalancerV3GyroECLPPoolRepo._getECLPParams();

        (int256 currentInvariant, int256 invErr) =
            GyroECLPMath.calculateInvariantWithError(balancesLiveScaled18, eclpParams, derivedECLPParams);

        if (rounding == Rounding.ROUND_DOWN) {
            invariant = (currentInvariant - invErr).toUint256();
        } else {
            invariant = (currentInvariant + invErr).toUint256();
        }
    }

    /**
     * @notice Computes the new balance of a token after an operation.
     * @dev Uses ECLP math to solve for the new balance given an invariant ratio change.
     * @param balancesLiveScaled18 Current live balances, adjusted for rates.
     * @param tokenInIndex Index of the token to compute the balance for.
     * @param invariantRatio Ratio of the new invariant to the old.
     * @return newBalance The new balance of the selected token, scaled to 18 decimals.
     */
    function computeBalance(uint256[] memory balancesLiveScaled18, uint256 tokenInIndex, uint256 invariantRatio)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 newBalance)
    {
        (IGyroECLPPool.EclpParams memory eclpParams, IGyroECLPPool.DerivedEclpParams memory derivedECLPParams) =
            BalancerV3GyroECLPPoolRepo._getECLPParams();

        IGyroECLPPool.Vector2 memory invariant;
        {
            (int256 currentInvariant, int256 invErr) =
                GyroECLPMath.calculateInvariantWithError(balancesLiveScaled18, eclpParams, derivedECLPParams);

            // The invariant vector contains the rounded up and rounded down invariant.
            // Both are needed when computing the virtual offsets.
            invariant = IGyroECLPPool.Vector2(
                (currentInvariant + invErr).toUint256().mulUp(invariantRatio).toInt256(),
                (currentInvariant - invErr).toUint256().mulUp(invariantRatio).toInt256()
            );

            // Edge case check. Should never happen except for insane tokens.
            require(invariant.x <= GyroECLPMath._MAX_INVARIANT, GyroECLPMath.MaxInvariantExceeded());
        }

        int256 newBalanceInt;

        if (tokenInIndex == 0) {
            (newBalanceInt,,) =
                GyroECLPMath.calcXGivenY(balancesLiveScaled18[1].toInt256(), eclpParams, derivedECLPParams, invariant);
        } else {
            (newBalanceInt,,) =
                GyroECLPMath.calcYGivenX(balancesLiveScaled18[0].toInt256(), eclpParams, derivedECLPParams, invariant);
        }

        newBalance = newBalanceInt.toUint256();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Swaps                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Execute a swap in the pool using ECLP math.
     * @dev Uses the stored ECLP parameters for swap calculations.
     * @param params Swap parameters, including balancesScaled18 adjusted by rates.
     * @return amountCalculatedScaled18 Calculated amount for the swap in scaled 18-decimal format.
     */
    function onSwap(PoolSwapParams calldata params)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 amountCalculatedScaled18)
    {
        // The Vault already checks that index in != index out.
        bool tokenInIsToken0 = params.indexIn == 0;

        (IGyroECLPPool.EclpParams memory eclpParams, IGyroECLPPool.DerivedEclpParams memory derivedECLPParams) =
            BalancerV3GyroECLPPoolRepo._getECLPParams();

        IGyroECLPPool.Vector2 memory invariant;
        {
            (int256 currentInvariant, int256 invErr) =
                GyroECLPMath.calculateInvariantWithError(params.balancesScaled18, eclpParams, derivedECLPParams);
            // invariant = overestimate in x-component, underestimate in y-component
            invariant = IGyroECLPPool.Vector2(currentInvariant + 2 * invErr, currentInvariant);
        }

        if (params.kind == SwapKind.EXACT_IN) {
            (amountCalculatedScaled18,,) = GyroECLPMath.calcOutGivenIn(
                params.balancesScaled18, params.amountGivenScaled18, tokenInIsToken0, eclpParams, derivedECLPParams, invariant
            );
        } else {
            (amountCalculatedScaled18,,) = GyroECLPMath.calcInGivenOut(
                params.balancesScaled18, params.amountGivenScaled18, tokenInIsToken0, eclpParams, derivedECLPParams, invariant
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              ECLP Parameters                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the ECLP parameters.
     * @return params The base ECLP parameters (alpha, beta, c, s, lambda).
     * @return derived The derived ECLP parameters (tauAlpha, tauBeta, u, v, w, z, dSq).
     */
    function getECLPParams()
        public
        view
        virtual
        override(IBalancerV3GyroECLPPool)
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        return BalancerV3GyroECLPPoolRepo._getECLPParams();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Bounds                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the minimum swap fee percentage allowed.
     * @dev Liquidity Approximation tests show that add/remove liquidity combinations
     * are more profitable than a swap if the swap fee percentage is 0%.
     * @return The minimum swap fee percentage (1e12 = 0.000001%).
     */
    function getMinimumSwapFeePercentage() public pure virtual override(IBalancerV3GyroECLPPool) returns (uint256) {
        return 1e12; // 0.000001%
    }

    /**
     * @notice Get the maximum swap fee percentage allowed.
     * @return The maximum swap fee percentage (1e18 = 100%).
     */
    function getMaximumSwapFeePercentage() public pure virtual override(IBalancerV3GyroECLPPool) returns (uint256) {
        return 1e18; // 100%
    }

    /**
     * @notice Get the minimum invariant ratio for unbalanced liquidity operations.
     * @return The minimum invariant ratio (60e16 = 60%).
     */
    function getMinimumInvariantRatio() public pure virtual override(IBalancerV3GyroECLPPool) returns (uint256) {
        return GyroECLPMath.MIN_INVARIANT_RATIO;
    }

    /**
     * @notice Get the maximum invariant ratio for unbalanced liquidity operations.
     * @return The maximum invariant ratio (500e16 = 500%).
     */
    function getMaximumInvariantRatio() public pure virtual override(IBalancerV3GyroECLPPool) returns (uint256) {
        return GyroECLPMath.MAX_INVARIANT_RATIO;
    }
}
