// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Array Standard operations for all arrays.
 * @author cyotee doge <doge.cyotee>
 */
library Array {

    /**
     * @param length The length of the array for which `invalidIndex` is out of bounds.
     * @param invalidIndex The index that is out of bounds for the array.
     */
    error IndexOutOfBounds(uint256 length, uint256 invalidIndex);

    /**
     * @dev Reverts with custom error if provided index would be out of bounds of provided length.
     * @dev Facilitates usage of custom error within a require statement.
     * @param length The length of the array against which the index is being checked..
     * @param index The index to confirm is contained within the provided length.
     * @custom:sig isValidIndex(uint256,uint256)
     * @custom:selector 0x65e8faf6
     */
    function isValidIndex(
        uint256 length,
        uint256 index
    ) external pure returns(bool isValid) {
        return _isValidIndex(length, index);
    }

    /**
     * @dev Reverts with custom error if provided index would be out of bounds of provided length.
     * @dev Facilitates usage of custom error within a require statement.
     * @param length The length of the array against which the index is being checked..
     * @param index The index to confirm is contained within the provided length.
     */
    function _isValidIndex(
        uint256 length,
        uint256 index
    ) internal pure returns(bool isValid) {
        if(length < index) {
            revert Array.IndexOutOfBounds(length, index);
        }
        return true;
    }

    function _toLength(
        address[5] memory values,
        uint256 newLength
    ) internal pure returns(address[] memory newValues) {
        require(newLength >= values.length);
        newValues = new address[](newLength);
        for(uint256 cursor =0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    function _toLength(
        address[10] memory values,
        uint256 newLength
    ) internal pure returns(address[] memory newValues) {
        require(newLength >= values.length);
        newValues = new address[](newLength);
        for(uint256 cursor =0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    function _toLength(
        address[100] memory values,
        uint256 newLength
    ) internal pure returns(address[] memory newValues) {
        require(newLength >= values.length);
        newValues = new address[](newLength);
        for(uint256 cursor =0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    function _toLength(
        address[1000] memory values,
        uint256 newLength
    ) internal pure returns(address[] memory newValues) {
        require(newLength >= values.length);
        newValues = new address[](newLength);
        for(uint256 cursor =0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    function _toLength(
        address[] memory values,
        uint256 newLength
    ) internal pure returns(address[] memory newValues) {
        require(newLength >= values.length);
        newValues = new address[](newLength);
        for(uint256 cursor =0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

}