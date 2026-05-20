// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

library BalancerV3PoolRepo {
    using BetterEfficientHashLib for bytes;
    using AddressSetRepo for AddressSet;

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.common");

    struct Storage {
        // bytes32 actionIdDisambiguator;
        uint256 minimumInvariantRatio;
        uint256 maximumInvariantRatio;
        uint256 minimumSwapFeePercentage;
        uint256 maximumSwapFeePercentage;
        AddressSet tokens;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(
        Storage storage layoutStruct,
        // bytes32 actionIdDisambiguator,
        uint256 minimumInvariantRatio,
        uint256 maximumInvariantRatio,
        uint256 minimumSwapFeePercentage,
        uint256 maximumSwapFeePercentage,
        address[] memory tokens
    ) internal {
        // layoutStruct.actionIdDisambiguator = actionIdDisambiguator;
        layoutStruct.minimumInvariantRatio = minimumInvariantRatio;
        layoutStruct.maximumInvariantRatio = maximumInvariantRatio;
        layoutStruct.minimumSwapFeePercentage = minimumSwapFeePercentage;
        layoutStruct.maximumSwapFeePercentage = maximumSwapFeePercentage;
        layoutStruct.tokens._add(tokens);
    }

    function _initialize(
        // bytes32 actionIdDisambiguator,
        uint256 minimumInvariantRatio,
        uint256 maximumInvariantRatio,
        uint256 minimumSwapFeePercentage,
        uint256 maximumSwapFeePercentage,
        address[] memory tokens
    ) internal {
        _initialize(
            _layoutStruct(),
            // actionIdDisambiguator,
            minimumInvariantRatio,
            maximumInvariantRatio,
            minimumSwapFeePercentage,
            maximumSwapFeePercentage,
            tokens
        );
    }

    // function _actionIdDisambiguator(Storage storage layoutStruct) internal view returns (bytes32) {
    //     return layoutStruct.actionIdDisambiguator;
    // }

    // function _actionIdDisambiguator() internal view returns (bytes32) {
    //     return _actionIdDisambiguator(_layoutStruct());
    // }

    function _minimumInvariantRatio(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minimumInvariantRatio;
    }

    function _minimumInvariantRatio() internal view returns (uint256) {
        return _minimumInvariantRatio(_layoutStruct());
    }

    function _maximumInvariantRatio(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maximumInvariantRatio;
    }

    function _maximumInvariantRatio() internal view returns (uint256) {
        return _maximumInvariantRatio(_layoutStruct());
    }

    function _minimumSwapFeePercentage(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minimumSwapFeePercentage;
    }

    function _minimumSwapFeePercentage() internal view returns (uint256) {
        return _minimumSwapFeePercentage(_layoutStruct());
    }

    function _maximumSwapFeePercentage(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maximumSwapFeePercentage;
    }

    function _maximumSwapFeePercentage() internal view returns (uint256) {
        return _maximumSwapFeePercentage(_layoutStruct());
    }

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
