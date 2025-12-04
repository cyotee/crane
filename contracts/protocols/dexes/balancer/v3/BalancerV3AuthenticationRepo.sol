// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

library BalancerV3AuthenticationRepo {
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.authentication");

    struct Storage {
        bytes32 actionIdDisambiguator;
        // uint256 minimumInvariantRatio;
        // uint256 maximumInvariantRatio;
        // uint256 minimumSwapFeePercentage;
        // uint256 maximumSwapFeePercentage;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(
        Storage storage layout,
        bytes32 actionIdDisambiguator
        // uint256 minimumInvariantRatio,
        // uint256 maximumInvariantRatio,
        // uint256 minimumSwapFeePercentage,
        // uint256 maximumSwapFeePercentage
    ) internal {
        layout.actionIdDisambiguator = actionIdDisambiguator;
        // layout.minimumInvariantRatio = minimumInvariantRatio;
        // layout.maximumInvariantRatio = maximumInvariantRatio;
        // layout.minimumSwapFeePercentage = minimumSwapFeePercentage;
        // layout.maximumSwapFeePercentage = maximumSwapFeePercentage;
    }

    function _initialize(
        bytes32 actionIdDisambiguator
        // uint256 minimumInvariantRatio,
        // uint256 maximumInvariantRatio,
        // uint256 minimumSwapFeePercentage,
        // uint256 maximumSwapFeePercentage
    ) internal {
        _initialize(
            _layout(),
            actionIdDisambiguator
            // minimumInvariantRatio,
            // maximumInvariantRatio,
            // minimumSwapFeePercentage,
            // maximumSwapFeePercentage
        );
    }

    function _actionIdDisambiguator(Storage storage layout) internal view returns (bytes32) {
        return layout.actionIdDisambiguator;
    }

    function _actionIdDisambiguator() internal view returns (bytes32) {
        return _actionIdDisambiguator(_layout());
    }

    // function _minimumInvariantRatio(Storage storage layout) internal view returns (uint256) {
    //     return layout.minimumInvariantRatio;
    // }

    // function _minimumInvariantRatio() internal view returns (uint256) {
    //     return _minimumInvariantRatio(_layout());
    // }

    // function _maximumInvariantRatio(Storage storage layout) internal view returns (uint256) {
    //     return layout.maximumInvariantRatio;
    // }

    // function _maximumInvariantRatio() internal view returns (uint256) {
    //     return _maximumInvariantRatio(_layout());
    // }

    // function _minimumSwapFeePercentage(Storage storage layout) internal view returns (uint256) {
    //     return layout.minimumSwapFeePercentage;
    // }

    // function _minimumSwapFeePercentage() internal view returns (uint256) {
    //     return _minimumSwapFeePercentage(_layout());
    // }

    // function _maximumSwapFeePercentage(Storage storage layout) internal view returns (uint256) {
    //     return layout.maximumSwapFeePercentage;
    // }

    // function _maximumSwapFeePercentage() internal view returns (uint256) {
    //     return _maximumSwapFeePercentage(_layout());
    // }

    function _getActionId(Storage storage layout, bytes4 selector) internal view returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        // return keccak256(abi.encodePacked(_actionIdDisambiguator(), selector));
        return abi.encodePacked(_actionIdDisambiguator(layout), selector)._hash();
    }

    function _getActionId(bytes4 selector) internal view returns (bytes32) {
        return _getActionId(_layout(), selector);
    }

}