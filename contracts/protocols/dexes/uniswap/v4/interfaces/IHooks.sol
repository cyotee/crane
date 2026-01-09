// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IHooks
/// @notice Interface for V4 pool hooks
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
/// @dev This is a minimal interface for PoolKey compatibility
interface IHooks {
    // Hooks can implement various callbacks, but for the purposes of
    // our quoting library, we only need the interface to exist for PoolKey
}
