// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct GreeterLayout {
    string message;
}

library GreeterRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.test.stubs.greeter");

    // tag::_layoutStruct[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (GreeterLayout storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct[]

    function _layoutStruct() internal pure returns (GreeterLayout storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _setMessage(GreeterLayout storage layoutStruct, string memory message) internal {
        layoutStruct.message = message;
    }

    function _setMessage(string memory message) internal {
        _setMessage(_layoutStruct(), message);
    }

    function _getMessage(GreeterLayout storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.message;
    }

    function _getMessage() internal view returns (string memory) {
        return _getMessage(_layoutStruct());
    }
}
