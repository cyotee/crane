// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

struct OwnableLayout {
    address owner;
    address proposedOwner;
}

/**
 * @title OwnableRepo - Repository library for OwnableLayout.
 * @author cyotee doge <doge.cyotee>
 */
library OwnableRepo {

    // tag::slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param layout_ Implicit "layout" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function slot(
        OwnableLayout storage layout_
    ) external pure returns(bytes32 slot_) {
        return _slot(layout_);
    }
    // end::slot[]

    // tag::_slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param layout_ Implicit "layout" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function _slot(
        OwnableLayout storage layout_
    ) internal pure returns(bytes32 slot_) {
        assembly{slot_ := layout_.slot}
    }
    // end::_slot[]

    // tag::layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     * @custom:sig layout(bytes32)
     * @custom:selector 0x81366cef
     */
    function layout(
        bytes32 slot_
    ) external pure returns(OwnableLayout storage layout_) {
        return _layout(slot_);
    }
    // end::layout[]

    /**
     * @dev "Binds" a struct to a storage slot.
     * @param storageRange The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 storageRange
    ) internal pure returns(OwnableLayout storage layout_) {
        assembly{layout_.slot := storageRange}
    }

}
