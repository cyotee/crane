// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibString} from "@crane/contracts/solady/utils/LibString.sol";

/**
 * @dev OpenZeppelin-compatible Strings library using Solady's LibString.
 * @notice Native Crane implementation - no external dependencies
 *
 * Provides string manipulation functions with OZ API compatibility.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        return LibString.toString(value);
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return LibString.toString(value);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        return LibString.toHexString(value);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        return LibString.toHexString(value, length);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return LibString.toHexString(addr);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its checksummed ASCII `string` hexadecimal
     * representation, according to EIP-55.
     */
    function toChecksumHexString(address addr) internal pure returns (string memory) {
        return LibString.toHexStringChecksummed(addr);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return LibString.eq(a, b);
    }
}
