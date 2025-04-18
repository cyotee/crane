// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ERC165Layout,
    ERC165Repo
} from "../libs/ERC165Repo.sol";
import {
    IERC165
} from "../interfaces/IERC165.sol";

/**
 * @title ERC165Storage - Inheritable 
 */
abstract contract ERC165Storage {

    using ERC165Repo for bytes32;

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ERC165Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IERC165).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _erc165()
    internal pure virtual returns(ERC165Layout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initERC165(
        bytes4[] memory supportedInterfaces_
    ) internal {
        for(uint256 cursor = 0; cursor < supportedInterfaces_.length; cursor ++) {
            _erc165().isSupportedInterface[supportedInterfaces_[cursor]] = true;
        }
    }

}
