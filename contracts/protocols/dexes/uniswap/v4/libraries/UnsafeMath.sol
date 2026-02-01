// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title UnsafeMath
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev Division by 0 has undefined behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    /// @notice Calculates floor(a×b÷denominator)
    /// @dev Division by 0 will return 0, and should be checked externally
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result, floor(a×b÷denominator)
    function simpleMulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := div(mul(a, b), denominator)
        }
    }
}
