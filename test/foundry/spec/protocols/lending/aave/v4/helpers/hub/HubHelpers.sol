// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfigHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/hub/ConfigHelpers.sol';
import {MockHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/hub/MockHelpers.sol';
import {SetupHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/hub/SetupHelpers.sol';

/// @title HubHelpers
/// @notice Aggregates all hub-level test helpers.
///
/// Inheritance tree:
///   HubHelpers
///   ├── ConfigHelpers
///   │   └── Assertions
///   │       └── QueryHelpers
///   │           ├── CommonHelpers
///   │           ├── Constants
///   │           └── Types
///   ├── SetupHelpers
///   │   └── MathHelpers
///   │       └── QueryHelpers (shared)
///   └── MockHelpers
///       ├── CommonHelpers (shared)
///       └── Constants (shared)
abstract contract HubHelpers is ConfigHelpers, SetupHelpers, MockHelpers {}
