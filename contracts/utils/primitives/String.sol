// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library String {

    function _padLeft(
        string memory value,
        string memory padValue,
        uint256 desiredLength
    ) internal pure returns(string memory paddedValue) {
        paddedValue = value;
        while(bytes(paddedValue).length < desiredLength) {
            paddedValue = string.concat(padValue, paddedValue);
        }
        return paddedValue;
    }

    function _padRight(
        string memory value,
        string memory padValue,
        uint256 desiredLength
    ) internal pure returns(string memory paddedValue) {
        // uint256 length = value.length();
        paddedValue = value;
        while(bytes(paddedValue).length < desiredLength) {
            paddedValue = string.concat(paddedValue, padValue);
        }
        return paddedValue;
    }

  /**
   * @notice Provides consistent encoding of address types.
   * @dev Intended to allow for consistent packed encoding.
   * @param value The address value to be encoded into a bytes array.
   * @return encodedValue The value encoded into a bytes array.
   */
  // TODO Refactor to packed encoding when Address._unmarshall() is refactored to packed decoding.
  function _marshall(
    string memory value
  ) internal pure returns(bytes memory encodedValue) {
    // Will be changed to packed encoding 
    encodedValue = abi.encode(value);
  }

  /**
   * @notice Named specific to the decoded type to disambiguate unmarshalling functions between libraries.
   * @notice Expects the value to have been marshalled with this library.
   * @dev Intended to provide consistent usage of packed encoded addressed.
   * @dev Used to minimze data size when working with fixed length types that would not require padding to differentiate.
   * @dev Should NOT be used with other encoding, ABI and otherwise, unless you know what you are doing.
   * @param value The bytes array to be decoded as an address
   * @return decodedValue The decoded address.
   */
  // TODO Refactor to decode packed encoding.
  function _unmarshallAsString(
    bytes memory value
  ) internal pure returns(string memory decodedValue ) {
    // TODO Will be tested with manual decoding from "packed" encoding.
    decodedValue = abi.decode(value, (string));
  }

}