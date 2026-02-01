// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "./IPoolManager.sol";

/// @title IImmutableState
/// @notice Interface for the ImmutableState contract
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
interface IImmutableState {
    /// @notice The Uniswap v4 PoolManager contract
    function poolManager() external view returns (IPoolManager);
}
