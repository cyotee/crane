// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    AddressSet,
    AddressSetRepo
} from "contracts/utils/collections/sets/AddressSetRepo.sol";

import {
    Bytes4Set,
    Bytes4SetRepo
} from "contracts/utils/collections/sets/Bytes4SetRepo.sol";

struct ERC2535Layout {
    AddressSet facetAddresses;
    mapping(bytes4 functionSelector => address facet) facetAddress;
    mapping(address facet => Bytes4Set functionSelectors) facetFunctionSelectors;
}

library ERC2535Repo {

    // using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(ERC2535Layout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}
