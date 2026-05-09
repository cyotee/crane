// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712Helpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/tokenization-spoke/EIP712Helpers.sol';
import {Assertions} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/tokenization-spoke/Assertions.sol';
import {SetupHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/tokenization-spoke/SetupHelpers.sol';

/// @title TokenizationSpokeHelpers
/// @notice Aggregates all tokenization spoke test helpers.
///
/// Inheritance tree:
///   TokenizationSpokeHelpers
///   ├── EIP712Helpers
///   │   └── Test
///   ├── Assertions
///   │   └── SpokeHelpers
///   └── SetupHelpers
///       └── SpokeHelpers (shared)
abstract contract TokenizationSpokeHelpers is EIP712Helpers, Assertions, SetupHelpers {}
