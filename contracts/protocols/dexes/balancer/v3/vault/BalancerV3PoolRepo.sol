// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

// tag::BalancerV3PoolRepo[]
/**
 * @title BalancerV3PoolRepo - Storage library for Balancer V3 common pool configuration and state.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for Balancer V3 pool common fields (invariant ratios, swap fee bounds, token set).
 * @dev Provides dual (parameterized + default) overloads for _initialize and all storage getters.
 * @dev Follows the gold standard from BalancerV3VaultAwareRepo, OperableRepo, ERC2535Repo, DeployedAddressesRepo, EIP712Repo, ERC20Repo, ERC4626Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by Balancer V3 pool related Targets, Facets, and services for Diamond storage binding.
 */
library BalancerV3PoolRepo {
    using BetterEfficientHashLib for bytes;
    using AddressSetRepo for AddressSet;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.common"))) - 1).
     *      This follows the canonical pattern used by BalancerV3VaultAwareRepo, OperableRepo, ERC2535Repo,
     *      MultiStepOwnableRepo, DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.pool.common"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for balancer v3 pool common.
     *      minimumInvariantRatio: lower bound for invariant ratio after swaps/joins/exits.
     *      maximumInvariantRatio: upper bound for invariant ratio.
     *      minimumSwapFeePercentage: lower bound for swap fee percentage.
     *      maximumSwapFeePercentage: upper bound for swap fee percentage.
     *      tokens: AddressSet of the pool's token addresses (populated via AddressSetRepo).
     */
    struct Storage {
        // bytes32 actionIdDisambiguator;
        uint256 minimumInvariantRatio;
        uint256 maximumInvariantRatio;
        uint256 minimumSwapFeePercentage;
        uint256 maximumSwapFeePercentage;
        AddressSet tokens;
    }
    // end::Storage[]

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

    // tag::_initialize(Storage-uint256-uint256-uint256-uint256-address[]-memory)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param minimumInvariantRatio_ The minimum invariant ratio.
     * @param maximumInvariantRatio_ The maximum invariant ratio.
     * @param minimumSwapFeePercentage_ The minimum swap fee percentage.
     * @param maximumSwapFeePercentage_ The maximum swap fee percentage.
     * @param tokens_ The initial list of token addresses for the pool.
     */
    function _initialize(
        Storage storage layoutStruct,
        // bytes32 actionIdDisambiguator,
        uint256 minimumInvariantRatio_,
        uint256 maximumInvariantRatio_,
        uint256 minimumSwapFeePercentage_,
        uint256 maximumSwapFeePercentage_,
        address[] memory tokens_
    ) internal {
        // layoutStruct.actionIdDisambiguator = actionIdDisambiguator;
        layoutStruct.minimumInvariantRatio = minimumInvariantRatio_;
        layoutStruct.maximumInvariantRatio = maximumInvariantRatio_;
        layoutStruct.minimumSwapFeePercentage = minimumSwapFeePercentage_;
        layoutStruct.maximumSwapFeePercentage = maximumSwapFeePercentage_;
        layoutStruct.tokens._add(tokens_);
    }
    // end::_initialize(Storage-uint256-uint256-uint256-uint256-address[]-memory)[]

    // tag::_initialize(uint256-uint256-uint256-uint256-address[]-memory)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param minimumInvariantRatio_ The minimum invariant ratio.
     * @param maximumInvariantRatio_ The maximum invariant ratio.
     * @param minimumSwapFeePercentage_ The minimum swap fee percentage.
     * @param maximumSwapFeePercentage_ The maximum swap fee percentage.
     * @param tokens_ The initial list of token addresses for the pool.
     */
    function _initialize(
        // bytes32 actionIdDisambiguator,
        uint256 minimumInvariantRatio_,
        uint256 maximumInvariantRatio_,
        uint256 minimumSwapFeePercentage_,
        uint256 maximumSwapFeePercentage_,
        address[] memory tokens_
    ) internal {
        _initialize(
            _layoutStruct(),
            // actionIdDisambiguator,
            minimumInvariantRatio_,
            maximumInvariantRatio_,
            minimumSwapFeePercentage_,
            maximumSwapFeePercentage_,
            tokens_
        );
    }
    // end::_initialize(uint256-uint256-uint256-uint256-address[]-memory)[]

    // tag::_minimumInvariantRatio(Storage)[]
    /**
     * @dev Argumented version of _minimumInvariantRatio to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The minimum invariant ratio.
     */
    function _minimumInvariantRatio(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minimumInvariantRatio;
    }
    // end::_minimumInvariantRatio(Storage)[]

    // tag::_minimumInvariantRatio()[]
    /**
     * @dev Default version of _minimumInvariantRatio binding to the standard STORAGE_SLOT.
     * @return The minimum invariant ratio.
     */
    function _minimumInvariantRatio() internal view returns (uint256) {
        return _minimumInvariantRatio(_layoutStruct());
    }
    // end::_minimumInvariantRatio()[]

    // tag::_maximumInvariantRatio(Storage)[]
    /**
     * @dev Argumented version of _maximumInvariantRatio to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The maximum invariant ratio.
     */
    function _maximumInvariantRatio(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maximumInvariantRatio;
    }
    // end::_maximumInvariantRatio(Storage)[]

    // tag::_maximumInvariantRatio()[]
    /**
     * @dev Default version of _maximumInvariantRatio binding to the standard STORAGE_SLOT.
     * @return The maximum invariant ratio.
     */
    function _maximumInvariantRatio() internal view returns (uint256) {
        return _maximumInvariantRatio(_layoutStruct());
    }
    // end::_maximumInvariantRatio()[]

    // tag::_minimumSwapFeePercentage(Storage)[]
    /**
     * @dev Argumented version of _minimumSwapFeePercentage to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The minimum swap fee percentage.
     */
    function _minimumSwapFeePercentage(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minimumSwapFeePercentage;
    }
    // end::_minimumSwapFeePercentage(Storage)[]

    // tag::_minimumSwapFeePercentage()[]
    /**
     * @dev Default version of _minimumSwapFeePercentage binding to the standard STORAGE_SLOT.
     * @return The minimum swap fee percentage.
     */
    function _minimumSwapFeePercentage() internal view returns (uint256) {
        return _minimumSwapFeePercentage(_layoutStruct());
    }
    // end::_minimumSwapFeePercentage()[]

    // tag::_maximumSwapFeePercentage(Storage)[]
    /**
     * @dev Argumented version of _maximumSwapFeePercentage to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The maximum swap fee percentage.
     */
    function _maximumSwapFeePercentage(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maximumSwapFeePercentage;
    }
    // end::_maximumSwapFeePercentage(Storage)[]

    // tag::_maximumSwapFeePercentage()[]
    /**
     * @dev Default version of _maximumSwapFeePercentage binding to the standard STORAGE_SLOT.
     * @return The maximum swap fee percentage.
     */
    function _maximumSwapFeePercentage() internal view returns (uint256) {
        return _maximumSwapFeePercentage(_layoutStruct());
    }
    // end::_maximumSwapFeePercentage()[]

    // function _actionIdDisambiguator(Storage storage layoutStruct) internal view returns (bytes32) {
    //     return layoutStruct.actionIdDisambiguator;
    // }

    // function _actionIdDisambiguator() internal view returns (bytes32) {
    //     return _actionIdDisambiguator(_layoutStruct());
    // }

    // function _getActionId(Storage storage layoutStruct, bytes4 selector) internal view returns (bytes32) {
    //     // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
    //     // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
    //     // multiple contracts.
    //     // return keccak256(abi.encodePacked(_actionIdDisambiguator(), selector));
    //     return abi.encodePacked(_actionIdDisambiguator(layoutStruct), selector)._hash();
    // }

    // function _getActionId(bytes4 selector) internal view returns (bytes32) {
    //     return _getActionId(_layoutStruct(), selector);
    // }
}
// end::BalancerV3PoolRepo[]
