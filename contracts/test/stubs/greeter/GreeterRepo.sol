// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct GreeterLayout {
    string message;
}

library GreeterRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.test.stubs.greeter");

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (GreeterLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]

    function _layout() internal pure returns (GreeterLayout storage) {
        return _layout(STORAGE_SLOT);
    }

    function _setMessage(GreeterLayout storage layout, string memory message) internal {
        layout.message = message;
    }

    function _setMessage(string memory message) internal {
        _setMessage(_layout(), message);
    }

    function _getMessage(GreeterLayout storage layout) internal view returns (string memory) {
        return layout.message;
    }

    function _getMessage() internal view returns (string memory) {
        return _getMessage(_layout());
    }
}
