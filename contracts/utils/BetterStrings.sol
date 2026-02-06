// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@crane/contracts/utils/Strings.sol";

library BetterStrings {
    using Strings for address;
    using Strings for int256;
    using Strings for string;
    using Strings for uint256;

    /* ---------------------------------------------------------------------- */
    /*               Wrapper Functions for Drop-In Compatibility              */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        return value.toString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toStringSigned(int256 value) internal pure returns (string memory) {
        return value.toStringSigned();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toHexString(uint256 value) internal pure returns (string memory) {
        return value.toHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        return value.toHexString(length);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toHexString(address addr) internal pure returns (string memory) {
        return addr.toHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _toChecksumHexString(address addr) internal pure returns (string memory) {
        return addr.toChecksumHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _equal(string memory a, string memory b) internal pure returns (bool) {
        return a.equal(b);
    }

    // NOTE: Parsing functions (parseUint, parseInt, parseAddress, etc.) removed
    // because Solady's LibString doesn't provide them. Add them back when needed
    // with a custom implementation.

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    function _parseFixedPoint(uint256 value, uint8 decimals) internal pure returns (string memory) {
        uint256 shifted;
        if (decimals < 2) {
            shifted = value * (10 ** (2 - uint256(decimals)));
        } else {
            shifted = value / (10 ** (uint256(decimals) - 2));
        }

        uint256 integerPart = shifted / 100;
        uint256 fracPart = shifted % 100;

        string memory intStr = _toString(integerPart);

        string memory fracStr;
        if (fracPart == 0) {
            fracStr = "00";
        } else if (fracPart < 10) {
            fracStr = string.concat("0", _toString(fracPart));
        } else {
            fracStr = _toString(fracPart);
        }

        return string.concat(intStr, ".", fracStr);
    }

    function _parseSecondsToISO(uint256 secs) internal pure returns (string memory) {
        uint256 daysAmount = secs / 86400;
        uint256 hoursAmount = (secs % 86400) / 3600;
        uint256 minutesAmount = (secs % 3600) / 60;
        uint256 secondsAmount = secs % 60;

        string memory d = bytes(_toString(daysAmount)).length == 1
            ? string(abi.encodePacked("0", _toString(daysAmount)))
            : _toString(daysAmount);
        string memory h = bytes(_toString(hoursAmount)).length == 1
            ? string(abi.encodePacked("0", _toString(hoursAmount)))
            : _toString(hoursAmount);
        string memory m = bytes(_toString(minutesAmount)).length == 1
            ? string(abi.encodePacked("0", _toString(minutesAmount)))
            : _toString(minutesAmount);
        string memory s = bytes(_toString(secondsAmount)).length == 1
            ? string(abi.encodePacked("0", _toString(secondsAmount)))
            : _toString(secondsAmount);

        return string(abi.encodePacked(d, ":", h, ":", m, ":", s));
    }

    function _padLeft(string memory value, string memory padValue, uint256 desiredLength)
        internal
        pure
        returns (string memory paddedValue)
    {
        paddedValue = value;
        while (bytes(paddedValue).length < desiredLength) {
            paddedValue = string.concat(padValue, paddedValue);
        }
        return paddedValue;
    }

    function _padRight(string memory value, string memory padValue, uint256 desiredLength)
        internal
        pure
        returns (string memory paddedValue)
    {
        // uint256 length = value.length();
        paddedValue = value;
        while (bytes(paddedValue).length < desiredLength) {
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
    function _marshall(string memory value) internal pure returns (bytes memory encodedValue) {
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
    function _unmarshallAsString(bytes memory value) internal pure returns (string memory decodedValue) {
        // TODO Will be tested with manual decoding from "packed" encoding.
        decodedValue = abi.decode(value, (string));
    }
}
