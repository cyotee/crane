// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IBalancerV3WeightedPool
 * @notice Minimal interface for weighted pool functionality in Crane framework.
 * @dev Provides access to normalized weights for weighted pool math operations.
 * This interface is designed for use with the Diamond pattern and does not include
 * all functions from the full Balancer IWeightedPool interface.
 * @custom:interfaceid 0x7b02f714
 */
interface IBalancerV3WeightedPool {
    /**
     * @notice Get the normalized weights of the pool tokens.
     * @return normalizedWeights Array of normalized weights (sum to 1e18), sorted in token registration order.
     * @custom:signature getNormalizedWeights()
     * @custom:selector 0xf89f27ed
     */
    function getNormalizedWeights() external view returns (uint256[] memory normalizedWeights);
}
