// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct PowerLayout {
    /**
     * The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
     *   Apply the same change in file 'PrintFunctionBancorFormula.py', run it and paste the results below.
     */
    uint256[128] maxExpArray;
}

library PowerRepo {
    // tag::slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param table Implicit "table" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function slot(PowerLayout storage table) external pure returns (bytes32 slot_) {
        return _slot(table);
    }

    // end::slot[]

    // tag::_slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param table Implicit "table" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function _slot(PowerLayout storage table) internal pure returns (bytes32 slot_) {
        assembly {
            slot_ := table.slot
        }
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
    function layout(bytes32 slot_) external pure returns (PowerLayout storage layout_) {
        return _layout(slot_);
    }

    // end::layout[]

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (PowerLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}
