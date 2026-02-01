// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IBalancerV3Gyro2CLPPool
 * @notice Crane-style interface for Balancer V3 Gyro 2-CLP pools.
 * @dev Exposes 2-CLP-specific functionality through the Diamond pattern.
 * 2-CLP (2-asset Concentrated Liquidity Pool) uses simpler concentrated
 * liquidity with parameters:
 * - sqrtAlpha: Square root of the lower price bound
 * - sqrtBeta: Square root of the upper price bound
 *
 * The invariant is L^2 = (x + a)(y + b) where:
 * - a = L / sqrtBeta
 * - b = L * sqrtAlpha
 *
 * @custom:interfaceid 0xc9a772b7
 */
interface IBalancerV3Gyro2CLPPool {
    /// @notice The informed sqrtAlpha is greater than or equal to sqrtBeta.
    error SqrtParamsWrong();

    /**
     * @notice Get the 2-CLP parameters.
     * @return sqrtAlpha Square root of alpha (lower price bound).
     * @return sqrtBeta Square root of beta (upper price bound).
     */
    function get2CLPParams() external view returns (uint256 sqrtAlpha, uint256 sqrtBeta);

    /**
     * @notice Get the minimum swap fee percentage allowed.
     * @return The minimum swap fee percentage (1e12 = 0.0001%).
     */
    function getMinimumSwapFeePercentage() external pure returns (uint256);

    /**
     * @notice Get the maximum swap fee percentage allowed.
     * @return The maximum swap fee percentage (1e18 = 100%).
     */
    function getMaximumSwapFeePercentage() external pure returns (uint256);

    /**
     * @notice Get the minimum invariant ratio for unbalanced liquidity operations.
     * @return The minimum invariant ratio (0 for 2-CLP).
     */
    function getMinimumInvariantRatio() external pure returns (uint256);

    /**
     * @notice Get the maximum invariant ratio for unbalanced liquidity operations.
     * @return The maximum invariant ratio (type(uint256).max for 2-CLP).
     */
    function getMaximumInvariantRatio() external pure returns (uint256);
}
