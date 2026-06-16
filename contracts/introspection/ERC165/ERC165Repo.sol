// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// tag::ERC165Repo[]
/**
 * @title ERC165Repo - Repository library for ERC165 relevant state.
 * @author cyotee doge <doge.cyotee>
 * @dev Storage library (Repo) implementing interface support registry for IERC165.
 * @dev Provides dual (parameterized + default) overloads for all storage accessors and mutators.
 * @dev This is a low-level storage library that intentionally does NOT enforce ERC-165
 * strict semantics (i.e., rejecting 0xffffffff). The ERC-165 specification reserves
 * 0xffffffff as an invalid interface ID that must always return false from supportsInterface().
 *
 * This Repo is designed as a generic mapping to allow flexibility:
 * - Higher-level Targets or Facets should enforce ERC-165 compliance by checking
 *   `interfaceId != 0xffffffff` in their supportsInterface() implementations.
 * - The ERC165Target/ERC165Facet implementations handle this constraint.
 *
 * If 0xffffffff is registered via _registerInterface(), _supportsInterface() will return true,
 * which violates ERC-165. Callers are responsible for preventing this at the appropriate layer.
 */
library ERC165Repo {
    // tag::ERC165_STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for ERC-165 (introspection) data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant ERC165_STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.165"))) - 1);

    // end::ERC165_STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-165 interface support flags.
     */
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        mapping(bytes4 interfaceId => bool isSupportedInterface) isSupportedInterface;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param storageSlot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 storageSlot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := storageSlot
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard ERC165_STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(ERC165_STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_registerInterface(Storage-bytes4)[]
    /**
     * @dev Argumented version of _registerInterface to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The ERC165 interface ID to register as supported.
     */
    function _registerInterface(Storage storage layoutStruct, bytes4 interfaceId) internal {
        layoutStruct.isSupportedInterface[interfaceId] = true;
    }

    // end::_registerInterface(Storage-bytes4)[]

    // tag::_registerInterface(bytes4)[]
    /**
     * @dev Default version of _registerInterface binding to the standard ERC165_STORAGE_SLOT.
     * @param interfaceId The ERC165 interface ID to register as supported.
     */
    function _registerInterface(bytes4 interfaceId) internal {
        _registerInterface(_layoutStruct(), interfaceId);
    }

    // end::_registerInterface(bytes4)[]

    // tag::_registerInterfaces(Storage-bytes4[])[]
    /**
     * @dev Argumented version of _registerInterfaces to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceIds The array of ERC165 interface IDs to register as supported.
     */
    function _registerInterfaces(Storage storage layoutStruct, bytes4[] memory interfaceIds) internal {
        for (uint256 cursor = 0; cursor < interfaceIds.length; cursor++) {
            _registerInterface(layoutStruct, interfaceIds[cursor]);
        }
    }

    // end::_registerInterfaces(Storage-bytes4[])[]

    // tag::_registerInterfaces(bytes4[])[]
    /**
     * @dev Default version of _registerInterfaces binding to the standard ERC165_STORAGE_SLOT.
     * @param interfaceIds The array of ERC165 interface IDs to register as supported.
     */
    function _registerInterfaces(bytes4[] memory interfaceIds) internal {
        _registerInterfaces(_layoutStruct(), interfaceIds);
    }

    // end::_registerInterfaces(bytes4[])[]

    // tag::_supportsInterface(Storage-bytes4)[]
    /**
     * @dev Argumented version of _supportsInterface to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The ERC165 interface ID to query.
     * @return True if the interface is registered as supported, false otherwise.
     */
    function _supportsInterface(Storage storage layoutStruct, bytes4 interfaceId) internal view returns (bool) {
        return layoutStruct.isSupportedInterface[interfaceId];
    }

    // end::_supportsInterface(Storage-bytes4)[]

    // tag::_supportsInterface(bytes4)[]
    /**
     * @dev Default version of _supportsInterface binding to the standard ERC165_STORAGE_SLOT.
     * @param interfaceId The ERC165 interface ID to query.
     * @return True if the interface is registered as supported, false otherwise.
     */
    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        return _supportsInterface(_layoutStruct(), interfaceId);
    }

    // end::_supportsInterface(bytes4)[]
}
// end::ERC165Repo[]
