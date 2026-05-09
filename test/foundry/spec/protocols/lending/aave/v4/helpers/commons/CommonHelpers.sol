// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AssertionHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/commons/AssertionHelpers.sol';
import {MathHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/commons/MathHelpers.sol';
import {ProxyHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/commons/ProxyHelpers.sol';
import {SetupHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/commons/SetupHelpers.sol';

/// @title CommonHelpers
/// @notice Aggregates all commons-level test helpers.
///
/// Inheritance tree:
///   CommonHelpers
///   ├── AssertionHelpers
///   │   └── Test
///   ├── MathHelpers
///   ├── SetupHelpers
///   │   └── Test
///   └── ProxyHelpers
abstract contract CommonHelpers is AssertionHelpers, MathHelpers, SetupHelpers, ProxyHelpers {}
