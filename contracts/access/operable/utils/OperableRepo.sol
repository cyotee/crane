// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

struct OperableLayout {
    mapping(address => bool) isOperator;
    mapping(bytes4 func => mapping(address => bool)) isOperatorFor;
}

/**
 * @title OperableRepo - Repository library for OperableLayout;
 * @author cyotee doge <doge.cyotee>
 */
library OperableRepo {

    // tag::slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param table Implicit "table" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function slot(
        OperableLayout storage table
    ) internal pure returns(bytes32 slot_) {
        assembly{slot_ := table.slot}
    }
    // end::slot[]

    // tag::layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function layout(
        bytes32 slot_
    ) internal pure returns(OperableLayout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::layout[]

}
