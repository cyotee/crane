// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {IArbitrator} from "@crane/contracts/interfaces/IArbitrator.sol";

// tag::BountyBoardConfigRepo[]
/**
 * @title BountyBoardConfigRepo - Storage library for bounty board configuration (oracle, arbitrator).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for board-level config with dual overloads.
 * @dev Follows gold standard dual _layoutStruct + ERC1967 slot + NatSpec + tags.
 */
library BountyBoardConfigRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for bounty board config.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.bounties.board.config"))) - 1);

    // end::STORAGE_SLOT[]

    struct Config {
        address configOracle;
        address arbitratorOverride;
    }

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for BountyBoardConfigRepo.
     */
    struct Storage {
        Config config;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_setConfig(Storage-address-address)[]
    /**
     * @dev Argumented version of _setConfig to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param configOracle The config oracle address.
     * @param arbitratorOverride The arbitrator override address.
     */
    function _setConfig(Storage storage layoutStruct, address configOracle, address arbitratorOverride) internal {
        layoutStruct.config.configOracle = configOracle;
        layoutStruct.config.arbitratorOverride = arbitratorOverride;
    }

    // end::_setConfig(Storage-address-address)[]

    // tag::_setConfig(address-address)[]
    /**
     * @dev Default version of _setConfig binding to the standard STORAGE_SLOT.
     * @param configOracle The config oracle address.
     * @param arbitratorOverride The arbitrator override address.
     */
    function _setConfig(address configOracle, address arbitratorOverride) internal {
        _setConfig(_layoutStruct(), configOracle, arbitratorOverride);
    }

    // end::_setConfig(address-address)[]

    // tag::_getConfig(Storage)[]
    /**
     * @dev Argumented version of _getConfig to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return c The config memory copy.
     */
    function _getConfig(Storage storage layoutStruct) internal view returns (Config memory c) {
        c = layoutStruct.config;
    }

    // end::_getConfig(Storage)[]

    // tag::_getConfig()[]
    /**
     * @dev Default version of _getConfig binding to the standard STORAGE_SLOT.
     * @return c The config memory copy.
     */
    function _getConfig() internal view returns (Config memory c) {
        return _getConfig(_layoutStruct());
    }

    // end::_getConfig()[]

    // tag::_getConfigOracle(Storage)[]
    /**
     * @dev Argumented version of _getConfigOracle to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return The config oracle address.
     */
    function _getConfigOracle(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.config.configOracle;
    }

    // end::_getConfigOracle(Storage)[]

    // tag::_getConfigOracle()[]
    /**
     * @dev Default version of _getConfigOracle binding to the standard STORAGE_SLOT.
     * @return The config oracle address.
     */
    function _getConfigOracle() internal view returns (address) {
        return _getConfigOracle(_layoutStruct());
    }

    // end::_getConfigOracle()[]

    // tag::_getArbitratorOverride(Storage)[]
    /**
     * @dev Argumented version of _getArbitratorOverride to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return The arbitrator override address.
     */
    function _getArbitratorOverride(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.config.arbitratorOverride;
    }

    // end::_getArbitratorOverride(Storage)[]

    // tag::_getArbitratorOverride()[]
    /**
     * @dev Default version of _getArbitratorOverride binding to the standard STORAGE_SLOT.
     * @return The arbitrator override address.
     */
    function _getArbitratorOverride() internal view returns (address) {
        return _getArbitratorOverride(_layoutStruct());
    }

    // end::_getArbitratorOverride()[]

    // tag::_resolveArbitrator(Storage)[]
    /**
     * @dev Argumented version of _resolveArbitrator to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return arb The resolved arbitrator address (or 0).
     * @dev Priority: override > per-caller in oracle (for this proxy) > default in oracle.
     */
    function _resolveArbitrator(Storage storage layoutStruct) internal view returns (address arb) {
        arb = _getArbitratorOverride(layoutStruct);
        if (arb != address(0)) return arb;

        address oracle = _getConfigOracle(layoutStruct);
        if (oracle == address(0)) return address(0);

        bytes4 arbId = type(IArbitrator).interfaceId;
        // Prefer caller-specific for this board instance, fall back to default
        arb = ICallTargetRegistryQuery(oracle).callTargetForIDForCaller(arbId, address(this));
        if (arb == address(0)) {
            arb = ICallTargetRegistryQuery(oracle).defaultCallTargetForID(arbId);
        }
    }

    // end::_resolveArbitrator(Storage)[]

    // tag::_resolveArbitrator()[]
    /**
     * @dev Default version of _resolveArbitrator binding to the standard STORAGE_SLOT.
     * @return arb The resolved arbitrator address (or 0).
     */
    function _resolveArbitrator() internal view returns (address arb) {
        return _resolveArbitrator(_layoutStruct());
    }

    // end::_resolveArbitrator()[]
}
// end::BountyBoardConfigRepo[]
