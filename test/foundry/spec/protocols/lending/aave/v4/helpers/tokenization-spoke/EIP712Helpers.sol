// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {ITokenizationSpoke} from '@crane/contracts/protocols/lending/aave/v4/spoke/TokenizationSpoke.sol';
import {EIP712Types} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/EIP712Types.sol';

/// @title EIP712Helpers
/// @notice EIP-712 typed data hash utilities for tokenization spoke tests.
abstract contract EIP712Helpers is Test {
  function _getTypedDataHash(
    ITokenizationSpoke vault,
    ITokenizationSpoke.TokenizedDeposit memory params
  ) internal view returns (bytes32) {
    return _typedDataHash(vault, vm.eip712HashStruct('TokenizedDeposit', abi.encode(params)));
  }

  function _getTypedDataHash(
    ITokenizationSpoke vault,
    ITokenizationSpoke.TokenizedMint memory params
  ) internal view returns (bytes32) {
    return _typedDataHash(vault, vm.eip712HashStruct('TokenizedMint', abi.encode(params)));
  }

  function _getTypedDataHash(
    ITokenizationSpoke vault,
    ITokenizationSpoke.TokenizedWithdraw memory params
  ) internal view returns (bytes32) {
    return _typedDataHash(vault, vm.eip712HashStruct('TokenizedWithdraw', abi.encode(params)));
  }

  function _getTypedDataHash(
    ITokenizationSpoke vault,
    ITokenizationSpoke.TokenizedRedeem memory params
  ) internal view returns (bytes32) {
    return _typedDataHash(vault, vm.eip712HashStruct('TokenizedRedeem', abi.encode(params)));
  }

  function _getTypedDataHash(
    ITokenizationSpoke vault,
    EIP712Types.Permit memory params
  ) internal view returns (bytes32) {
    return _typedDataHash(vault, vm.eip712HashStruct('Permit', abi.encode(params)));
  }

  function _typedDataHash(
    ITokenizationSpoke vault,
    bytes32 typeHash
  ) internal view returns (bytes32) {
    return keccak256(abi.encodePacked('\x19\x01', vault.DOMAIN_SEPARATOR(), typeHash));
  }
}
