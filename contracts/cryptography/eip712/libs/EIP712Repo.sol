// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ShortString,
    ShortStrings
} from "../../../utils/storage/ShortStrings.sol";

struct EIP712Layout {
    bytes32 _cachedDomainSeparator;
    uint256 _cachedChainId;
    address _cachedThis;

    bytes32 _hashedName;
    bytes32 _hashedVersion;

    ShortString _name;
    ShortString _version;
    string _nameFallback;
    string _versionFallback;
}

library EIP712Repo {

    // tag::slot[]
    /**
     * @dev Provides the storage pointer bound to a Struct instance.
     * @param layout_ Implicit "layout" of storage slots defined as this Struct.
     * @return slot_ The storage slot bound to the provided Struct.
     */
    function slot(
        EIP712Layout storage layout_
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
        EIP712Layout storage layout_
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
    ) external pure returns(EIP712Layout storage layout_) {
        return _layout(slot_);
    }
    // end::layout[]

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(EIP712Layout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}
