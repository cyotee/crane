// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}
