// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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
    function toString(uint256 value) internal pure returns (string memory) {
        return value.toString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return value.toStringSigned();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        return value.toHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        return value.toHexString(length);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return addr.toHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function toChecksumHexString(address addr) internal pure returns (string memory) {
        return addr.toChecksumHexString();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return a.equal(b);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseUint(string memory input) internal pure returns (uint256) {
        return input.parseUint();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {
        return input.parseUint(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseUint(string memory input) internal pure returns (bool success, uint256 value) {
        return input.tryParseUint();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseUint(string memory input, uint256 begin, uint256 end)
        internal
        pure
        returns (bool success, uint256 value)
    {
        return input.tryParseUint(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseInt(string memory input) internal pure returns (int256) {
        return input.parseInt();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseInt(string memory input, uint256 begin, uint256 end) internal pure returns (int256) {
        return input.parseInt(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseInt(string memory input) internal pure returns (bool success, int256 value) {
        return input.tryParseInt();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseInt(string memory input, uint256 begin, uint256 end)
        internal
        pure
        returns (bool success, int256 value)
    {
        return input.tryParseInt(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseHexUint(string memory input) internal pure returns (uint256) {
        return input.parseHexUint();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseHexUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {
        return input.parseHexUint(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseHexUint(string memory input) internal pure returns (bool success, uint256 value) {
        return input.tryParseHexUint();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseHexUint(string memory input, uint256 begin, uint256 end)
        internal
        pure
        returns (bool success, uint256 value)
    {
        return input.tryParseHexUint(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseAddress(string memory input) internal pure returns (address) {
        return input.parseAddress();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function parseAddress(string memory input, uint256 begin, uint256 end) internal pure returns (address) {
        return input.parseAddress(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseAddress(string memory input) internal pure returns (bool success, address value) {
        return input.tryParseAddress();
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function tryParseAddress(string memory input, uint256 begin, uint256 end)
        internal
        pure
        returns (bool success, address value)
    {
        return input.tryParseAddress(begin, end);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function escapeJSON(string memory input) internal pure returns (string memory) {
        return input.escapeJSON();
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    function parseFixedPoint(uint256 value, uint8 decimals) internal pure returns (string memory) {
        uint256 shifted;
        if (decimals < 2) {
            shifted = value * (10 ** (2 - uint256(decimals)));
        } else {
            shifted = value / (10 ** (uint256(decimals) - 2));
        }

        uint256 integerPart = shifted / 100;
        uint256 fracPart = shifted % 100;

        string memory intStr = toString(integerPart);

        string memory fracStr;
        if (fracPart == 0) {
            fracStr = "00";
        } else if (fracPart < 10) {
            fracStr = string.concat("0", toString(fracPart));
        } else {
            fracStr = toString(fracPart);
        }

        return string.concat(intStr, ".", fracStr);
    }

    function parseSecondsToISO(uint256 secs) internal pure returns (string memory) {
        uint256 daysAmount = secs / 86400;
        uint256 hoursAmount = (secs % 86400) / 3600;
        uint256 minutesAmount = (secs % 3600) / 60;
        uint256 secondsAmount = secs % 60;

        string memory d = bytes(toString(daysAmount)).length == 1
            ? string(abi.encodePacked("0", toString(daysAmount)))
            : toString(daysAmount);
        string memory h = bytes(toString(hoursAmount)).length == 1
            ? string(abi.encodePacked("0", toString(hoursAmount)))
            : toString(hoursAmount);
        string memory m = bytes(toString(minutesAmount)).length == 1
            ? string(abi.encodePacked("0", toString(minutesAmount)))
            : toString(minutesAmount);
        string memory s = bytes(toString(secondsAmount)).length == 1
            ? string(abi.encodePacked("0", toString(secondsAmount)))
            : toString(secondsAmount);

        return string(abi.encodePacked(d, ":", h, ":", m, ":", s));
    }

    function padLeft(string memory value, string memory padValue, uint256 desiredLength)
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

    function padRight(string memory value, string memory padValue, uint256 desiredLength)
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
    function marshall(string memory value) internal pure returns (bytes memory encodedValue) {
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
    function unmarshallAsString(bytes memory value) internal pure returns (string memory decodedValue) {
        // TODO Will be tested with manual decoding from "packed" encoding.
        decodedValue = abi.decode(value, (string));
    }
}
