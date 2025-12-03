// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {HEX_SYMBOLS} from "contracts/constants/Constants.sol";
import {BetterArrays as Arrays} from "contracts/utils/collections/BetterArrays.sol";

/**
 * @title Bytes32 - Standardized operations for bytes32.
 * @author cyotee doge <doge.cyotee>
 */
library Bytes32 {
    using Arrays for uint256;

    // bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    // TODO Could it be possible to calculate and store this immutably on creation?
    // Proxies will be DELEGATECALLING targets.
    // Targets couldn't store this.
    // Maybe proxies can caculate and store their obfuscation value?
    // Viable to reserve slot 0 for this?
    // FML for having to deal with this.
    // Why do humans have to suck sometimes?
    function _scramble(bytes32 value) internal view returns (bytes32) {
        return value ^ bytes32((uint256(keccak256(abi.encodePacked(address(this)))) - 1));
    }

    /**
     * @dev Converts an bytes32 to an address truncating from the left.
     * @dev All values over 2^160-1 will be returned as 2^160-1.
     * @param value The value to convert.
     * @return result The converted value.
     */
    function _toAddress(bytes32 value) internal pure returns (address result) {
        //               address(bytes20(value)) is NOT equivalent.
        result = address(uint160(uint256(value)));
    }

    function _toHexString(bytes32 _bytes32) internal pure returns (string memory) {
        // 2 characters per byte + "0x" prefix = 66 characters total
        bytes memory result = new bytes(66);

        // Set "0x" prefix
        result[0] = "0";
        result[1] = "x";

        // Convert each byte to two hex characters
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(_bytes32[i]);
            // First nibble (high 4 bits)
            result[2 + i * 2] = HEX_SYMBOLS[b >> 4];
            // Second nibble (low 4 bits)
            result[3 + i * 2] = HEX_SYMBOLS[b & 0x0f];
        }

        return string(result);
    }

    function _equalPartitions(bytes32 data) internal pure returns (bytes4[] memory partitions) {
        uint256 uintData = uint256(data);
        partitions = new bytes4[](8);
        for (uint256 cursor = 0; cursor < 8; cursor++) {
            uint256 shifted = uintData >> (224 - cursor * 32);
            partitions[cursor] = bytes4(uint32(shifted));
        }
    }

    function _extractEqPartition(bytes32 data, uint256 index) internal pure returns (bytes4) {
        // require(Arrays.isValidIndex(8, index));
        Arrays._isValidIndex(8, index);
        uint256 uintData = uint256(data);
        uint256 shifted = uintData >> (224 - index * 32);
        return bytes4(uint32(shifted));
    }

    function _insertEqPartition(bytes32 data, bytes4 part, uint256 index) internal pure returns (bytes32) {
        require(Arrays._isValidIndex(8, index));
        uint256 uintData = uint256(data);
        uint256 uintPart = uint256(uint32(part));
        uint256 shift = 224 - index * 32;
        uint256 mask = ~(uint256(0xffffffff) << shift);
        uintData &= mask;
        uintData |= (uintPart << shift);
        return bytes32(uintData);
    }

    function _packEqualPartitions(bytes4[] memory data) internal pure returns (bytes32) {
        uint256 length = data.length;
        // require(Arrays.isValidIndex(8, length));
        Arrays._isValidIndex(8, length);
        uint256 result;
        uint256 position = 224;
        for (uint256 cursor = 0; cursor < length; cursor++) {
            uint256 part = uint256(uint32(data[cursor]));
            result |= (part << position);
            position -= 32;
        }
        return bytes32(result);
    }
}
