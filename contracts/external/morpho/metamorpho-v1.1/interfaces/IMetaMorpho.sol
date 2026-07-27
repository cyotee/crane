// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// Compatibility alias for Public Allocator and other V1.0-named consumers.
// Crane vendors MetaMorpho V1.1; this file re-exports V1.1 types under historical names.

import {
    MarketAllocation,
    IMetaMorphoV1_1Base,
    IMetaMorphoV1_1StaticTyping,
    IMetaMorphoV1_1
} from "./IMetaMorphoV1_1.sol";

import {Id, MarketParams, IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

/// @dev Alias for integrators expecting `IMetaMorpho` (MetaMorpho V1.x naming).
interface IMetaMorpho is IMetaMorphoV1_1 {}
