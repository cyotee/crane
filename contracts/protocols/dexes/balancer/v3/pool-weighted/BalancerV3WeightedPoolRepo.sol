// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

// tag::BalancerV3WeightedPoolRepo[]
/**
 * @title BalancerV3WeightedPoolRepo - Storage library for Balancer V3 weighted pool normalized weights.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding normalized weights for Balancer V3 weighted pools.
 * @dev Provides dual (parameterized + default) overloads for _initialize and all getters.
 * @dev Weights are stored as fixed-point numbers that sum to FixedPoint.ONE (1e18).
 * @dev Follows the gold standard from BalancerV3VaultAwareRepo, OperableRepo, ERC20Repo, EIP712Repo, ERC2535Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by BalancerV3 weighted pool targets/facets/DFPkgs for Diamond storage binding of weights.
 */
library BalancerV3WeightedPoolRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.weighted"))) - 1).
     *      This follows the canonical pattern used by BalancerV3VaultAwareRepo, OperableRepo (crane.access.operable),
     *      ERC20Repo (eip.erc.20), ERC2535Repo (eip.erc.2535), MultiStepOwnableRepo and other gold-standard Repos
     *      for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.weighted"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for Balancer V3 weighted pool.
     *      normalizedWeights: array of weights (each FixedPoint, sum to ONE).
     */
    struct Storage {
        uint256[] normalizedWeights;
    }
    // end::Storage[]

    /// @notice The weights array does not sum to FixedPoint.ONE (1e18).
    error WeightsMustSumToOne();

    /// @notice The weights array length is invalid (must be >=2).
    error InvalidWeightsLength();

    /// @notice A weight value of zero is not allowed.
    error ZeroWeight();

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-uint256[]-memory)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param normalizedWeights_ Array of normalized weights (e.g., [0.8e18, 0.2e18] for 80/20 pool).
     *      Weights must sum to FixedPoint.ONE (1e18) and have length >= 2; zero weights disallowed.
     * @custom:throws InvalidWeightsLength
     * @custom:throws ZeroWeight
     * @custom:throws WeightsMustSumToOne
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

    // end::_initialize(Storage-uint256[]-memory)[]

    // tag::_initialize(uint256[]-memory)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param normalizedWeights_ Array of normalized weights (e.g., [0.8e18, 0.2e18] for 80/20 pool).
     * @custom:throws InvalidWeightsLength
     * @custom:throws ZeroWeight
     * @custom:throws WeightsMustSumToOne
     */
    function _initialize(uint256[] memory normalizedWeights_) internal {
        _initialize(_layoutStruct(), normalizedWeights_);
    }

    // end::_initialize(uint256[]-memory)[]

    // tag::_getNormalizedWeights(Storage)[]
    /**
     * @dev Argumented version of _getNormalizedWeights to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return weights Array of normalized weights.
     */
    function _getNormalizedWeights(Storage storage layoutStruct) internal view returns (uint256[] memory weights) {
        weights = layoutStruct.normalizedWeights;
    }

    // end::_getNormalizedWeights(Storage)[]

    // tag::_getNormalizedWeights()[]
    /**
     * @dev Default version of _getNormalizedWeights binding to the standard STORAGE_SLOT.
     * @return weights Array of normalized weights.
     */
    function _getNormalizedWeights() internal view returns (uint256[] memory weights) {
        return _getNormalizedWeights(_layoutStruct());
    }

    // end::_getNormalizedWeights()[]

    // tag::_getNormalizedWeight(Storage-uint256)[]
    /**
     * @dev Argumented version of _getNormalizedWeight to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenIndex Index of the token.
     * @return weight Normalized weight of the token.
     */
    function _getNormalizedWeight(Storage storage layoutStruct, uint256 tokenIndex)
        internal
        view
        returns (uint256 weight)
    {
        return layoutStruct.normalizedWeights[tokenIndex];
    }

    // end::_getNormalizedWeight(Storage-uint256)[]

    // tag::_getNormalizedWeight(uint256)[]
    /**
     * @dev Default version of _getNormalizedWeight binding to the standard STORAGE_SLOT.
     * @param tokenIndex Index of the token.
     * @return weight Normalized weight of the token.
     */
    function _getNormalizedWeight(uint256 tokenIndex) internal view returns (uint256 weight) {
        return _getNormalizedWeight(_layoutStruct(), tokenIndex);
    }

    // end::_getNormalizedWeight(uint256)[]

    // tag::_getNumTokens(Storage)[]
    /**
     * @dev Argumented version of _getNumTokens to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return count Number of tokens.
     */
    function _getNumTokens(Storage storage layoutStruct) internal view returns (uint256 count) {
        return layoutStruct.normalizedWeights.length;
    }

    // end::_getNumTokens(Storage)[]

    // tag::_getNumTokens()[]
    /**
     * @dev Default version of _getNumTokens binding to the standard STORAGE_SLOT.
     * @return count Number of tokens.
     */
    function _getNumTokens() internal view returns (uint256 count) {
        return _getNumTokens(_layoutStruct());
    }
    // end::_getNumTokens()[]
}
// end::BalancerV3WeightedPoolRepo[]
