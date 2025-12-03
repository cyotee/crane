// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

library BetterEfficientHashLib {
    function __hash(bytes32 v0) internal pure returns (bytes32 result) {
        result = EfficientHashLib.hash(v0);
    }

    function __hash(uint256 v0) internal pure returns (bytes32 result) {
        result = EfficientHashLib.hash(bytes32(v0));
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1))`.
    function _hash(bytes32 v0, bytes32 v1) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1);
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1))`.
    function _hash(uint256 v0, uint256 v1) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1);
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2);
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2);
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2, v3))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3);
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2, v3))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v4))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v4))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v5))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4, bytes32 v5)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v5))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4, uint256 v5)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v6))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4, bytes32 v5, bytes32 v6)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v6))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4, uint256 v5, uint256 v6)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v7))`.
    function _hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4, bytes32 v5, bytes32 v6, bytes32 v7)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v7))`.
    function _hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4, uint256 v5, uint256 v6, uint256 v7)
        internal
        pure
        returns (bytes32 result)
    {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v8))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v8))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v9))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v9))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v10))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v10))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v11))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v11))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v12))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11,
        bytes32 v12
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v12))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11,
        uint256 v12
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v13))`.
    function _hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11,
        bytes32 v12,
        bytes32 v13
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13);
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v13))`.
    function _hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11,
        uint256 v12,
        uint256 v13
    ) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             BYTES32 BUFFER HASHING OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `keccak256(abi.encode(buffer[0], .., buffer[buffer.length - 1]))`.
    function _hash(bytes32[] memory buffer) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(buffer);
    }

    /// @dev Sets `buffer[i]` to `value`, without a bounds check.
    /// Returns the `buffer` for function chaining.
    function _set(bytes32[] memory buffer, uint256 i, bytes32 value) internal pure returns (bytes32[] memory) {
        return EfficientHashLib.set(buffer, i, value);
    }

    /// @dev Sets `buffer[i]` to `value`, without a bounds check.
    /// Returns the `buffer` for function chaining.
    function _set(bytes32[] memory buffer, uint256 i, uint256 value) internal pure returns (bytes32[] memory) {
        return EfficientHashLib.set(buffer, i, value);
    }

    /// @dev Returns `new bytes32[](n)`, without zeroing out the memory.
    function _malloc(uint256 n) internal pure returns (bytes32[] memory buffer) {
        return EfficientHashLib.malloc(n);
    }

    /// @dev Frees memory that has been allocated for `buffer`.
    /// No-op if `buffer.length` is zero, or if new memory has been allocated after `buffer`.
    function _free(bytes32[] memory buffer) internal pure {
        EfficientHashLib.free(buffer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EQUALITY CHECKS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `a == abi.decode(b, (bytes32))`.
    function _eq(bytes32 a, bytes memory b) internal pure returns (bool result) {
        return EfficientHashLib.eq(a, b);
    }

    /// @dev Returns `abi.decode(a, (bytes32)) == b`.
    function _eq(bytes memory a, bytes32 b) internal pure returns (bool result) {
        return EfficientHashLib.eq(a, b);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               BYTE SLICE HASHING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the keccak256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function _hash(bytes memory b, uint256 start, uint256 end) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(b, start, end);
    }

    /// @dev Returns the keccak256 of the slice from `start` to the end of the bytes.
    function _hash(bytes memory b, uint256 start) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(b, start);
    }

    /// @dev Returns the keccak256 of the bytes.
    function _hash(bytes memory b) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(b);
    }

    /// @dev Returns the keccak256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function _hashCalldata(bytes calldata b, uint256 start, uint256 end) internal pure returns (bytes32 result) {
        return EfficientHashLib.hashCalldata(b, start, end);
    }

    /// @dev Returns the keccak256 of the slice from `start` to the end of the bytes.
    function _hashCalldata(bytes calldata b, uint256 start) internal pure returns (bytes32 result) {
        return EfficientHashLib.hashCalldata(b, start);
    }

    /// @dev Returns the keccak256 of the bytes.
    function _hashCalldata(bytes calldata b) internal pure returns (bytes32 result) {
        return EfficientHashLib.hashCalldata(b);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      SHA2-256 HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `sha256(abi.encode(b))`. Yes, it's more efficient.
    function _sha2(bytes32 b) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2(b);
    }

    /// @dev Returns the sha256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function _sha2(bytes memory b, uint256 start, uint256 end) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2(b, start, end);
    }

    /// @dev Returns the sha256 of the slice from `start` to the end of the bytes.
    function _sha2(bytes memory b, uint256 start) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2(b, start);
    }

    /// @dev Returns the sha256 of the bytes.
    function _sha2(bytes memory b) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2(b);
    }

    /// @dev Returns the sha256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function _sha2Calldata(bytes calldata b, uint256 start, uint256 end) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2Calldata(b, start, end);
    }

    /// @dev Returns the sha256 of the slice from `start` to the end of the bytes.
    function _sha2Calldata(bytes calldata b, uint256 start) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2Calldata(b, start);
    }

    /// @dev Returns the sha256 of the bytes.
    function _sha2Calldata(bytes calldata b) internal view returns (bytes32 result) {
        return EfficientHashLib.sha2Calldata(b);
    }
}
