// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IGyroECLPPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyroECLPPool.sol";

/**
 * @title IBalancerV3GyroECLPPool
 * @notice Crane-style interface for Balancer V3 Gyro ECLP pools.
 * @dev Exposes ECLP-specific functionality through the Diamond pattern.
 * ECLP (Elliptic Concentrated Liquidity Pool) uses ellipse curve math for
 * sophisticated price curves with parameters:
 * - alpha, beta: Price range bounds
 * - c, s: Rotation angle (cos/sin)
 * - lambda: Stretching factor
 * - Derived params: tauAlpha, tauBeta, u, v, w, z, dSq (38 decimals precision)
 *
 * @custom:interfaceid 0x41c5e491
 */
interface IBalancerV3GyroECLPPool {
    /**
     * @notice Get the ECLP parameters.
     * @return params The base ECLP parameters (alpha, beta, c, s, lambda).
     * @return derived The derived ECLP parameters (tauAlpha, tauBeta, u, v, w, z, dSq).
     */
    function getECLPParams()
        external
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived);

    /**
     * @notice Get the minimum swap fee percentage allowed.
     * @return The minimum swap fee percentage (1e12 = 0.000001%).
     */
    function getMinimumSwapFeePercentage() external pure returns (uint256);

    /**
     * @notice Get the maximum swap fee percentage allowed.
     * @return The maximum swap fee percentage (1e18 = 100%).
     */
    function getMaximumSwapFeePercentage() external pure returns (uint256);

    /**
     * @notice Get the minimum invariant ratio for unbalanced liquidity operations.
     * @return The minimum invariant ratio (60e16 = 60%).
     */
    function getMinimumInvariantRatio() external pure returns (uint256);

    /**
     * @notice Get the maximum invariant ratio for unbalanced liquidity operations.
     * @return The maximum invariant ratio (500e16 = 500%).
     */
    function getMaximumInvariantRatio() external pure returns (uint256);
}
