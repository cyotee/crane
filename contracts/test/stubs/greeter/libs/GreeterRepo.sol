// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct GreeterLayout {
    string message;
}

library GreeterRepo {

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(GreeterLayout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}
