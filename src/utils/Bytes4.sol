// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {HEX_SYMBOLS} from "src/constants/Constants.sol";

/**
 * @title Library of utility functions for dealing with bytes4 and bytes4[].
 * @author cyotee doge
 */
// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
library Bytes4 {
    function _xor(bytes4 value1, bytes4 value2) internal pure returns (bytes4 xor_) {
        return value1 ^ value2;
    }

    function _xor(bytes4[] memory values) internal pure returns (bytes4 xor_) {
        if (values.length > 0) {
            xor_ = values[0];
            for (uint256 cursor = 1; cursor < values.length; cursor++) {
                xor_ = xor_ ^ values[cursor];
            }
        }
    }

    function _toString(bytes4 value) internal pure returns (string memory) {
        return string.concat("0x", string(abi.encodePacked(value)));
    }

    function _toHexString(bytes4 _bytes4) internal pure returns (string memory) {
        // 2 characters per byte + "0x" prefix = 10 characters total
        bytes memory result = new bytes(10);

        // Set "0x" prefix
        result[0] = "0";
        result[1] = "x";

        // Convert each byte to two hex characters
        for (uint256 i = 0; i < 4; i++) {
            uint8 b = uint8(_bytes4[i]);
            // First nibble (high 4 bits)
            result[2 + i * 2] = HEX_SYMBOLS[b >> 4];
            // Second nibble (low 4 bits)
            result[3 + i * 2] = HEX_SYMBOLS[b & 0x0f];
        }

        return string(result);
    }

    /**
     * @dev Merges two array of bytes4. Intended to be used to consilidate the function selectors from a Policy in the array of Gates.
     * @param array1 An array of function bytes4 to be merged with array2.
     * @param array2 An array of function bytes4 to be merged with array1.
     * @return mergedArray The array that will be comprised of the two provided arrays.
     */
    function _append(bytes4[] memory array1, bytes4[] memory array2)
        internal
        pure
        returns (bytes4[] memory mergedArray)
    {
        // Set the return size to the combined length of both provided arrays.
        mergedArray = new bytes4[](array1.length + array2.length);
        // Iterate through the first provided array until the end of the first provided array.
        for (uint256 iteration = 0; iteration < array1.length; iteration++) {
            // Set the members of the first provided array as the first members of the merged array.
            mergedArray[iteration] = array1[iteration];
        }
        // Init an iteration counter for stepping through the second provided array.
        uint256 array2Iteration = 0;
        // Iterate through the second provided array until the end of the merged array.
        for (uint256 iteration = array1.length; iteration < mergedArray.length; iteration++) {
            // Set the members of the second provided array as the members of the merged array starting after the last member from the first provided array.
            mergedArray[iteration] = array2[array2Iteration];
            // Increment the second provided array iteration counter for stepping through the array.
            array2Iteration++;
        }
    }

    function _append(bytes4[] memory array1, bytes4 value) internal pure returns (bytes4[] memory appendedArray) {
        // Set the return size to the combined length of both provided arrays.
        appendedArray = new bytes4[](array1.length + 1);
        // Iterate through the first provided array until the end of the first provided array.
        for (uint256 iteration = 0; iteration < array1.length; iteration++) {
            // Set the members of the first provided array as the first members of the merged array.
            appendedArray[iteration] = array1[iteration];
        }
        appendedArray[array1.length] = value;
    }

}
