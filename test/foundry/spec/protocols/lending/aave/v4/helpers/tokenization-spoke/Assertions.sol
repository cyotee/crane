// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SpokeHelpers} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/spoke/SpokeHelpers.sol';
import {IERC20} from '@crane/contracts/protocols/lending/aave/v4/dependencies/openzeppelin/SafeERC20.sol';
import {ITokenizationSpoke} from '@crane/contracts/protocols/lending/aave/v4/spoke/TokenizationSpoke.sol';

/// @title Assertions
/// @notice Assertion utilities for tokenization spoke tests.
abstract contract Assertions is SpokeHelpers {
  function _assertVaultHasNoBalanceOrAllowance(ITokenizationSpoke vault, address who) internal view {
    _assertEntityHasNoBalanceOrAllowance({
      underlying: IERC20(vault.asset()),
      entity: address(vault),
      user: who
    });
  }
}
