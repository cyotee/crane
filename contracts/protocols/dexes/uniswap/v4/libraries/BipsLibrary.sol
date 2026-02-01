// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title For calculating a percentage of an amount, using bips
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
library BipsLibrary {
    uint256 internal constant BPS_DENOMINATOR = 10_000;

    /// @notice emitted when an invalid percentage is provided
    error InvalidBips();

    /// @param amount The total amount to calculate a percentage of
    /// @param bips The percentage to calculate, in bips
    function calculatePortion(uint256 amount, uint256 bips) internal pure returns (uint256) {
        if (bips > BPS_DENOMINATOR) revert InvalidBips();
        return (amount * bips) / BPS_DENOMINATOR;
    }
}
