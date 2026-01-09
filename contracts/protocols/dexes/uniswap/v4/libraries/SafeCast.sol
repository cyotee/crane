// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
library SafeCast {
    error SafeCastOverflow();

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint160
    function toUint160(uint256 x) internal pure returns (uint160 y) {
        y = uint160(x);
        if (y != x) revert SafeCastOverflow();
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return y The downcasted integer, now type uint128
    function toUint128(uint256 x) internal pure returns (uint128 y) {
        y = uint128(x);
        if (y != x) revert SafeCastOverflow();
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param x The int256 to be downcasted
    /// @return y The downcasted integer, now type int128
    function toInt128(int256 x) internal pure returns (int128 y) {
        y = int128(x);
        if (y != x) revert SafeCastOverflow();
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param x The uint256 to be casted
    /// @return y The casted integer, now type int256
    function toInt256(uint256 x) internal pure returns (int256 y) {
        if (x > uint256(type(int256).max)) revert SafeCastOverflow();
        y = int256(x);
    }

    /// @notice Cast an int256 to a uint256, revert on underflow
    /// @param x The int256 to be casted
    /// @return y The casted integer, now type uint256
    function toUint256(int256 x) internal pure returns (uint256 y) {
        if (x < 0) revert SafeCastOverflow();
        y = uint256(x);
    }
}
