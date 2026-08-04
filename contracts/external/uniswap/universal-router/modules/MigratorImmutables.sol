// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {INonfungiblePositionManager} from '@crane/contracts/external/uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import {IPositionManager} from '@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPositionManager.sol';
import {IPoolManager} from '@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol';

struct MigratorParameters {
    address v3PositionManager;
    address v4PositionManager;
}

/// @title Migrator Immutables
/// @notice Immutable state for liquidity-migration contracts
contract MigratorImmutables {
    /// @notice v3 PositionManager address
    INonfungiblePositionManager public immutable V3_POSITION_MANAGER;
    /// @notice v4 PositionManager address
    IPositionManager public immutable V4_POSITION_MANAGER;

    constructor(MigratorParameters memory params) {
        V3_POSITION_MANAGER = INonfungiblePositionManager(params.v3PositionManager);
        V4_POSITION_MANAGER = IPositionManager(params.v4PositionManager);
    }
}
