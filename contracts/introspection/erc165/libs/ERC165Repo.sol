// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct ERC165Layout {
    mapping(bytes4 interfaceId => bool isSupported) isSupportedInterface;
}

/**
 * @title ERC165Repo - Repository library for ERC165 relevant state.
 * @author cyotee doge <doge.cyotee>
 */
library ERC165Repo {

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(ERC165Layout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}
