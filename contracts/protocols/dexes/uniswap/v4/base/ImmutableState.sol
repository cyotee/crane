// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IImmutableState} from "../interfaces/IImmutableState.sol";

/// @title Immutable State
/// @notice A collection of immutable state variables, commonly used across multiple contracts
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
contract ImmutableState is IImmutableState {
    /// @inheritdoc IImmutableState
    IPoolManager public immutable poolManager;

    /// @notice Thrown when the caller is not PoolManager
    error NotPoolManager();

    /// @notice Only allow calls from the PoolManager contract
    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }
}
