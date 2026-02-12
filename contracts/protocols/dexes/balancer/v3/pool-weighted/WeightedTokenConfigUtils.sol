// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {TokenConfig} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol";

/**
 * @title WeightedTokenConfigUtils
 * @notice Utilities for sorting TokenConfig arrays alongside corresponding weights.
 * @dev Sorting tokens and weights together ensures the weight at index i always
 * corresponds to the token at index i after sorting by token address.
 */
library WeightedTokenConfigUtils {
    /**
     * @notice Thrown when tokenConfigs and weights arrays differ in length.
     * @param expected The expected length (tokenConfigs.length).
     * @param actual The actual length (weights.length).
     * @custom:signature LengthMismatch(uint256,uint256)
     * @custom:selector 0xab8b67c6
     */
    error LengthMismatch(uint256 expected, uint256 actual);

    /**
     * @notice Sort tokenConfigs by token address (ascending) and reorder weights to match.
     * @dev Uses bubble sort which is efficient for small arrays (typical pool size 2-8 tokens).
     * Both arrays must have the same length. Note that `sortedConfigs = tokenConfigs` assigns
     * the memory pointer, so the original array is sorted in-place.
     * @param tokenConfigs Array of token configurations to sort.
     * @param weights Array of normalized weights corresponding to each token.
     * @return sortedConfigs The sorted token configurations (same memory reference as input).
     * @return sortedWeights The weights reordered to match the sorted tokens (same memory reference as input).
     */
    function _sortWithWeights(TokenConfig[] memory tokenConfigs, uint256[] memory weights)
        internal
        pure
        returns (TokenConfig[] memory sortedConfigs, uint256[] memory sortedWeights)
    {
        if (tokenConfigs.length != weights.length) {
            revert LengthMismatch(tokenConfigs.length, weights.length);
        }

        // Assigns memory pointer — sorts the input arrays in-place
        sortedConfigs = tokenConfigs;
        sortedWeights = weights;

        bool swapped;
        for (uint256 i = 1; i < sortedConfigs.length; i++) {
            swapped = false;
            for (uint256 j = 0; j < sortedConfigs.length - i; j++) {
                if (sortedConfigs[j + 1].token < sortedConfigs[j].token) {
                    // Swap token configs
                    TokenConfig memory tempConfig = sortedConfigs[j];
                    sortedConfigs[j] = sortedConfigs[j + 1];
                    sortedConfigs[j + 1] = tempConfig;

                    // Swap weights in parallel
                    uint256 tempWeight = sortedWeights[j];
                    sortedWeights[j] = sortedWeights[j + 1];
                    sortedWeights[j + 1] = tempWeight;

                    swapped = true;
                }
            }
            if (!swapped) {
                return (sortedConfigs, sortedWeights);
            }
        }
        return (sortedConfigs, sortedWeights);
    }
}
