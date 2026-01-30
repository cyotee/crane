// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// tag::SafeCast160[]
/// @title SafeCast160
/// @notice Library for safely casting uint256 to uint160
library SafeCast160 {
    /// @notice Thrown when a value greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    /// @return The value cast to uint160
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}
// end::SafeCast160[]
