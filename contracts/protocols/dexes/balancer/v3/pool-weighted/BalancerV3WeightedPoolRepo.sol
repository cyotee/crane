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

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /**
     * @notice Initialize the weighted pool with normalized weights.
     * @dev Weights must sum to 1e18 (FixedPoint.ONE).
     * @param layoutStruct Storage pointer.
     * @param normalizedWeights_ Array of normalized weights (e.g., [0.8e18, 0.2e18] for 80/20 pool).
     */
    function _initialize(Storage storage layoutStruct, uint256[] memory normalizedWeights_) internal {
        // Require at least 2 weights to match pool usage (Finding 3 fix)
        if (normalizedWeights_.length < 2) revert InvalidWeightsLength();

        uint256 sum = 0;
        for (uint256 i = 0; i < normalizedWeights_.length; ++i) {
            // Reject zero weights (Finding 3 fix)
            if (normalizedWeights_[i] == 0) revert ZeroWeight();
            sum += normalizedWeights_[i];
        }
        if (sum != FixedPoint.ONE) revert WeightsMustSumToOne();

        layoutStruct.normalizedWeights = normalizedWeights_;
    }

    function _initialize(uint256[] memory normalizedWeights_) internal {
        _initialize(_layoutStruct(), normalizedWeights_);
    }

    /**
     * @notice Get the normalized weights of the pool tokens.
     * @param layoutStruct Storage pointer.
     * @return weights Array of normalized weights.
     */
    function _getNormalizedWeights(Storage storage layoutStruct) internal view returns (uint256[] memory weights) {
        weights = layoutStruct.normalizedWeights;
    }

    function _getNormalizedWeights() internal view returns (uint256[] memory weights) {
        return _getNormalizedWeights(_layoutStruct());
    }

    /**
     * @notice Get the normalized weight for a specific token index.
     * @param layoutStruct Storage pointer.
     * @param tokenIndex Index of the token.
     * @return weight Normalized weight of the token.
     */
    function _getNormalizedWeight(Storage storage layoutStruct, uint256 tokenIndex) internal view returns (uint256 weight) {
        return layoutStruct.normalizedWeights[tokenIndex];
    }

    function _getNormalizedWeight(uint256 tokenIndex) internal view returns (uint256 weight) {
        return _getNormalizedWeight(_layoutStruct(), tokenIndex);
    }

    /**
     * @notice Get the number of tokens in the pool.
     * @param layoutStruct Storage pointer.
     * @return count Number of tokens.
     */
    function _getNumTokens(Storage storage layoutStruct) internal view returns (uint256 count) {
        return layoutStruct.normalizedWeights.length;
    }

    function _getNumTokens() internal view returns (uint256 count) {
        return _getNumTokens(_layoutStruct());
    }
}
