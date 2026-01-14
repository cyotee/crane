// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/**
 * @title ERC165Repo - Repository library for ERC165 relevant state.
 * @author cyotee doge <doge.cyotee>
 */
library ERC165Repo {
    bytes32 internal constant ERC165_STORAGE_SLOT = keccak256(abi.encode("eip.erc.165"));

    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        mapping(bytes4 interfaceId => bool isSupported) isSupportedInterface;
    }

    // tag::_layout(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout(bytes32)[]

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(ERC165_STORAGE_SLOT);
    }

    function _registerInterface(Storage storage layout, bytes4 interfaceId) internal {
        layout.isSupportedInterface[interfaceId] = true;
    }

    function _registerInterface(bytes4 interfaceId) internal {
        _layout().isSupportedInterface[interfaceId] = true;
    }

    function _registerInterfaces(Storage storage layout, bytes4[] memory interfaceIds) internal {
        for (uint256 cursor = 0; cursor < interfaceIds.length; cursor++) {
            _registerInterface(layout, interfaceIds[cursor]);
        }
    }

    function _registerInterfaces(bytes4[] memory interfaceIds) internal {
        _registerInterfaces(_layout(), interfaceIds);
    }

    function _supportsInterface(Storage storage layout, bytes4 interfaceId) internal view returns (bool) {
        return layout.isSupportedInterface[interfaceId];
    }

    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        return _layout().isSupportedInterface[interfaceId];
    }
}
