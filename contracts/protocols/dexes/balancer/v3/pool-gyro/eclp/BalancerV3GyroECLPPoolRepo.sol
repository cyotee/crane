// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IGyroECLPPool} from "@balancer-labs/v3-interfaces/contracts/pool-gyro/IGyroECLPPool.sol";

/**
 * @title BalancerV3GyroECLPPoolRepo
 * @notice Storage library for Balancer V3 Gyro ECLP pool parameters.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 *
 * ECLP pools require complex elliptic curve parameters:
 * - Base params (18 decimals): alpha, beta, c, s, lambda
 * - Derived params (38 decimals): tauAlpha, tauBeta, u, v, w, z, dSq
 *
 * The derived parameters are calculated off-chain for gas efficiency and
 * higher precision. They must satisfy validation constraints in GyroECLPMath.
 */
library BalancerV3GyroECLPPoolRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.gyro.eclp");

    /**
     * @notice Storage layout for ECLP pool parameters.
     * @dev Parameters are stored as signed integers because intermediate
     * calculations in GyroECLPMath can produce negative values.
     *
     * Base parameters (18 decimals):
     * - alpha: Lower price limit (alpha > 0)
     * - beta: Upper price limit (beta > alpha > 0)
     * - c: cos(-phi) where phi is the rotation angle
     * - s: sin(-phi) where phi is the rotation angle
     * - lambda: Stretching factor (lambda >= 1)
     *
     * Derived parameters (38 decimals for higher precision):
     * - tauAlpha, tauBeta: Points on the unit circle
     * - u, v: Components of (A chi)_y = lambda * u + v
     * - w, z: Components of (A chi)_x = w / lambda + z
     * - dSq: Error correction term for c^2 + s^2 = dSq
     */
    struct Storage {
        // Base ECLP parameters (18 decimals)
        int256 paramsAlpha;
        int256 paramsBeta;
        int256 paramsC;
        int256 paramsS;
        int256 paramsLambda;
        // Derived ECLP parameters (38 decimals)
        int256 tauAlphaX;
        int256 tauAlphaY;
        int256 tauBetaX;
        int256 tauBetaY;
        int256 u;
        int256 v;
        int256 w;
        int256 z;
        int256 dSq;
    }

    /* ------ Layout Functions ------ */

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the ECLP pool with parameters.
     * @dev Parameters should be validated using GyroECLPMath.validateParams()
     * and GyroECLPMath.validateDerivedParamsLimits() before calling this.
     * @param layout Storage pointer.
     * @param eclpParams Base ECLP parameters (alpha, beta, c, s, lambda).
     * @param derivedEclpParams Derived ECLP parameters (tauAlpha, tauBeta, u, v, w, z, dSq).
     */
    function _initialize(
        Storage storage layout,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams
    ) internal {
        // Store base parameters
        layout.paramsAlpha = eclpParams.alpha;
        layout.paramsBeta = eclpParams.beta;
        layout.paramsC = eclpParams.c;
        layout.paramsS = eclpParams.s;
        layout.paramsLambda = eclpParams.lambda;

        // Store derived parameters
        layout.tauAlphaX = derivedEclpParams.tauAlpha.x;
        layout.tauAlphaY = derivedEclpParams.tauAlpha.y;
        layout.tauBetaX = derivedEclpParams.tauBeta.x;
        layout.tauBetaY = derivedEclpParams.tauBeta.y;
        layout.u = derivedEclpParams.u;
        layout.v = derivedEclpParams.v;
        layout.w = derivedEclpParams.w;
        layout.z = derivedEclpParams.z;
        layout.dSq = derivedEclpParams.dSq;
    }

    function _initialize(
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams
    ) internal {
        _initialize(_layout(), eclpParams, derivedEclpParams);
    }

    /* ------ Parameter Getters ------ */

    /**
     * @notice Get the ECLP parameters reconstructed as structs.
     * @param layout Storage pointer.
     * @return params The base ECLP parameters.
     * @return derived The derived ECLP parameters.
     */
    function _getECLPParams(Storage storage layout)
        internal
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        // Reconstruct base params
        params.alpha = layout.paramsAlpha;
        params.beta = layout.paramsBeta;
        params.c = layout.paramsC;
        params.s = layout.paramsS;
        params.lambda = layout.paramsLambda;

        // Reconstruct derived params
        derived.tauAlpha.x = layout.tauAlphaX;
        derived.tauAlpha.y = layout.tauAlphaY;
        derived.tauBeta.x = layout.tauBetaX;
        derived.tauBeta.y = layout.tauBetaY;
        derived.u = layout.u;
        derived.v = layout.v;
        derived.w = layout.w;
        derived.z = layout.z;
        derived.dSq = layout.dSq;
    }

    function _getECLPParams()
        internal
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        return _getECLPParams(_layout());
    }

    /* ------ Individual Parameter Getters ------ */

    /**
     * @notice Get the alpha parameter (lower price limit).
     * @param layout Storage pointer.
     * @return The alpha parameter.
     */
    function _getAlpha(Storage storage layout) internal view returns (int256) {
        return layout.paramsAlpha;
    }

    function _getAlpha() internal view returns (int256) {
        return _getAlpha(_layout());
    }

    /**
     * @notice Get the beta parameter (upper price limit).
     * @param layout Storage pointer.
     * @return The beta parameter.
     */
    function _getBeta(Storage storage layout) internal view returns (int256) {
        return layout.paramsBeta;
    }

    function _getBeta() internal view returns (int256) {
        return _getBeta(_layout());
    }

    /**
     * @notice Get the lambda parameter (stretching factor).
     * @param layout Storage pointer.
     * @return The lambda parameter.
     */
    function _getLambda(Storage storage layout) internal view returns (int256) {
        return layout.paramsLambda;
    }

    function _getLambda() internal view returns (int256) {
        return _getLambda(_layout());
    }
}
