// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "./PoolKey.sol";

/// @title PoolId
/// @notice Unique identifier for a V4 pool, derived from hashing the PoolKey
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
type PoolId is bytes32;

using PoolIdLibrary for PoolKey;

/// @notice Library for computing the ID of a pool
library PoolIdLibrary {
    /// @notice Returns value equal to keccak256(abi.encode(poolKey))
    function toId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            // 0xa0 represents the total size of the poolKey struct (5 slots of 32 bytes)
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}
