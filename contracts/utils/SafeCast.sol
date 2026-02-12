// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCastLib} from "@crane/contracts/utils/SafeCastLib.sol";

/**
 * @dev OpenZeppelin-compatible SafeCast wrapper using Solady's SafeCastLib.
 * @notice Native Crane implementation - delegates to Solady
 *
 * This provides OpenZeppelin API compatibility while leveraging Solady's
 * gas-optimized implementations.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    // ===== Unsigned to Unsigned Casts =====

    function toUint248(uint256 value) internal pure returns (uint248) {
        return SafeCastLib.toUint248(value);
    }

    function toUint240(uint256 value) internal pure returns (uint240) {
        return SafeCastLib.toUint240(value);
    }

    function toUint232(uint256 value) internal pure returns (uint232) {
        return SafeCastLib.toUint232(value);
    }

    function toUint224(uint256 value) internal pure returns (uint224) {
        return SafeCastLib.toUint224(value);
    }

    function toUint216(uint256 value) internal pure returns (uint216) {
        return SafeCastLib.toUint216(value);
    }

    function toUint208(uint256 value) internal pure returns (uint208) {
        return SafeCastLib.toUint208(value);
    }

    function toUint200(uint256 value) internal pure returns (uint200) {
        return SafeCastLib.toUint200(value);
    }

    function toUint192(uint256 value) internal pure returns (uint192) {
        return SafeCastLib.toUint192(value);
    }

    function toUint184(uint256 value) internal pure returns (uint184) {
        return SafeCastLib.toUint184(value);
    }

    function toUint176(uint256 value) internal pure returns (uint176) {
        return SafeCastLib.toUint176(value);
    }

    function toUint168(uint256 value) internal pure returns (uint168) {
        return SafeCastLib.toUint168(value);
    }

    function toUint160(uint256 value) internal pure returns (uint160) {
        return SafeCastLib.toUint160(value);
    }

    function toUint152(uint256 value) internal pure returns (uint152) {
        return SafeCastLib.toUint152(value);
    }

    function toUint144(uint256 value) internal pure returns (uint144) {
        return SafeCastLib.toUint144(value);
    }

    function toUint136(uint256 value) internal pure returns (uint136) {
        return SafeCastLib.toUint136(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        return SafeCastLib.toUint128(value);
    }

    function toUint120(uint256 value) internal pure returns (uint120) {
        return SafeCastLib.toUint120(value);
    }

    function toUint112(uint256 value) internal pure returns (uint112) {
        return SafeCastLib.toUint112(value);
    }

    function toUint104(uint256 value) internal pure returns (uint104) {
        return SafeCastLib.toUint104(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        return SafeCastLib.toUint96(value);
    }

    function toUint88(uint256 value) internal pure returns (uint88) {
        return SafeCastLib.toUint88(value);
    }

    function toUint80(uint256 value) internal pure returns (uint80) {
        return SafeCastLib.toUint80(value);
    }

    function toUint72(uint256 value) internal pure returns (uint72) {
        return SafeCastLib.toUint72(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        return SafeCastLib.toUint64(value);
    }

    function toUint56(uint256 value) internal pure returns (uint56) {
        return SafeCastLib.toUint56(value);
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        return SafeCastLib.toUint48(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        return SafeCastLib.toUint40(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        return SafeCastLib.toUint32(value);
    }

    function toUint24(uint256 value) internal pure returns (uint24) {
        return SafeCastLib.toUint24(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        return SafeCastLib.toUint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        return SafeCastLib.toUint8(value);
    }

    // ===== Signed to Unsigned Casts =====

    function toUint256(int256 value) internal pure returns (uint256) {
        return SafeCastLib.toUint256(value);
    }

    // ===== Signed to Signed Casts =====

    function toInt256(uint256 value) internal pure returns (int256) {
        return SafeCastLib.toInt256(value);
    }

    function toInt248(int256 value) internal pure returns (int248) {
        return SafeCastLib.toInt248(value);
    }

    function toInt240(int256 value) internal pure returns (int240) {
        return SafeCastLib.toInt240(value);
    }

    function toInt232(int256 value) internal pure returns (int232) {
        return SafeCastLib.toInt232(value);
    }

    function toInt224(int256 value) internal pure returns (int224) {
        return SafeCastLib.toInt224(value);
    }

    function toInt216(int256 value) internal pure returns (int216) {
        return SafeCastLib.toInt216(value);
    }

    function toInt208(int256 value) internal pure returns (int208) {
        return SafeCastLib.toInt208(value);
    }

    function toInt200(int256 value) internal pure returns (int200) {
        return SafeCastLib.toInt200(value);
    }

    function toInt192(int256 value) internal pure returns (int192) {
        return SafeCastLib.toInt192(value);
    }

    function toInt184(int256 value) internal pure returns (int184) {
        return SafeCastLib.toInt184(value);
    }

    function toInt176(int256 value) internal pure returns (int176) {
        return SafeCastLib.toInt176(value);
    }

    function toInt168(int256 value) internal pure returns (int168) {
        return SafeCastLib.toInt168(value);
    }

    function toInt160(int256 value) internal pure returns (int160) {
        return SafeCastLib.toInt160(value);
    }

    function toInt152(int256 value) internal pure returns (int152) {
        return SafeCastLib.toInt152(value);
    }

    function toInt144(int256 value) internal pure returns (int144) {
        return SafeCastLib.toInt144(value);
    }

    function toInt136(int256 value) internal pure returns (int136) {
        return SafeCastLib.toInt136(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        return SafeCastLib.toInt128(value);
    }

    function toInt120(int256 value) internal pure returns (int120) {
        return SafeCastLib.toInt120(value);
    }

    function toInt112(int256 value) internal pure returns (int112) {
        return SafeCastLib.toInt112(value);
    }

    function toInt104(int256 value) internal pure returns (int104) {
        return SafeCastLib.toInt104(value);
    }

    function toInt96(int256 value) internal pure returns (int96) {
        return SafeCastLib.toInt96(value);
    }

    function toInt88(int256 value) internal pure returns (int88) {
        return SafeCastLib.toInt88(value);
    }

    function toInt80(int256 value) internal pure returns (int80) {
        return SafeCastLib.toInt80(value);
    }

    function toInt72(int256 value) internal pure returns (int72) {
        return SafeCastLib.toInt72(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        return SafeCastLib.toInt64(value);
    }

    function toInt56(int256 value) internal pure returns (int56) {
        return SafeCastLib.toInt56(value);
    }

    function toInt48(int256 value) internal pure returns (int48) {
        return SafeCastLib.toInt48(value);
    }

    function toInt40(int256 value) internal pure returns (int40) {
        return SafeCastLib.toInt40(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        return SafeCastLib.toInt32(value);
    }

    function toInt24(int256 value) internal pure returns (int24) {
        return SafeCastLib.toInt24(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        return SafeCastLib.toInt16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        return SafeCastLib.toInt8(value);
    }

    // ===== Boolean Cast (OZ-specific) =====

    /**
     * @dev Converts a boolean to uint256, where false maps to 0 and true maps to 1.
     * This is used internally by OZ Math functions.
     */
    function toUint(bool b) internal pure returns (uint256 u) {
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}
