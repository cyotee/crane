// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

/**
 * @title BalancerV3WeightedPoolRepo
 * @notice Storage library for Balancer V3 weighted pool normalized weights.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 * Weights are stored as fixed-point numbers that sum to FixedPoint.ONE (1e18).
 */
library BalancerV3WeightedPoolRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.weighted");

    error WeightsMustSumToOne();
    error InvalidWeightsLength();
    error ZeroWeight();

    struct Storage {
        uint256[] normalizedWeights;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /**
     * @notice Initialize the weighted pool with normalized weights.
     * @dev Weights must sum to 1e18 (FixedPoint.ONE).
     * @param layout Storage pointer.
     * @param normalizedWeights_ Array of normalized weights (e.g., [0.8e18, 0.2e18] for 80/20 pool).
     */
    function _initialize(Storage storage layout, uint256[] memory normalizedWeights_) internal {
        // Require at least 2 weights to match pool usage (Finding 3 fix)
        if (normalizedWeights_.length < 2) revert InvalidWeightsLength();

        uint256 sum = 0;
        for (uint256 i = 0; i < normalizedWeights_.length; ++i) {
            // Reject zero weights (Finding 3 fix)
            if (normalizedWeights_[i] == 0) revert ZeroWeight();
            sum += normalizedWeights_[i];
        }
        if (sum != FixedPoint.ONE) revert WeightsMustSumToOne();

        layout.normalizedWeights = normalizedWeights_;
    }

    function _initialize(uint256[] memory normalizedWeights_) internal {
        _initialize(_layout(), normalizedWeights_);
    }

    /**
     * @notice Get the normalized weights of the pool tokens.
     * @param layout Storage pointer.
     * @return weights Array of normalized weights.
     */
    function _getNormalizedWeights(Storage storage layout) internal view returns (uint256[] memory weights) {
        weights = layout.normalizedWeights;
    }

    function _getNormalizedWeights() internal view returns (uint256[] memory weights) {
        return _getNormalizedWeights(_layout());
    }

    /**
     * @notice Get the normalized weight for a specific token index.
     * @param layout Storage pointer.
     * @param tokenIndex Index of the token.
     * @return weight Normalized weight of the token.
     */
    function _getNormalizedWeight(Storage storage layout, uint256 tokenIndex) internal view returns (uint256 weight) {
        return layout.normalizedWeights[tokenIndex];
    }

    function _getNormalizedWeight(uint256 tokenIndex) internal view returns (uint256 weight) {
        return _getNormalizedWeight(_layout(), tokenIndex);
    }

    /**
     * @notice Get the number of tokens in the pool.
     * @param layout Storage pointer.
     * @return count Number of tokens.
     */
    function _getNumTokens(Storage storage layout) internal view returns (uint256 count) {
        return layout.normalizedWeights.length;
    }

    function _getNumTokens() internal view returns (uint256 count) {
        return _getNumTokens(_layout());
    }
}
