// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::CallTargetRegistryRepo[]
/**
 * @title CallTargetRegistryRepo - Storage library for the Call Target Registry.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for registering and querying call targets (default and per-caller)
 *      keyed by interface ID. Implements dual (parameterized + default) functions for all
 *      accessors and mutators, following the Facet-Target-Repo pattern.
 * @dev Used by CallTargetRegistryManagementTarget / CallTargetRegistryQueryTarget and corresponding Facets.
 */
library CallTargetRegistryRepo {
    // tag::DEFAULT_SLOT[]
    /**
     * @dev Standardized storage slot for Call Target Registry data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant DEFAULT_SLOT =
        bytes32(uint256(keccak256(abi.encode("crane.registries.calltargets"))) - 1);

    // end::DEFAULT_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for call target registry state.
     */
    struct Storage {
        // Default call target for a given interface ID (when no per-caller override).
        mapping(bytes4 interfaceId => address callTarget) defaultCallTargetForID;
        // Per-caller override call target for a given interface ID.
        mapping(bytes4 interfaceId => mapping(address caller => address callTarget)) callTargetForIDForCaller;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct_ The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard DEFAULT_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(DEFAULT_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_defaultCallTargetForID(Storage-bytes4)[]
    /**
     * @dev Argumented version of _defaultCallTargetForID to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up the default call target for.
     * @return callTarget_ The registered call target for the interface (or zero if none).
     */
    function _defaultCallTargetForID(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (address callTarget_)
    {
        return layoutStruct.defaultCallTargetForID[interfaceId];
    }

    // end::_defaultCallTargetForID(Storage-bytes4)[]

    // tag::_defaultCallTargetForID(bytes4)[]
    /**
     * @dev Default version of _defaultCallTargetForID binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up the default call target for.
     * @return callTarget_ The registered call target for the interface (or zero if none).
     */
    function _defaultCallTargetForID(bytes4 interfaceId) internal view returns (address callTarget_) {
        return _defaultCallTargetForID(_layoutStruct(), interfaceId);
    }

    // end::_defaultCallTargetForID(bytes4)[]

    // tag::_setDefaultCallTargetForID(Storage-bytes4-address)[]
    /**
     * @dev Argumented version of _setDefaultCallTargetForID to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID for which to set the default call target.
     * @param callTarget The call target address to register (zero clears).
     */
    function _setDefaultCallTargetForID(Storage storage layoutStruct, bytes4 interfaceId, address callTarget) internal {
        layoutStruct.defaultCallTargetForID[interfaceId] = callTarget;
    }

    // end::_setDefaultCallTargetForID(Storage-bytes4-address)[]

    // tag::_setDefaultCallTargetForID(bytes4-address)[]
    /**
     * @dev Default version of _setDefaultCallTargetForID binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID for which to set the default call target.
     * @param callTarget The call target address to register (zero clears).
     */
    function _setDefaultCallTargetForID(bytes4 interfaceId, address callTarget) internal {
        _setDefaultCallTargetForID(_layoutStruct(), interfaceId, callTarget);
    }

    // end::_setDefaultCallTargetForID(bytes4-address)[]

    // tag::_callTargetForIDForCaller(Storage-bytes4-address)[]
    /**
     * @dev Argumented version of _callTargetForIDForCaller to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up the per-caller call target for.
     * @param caller The caller address for the per-caller override lookup.
     * @return callTarget_ The registered call target for the interface+caller (or zero if none).
     */
    function _callTargetForIDForCaller(Storage storage layoutStruct, bytes4 interfaceId, address caller)
        internal
        view
        returns (address callTarget_)
    {
        return layoutStruct.callTargetForIDForCaller[interfaceId][caller];
    }

    // end::_callTargetForIDForCaller(Storage-bytes4-address)[]

    // tag::_callTargetForIDForCaller(bytes4-address)[]
    /**
     * @dev Default version of _callTargetForIDForCaller binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up the per-caller call target for.
     * @param caller The caller address for the per-caller override lookup.
     * @return callTarget_ The registered call target for the interface+caller (or zero if none).
     */
    function _callTargetForIDForCaller(bytes4 interfaceId, address caller) internal view returns (address callTarget_) {
        return _callTargetForIDForCaller(_layoutStruct(), interfaceId, caller);
    }

    // end::_callTargetForIDForCaller(bytes4-address)[]

    // tag::_setCallTargetForIDForCaller(Storage-bytes4-address-address)[]
    /**
     * @dev Argumented version of _setCallTargetForIDForCaller to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID for which to set the per-caller call target.
     * @param caller The caller address for which the override applies.
     * @param callTarget The call target address to register for this caller (zero clears).
     */
    function _setCallTargetForIDForCaller(
        Storage storage layoutStruct,
        bytes4 interfaceId,
        address caller,
        address callTarget
    ) internal {
        layoutStruct.callTargetForIDForCaller[interfaceId][caller] = callTarget;
    }

    // end::_setCallTargetForIDForCaller(Storage-bytes4-address-address)[]

    // tag::_setCallTargetForIDForCaller(bytes4-address-address)[]
    /**
     * @dev Default version of _setCallTargetForIDForCaller binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID for which to set the per-caller call target.
     * @param caller The caller address for which the override applies.
     * @param callTarget The call target address to register for this caller (zero clears).
     */
    function _setCallTargetForIDForCaller(bytes4 interfaceId, address caller, address callTarget) internal {
        _setCallTargetForIDForCaller(_layoutStruct(), interfaceId, caller, callTarget);
    }

    // end::_setCallTargetForIDForCaller(bytes4-address-address)[]
}

// end::CallTargetRegistryRepo[]
