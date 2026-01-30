// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IBalancerV3LBPool
 * @notice Interface for Liquidity Bootstrapping Pool (LBP) functionality in Crane framework.
 * @dev LBPs are weighted pools with time-based gradual weight transitions for token launches.
 *
 * Key features:
 * - Weights change linearly from start to end over the sale period
 * - Swaps only enabled during the sale period
 * - Optional blocking of project token sell-backs
 * - Optional seedless mode with virtual reserve balance
 *
 * @custom:interfaceid 0x9f8e3c1d (computed from function signatures)
 */
interface IBalancerV3LBPool {
    /**
     * @notice Get the current normalized weights of the pool tokens.
     * @dev Weights are interpolated between start and end weights based on time progress.
     * @return normalizedWeights Array of current normalized weights (sum to 1e18).
     * @custom:signature getNormalizedWeights()
     * @custom:selector 0xf89f27ed
     */
    function getNormalizedWeights() external view returns (uint256[] memory normalizedWeights);

    /**
     * @notice Get the gradual weight update parameters.
     * @return startTime Sale start timestamp.
     * @return endTime Sale end timestamp.
     * @return startWeights Array of starting weights [projectToken, reserveToken].
     * @return endWeights Array of ending weights [projectToken, reserveToken].
     * @custom:signature getGradualWeightUpdateParams()
     * @custom:selector 0x2954018c
     */
    function getGradualWeightUpdateParams()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        );

    /**
     * @notice Check if swaps are currently enabled.
     * @return True if current time is between startTime and endTime.
     * @custom:signature isSwapEnabled()
     * @custom:selector 0x627dd56a
     */
    function isSwapEnabled() external view returns (bool);

    /**
     * @notice Get the token indices.
     * @return projectTokenIndex Index of the project token (0 or 1).
     * @return reserveTokenIndex Index of the reserve token (0 or 1).
     * @custom:signature getTokenIndices()
     * @custom:selector 0x6a1db1bf
     */
    function getTokenIndices() external view returns (uint256 projectTokenIndex, uint256 reserveTokenIndex);

    /**
     * @notice Check if project token swaps in are blocked.
     * @return True if project token can only be bought, not sold back.
     * @custom:signature isProjectTokenSwapInBlocked()
     * @custom:selector 0x7c602bc2
     */
    function isProjectTokenSwapInBlocked() external view returns (bool);
}
