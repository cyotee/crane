// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IGyroECLPPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyroECLPPool.sol";

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
     * @notice Storage layoutStruct for ECLP pool parameters.
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

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the ECLP pool with parameters.
     * @dev Parameters should be validated using GyroECLPMath.validateParams()
     * and GyroECLPMath.validateDerivedParamsLimits() before calling this.
     * @param layoutStruct Storage pointer.
     * @param eclpParams Base ECLP parameters (alpha, beta, c, s, lambda).
     * @param derivedEclpParams Derived ECLP parameters (tauAlpha, tauBeta, u, v, w, z, dSq).
     */
    function _initialize(
        Storage storage layoutStruct,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams
    ) internal {
        // Store base parameters
        layoutStruct.paramsAlpha = eclpParams.alpha;
        layoutStruct.paramsBeta = eclpParams.beta;
        layoutStruct.paramsC = eclpParams.c;
        layoutStruct.paramsS = eclpParams.s;
        layoutStruct.paramsLambda = eclpParams.lambda;

        // Store derived parameters
        layoutStruct.tauAlphaX = derivedEclpParams.tauAlpha.x;
        layoutStruct.tauAlphaY = derivedEclpParams.tauAlpha.y;
        layoutStruct.tauBetaX = derivedEclpParams.tauBeta.x;
        layoutStruct.tauBetaY = derivedEclpParams.tauBeta.y;
        layoutStruct.u = derivedEclpParams.u;
        layoutStruct.v = derivedEclpParams.v;
        layoutStruct.w = derivedEclpParams.w;
        layoutStruct.z = derivedEclpParams.z;
        layoutStruct.dSq = derivedEclpParams.dSq;
    }

    function _initialize(
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams
    ) internal {
        _initialize(_layoutStruct(), eclpParams, derivedEclpParams);
    }

    /* ------ Parameter Getters ------ */

    /**
     * @notice Get the ECLP parameters reconstructed as structs.
     * @param layoutStruct Storage pointer.
     * @return params The base ECLP parameters.
     * @return derived The derived ECLP parameters.
     */
    function _getECLPParams(Storage storage layoutStruct)
        internal
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        // Reconstruct base params
        params.alpha = layoutStruct.paramsAlpha;
        params.beta = layoutStruct.paramsBeta;
        params.c = layoutStruct.paramsC;
        params.s = layoutStruct.paramsS;
        params.lambda = layoutStruct.paramsLambda;

        // Reconstruct derived params
        derived.tauAlpha.x = layoutStruct.tauAlphaX;
        derived.tauAlpha.y = layoutStruct.tauAlphaY;
        derived.tauBeta.x = layoutStruct.tauBetaX;
        derived.tauBeta.y = layoutStruct.tauBetaY;
        derived.u = layoutStruct.u;
        derived.v = layoutStruct.v;
        derived.w = layoutStruct.w;
        derived.z = layoutStruct.z;
        derived.dSq = layoutStruct.dSq;
    }

    function _getECLPParams()
        internal
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        return _getECLPParams(_layoutStruct());
    }

    /* ------ Individual Parameter Getters ------ */

    /**
     * @notice Get the alpha parameter (lower price limit).
     * @param layoutStruct Storage pointer.
     * @return The alpha parameter.
     */
    function _getAlpha(Storage storage layoutStruct) internal view returns (int256) {
        return layoutStruct.paramsAlpha;
    }

    function _getAlpha() internal view returns (int256) {
        return _getAlpha(_layoutStruct());
    }

    /**
     * @notice Get the beta parameter (upper price limit).
     * @param layoutStruct Storage pointer.
     * @return The beta parameter.
     */
    function _getBeta(Storage storage layoutStruct) internal view returns (int256) {
        return layoutStruct.paramsBeta;
    }

    function _getBeta() internal view returns (int256) {
        return _getBeta(_layoutStruct());
    }

    /**
     * @notice Get the lambda parameter (stretching factor).
     * @param layoutStruct Storage pointer.
     * @return The lambda parameter.
     */
    function _getLambda(Storage storage layoutStruct) internal view returns (int256) {
        return layoutStruct.paramsLambda;
    }

    function _getLambda() internal view returns (int256) {
        return _getLambda(_layoutStruct());
    }
}
