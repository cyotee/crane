// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    GreeterLayout,
    GreeterRepo
} from "./GreeterRepo.sol";

import {
    IGreeter
} from "../IGreeter.sol";

contract GreeterStorage
{
    using GreeterRepo for bytes32;

    bytes32 private constant LAYOUT_ID
        = keccak256(type(GreeterRepo).creationCode);
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IGreeter).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _greeter()
    internal pure virtual returns(GreeterLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initGreeter(
        string memory message
    ) internal {
        emit IGreeter.NewMessage(_greeter().message, message);
        _greeter().message = message;
    }

}
