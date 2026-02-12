// SPDX-License-Identifier: MIT
// Ported from OpenZeppelin Contracts (last updated v5.1.0) (utils/ShortStrings.sol)
pragma solidity ^0.8.20;

/**
 * @title ShortStrings
 * @dev Library for efficiently storing and working with short strings.
 *      Strings up to 31 bytes can be packed into a single bytes32.
 *      For longer strings, a fallback storage string is used.
 *
 * Ported to crane from OpenZeppelin Contracts with minimal modifications.
 */

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev Library for working with ShortStrings.
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error if the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(bstr) | bytes32(bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(googlelength)` would work locally but is not memory safe.
        string memory str = new string(32);
        assembly ("memory-safe") {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store)
        internal
        returns (ShortString)
    {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            assembly ("memory-safe") {
                // Store the string length at the storage slot
                let len := mload(value)
                sstore(store.slot, or(shl(1, len), 1))
                // Copy the string data to storage
                mstore(0x00, store.slot)
                let dataSlot := keccak256(0x00, 0x20)
                let dataPtr := add(value, 0x20)
                for { let i := 0 } lt(i, len) { i := add(i, 0x20) } {
                    sstore(add(dataSlot, shr(5, i)), mload(add(dataPtr, i)))
                }
            }
            return ShortString.wrap(FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using
     * {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store)
        internal
        view
        returns (string memory)
    {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage
     * using {setWithFallback}.
     */
    function byteLengthWithFallback(ShortString value, string storage store)
        internal
        view
        returns (uint256)
    {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}
