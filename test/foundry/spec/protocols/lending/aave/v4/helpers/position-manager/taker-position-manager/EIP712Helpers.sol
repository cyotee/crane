// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {
    ITakerPositionManager
} from "@crane/contracts/protocols/lending/aave/v4/position-manager/interfaces/ITakerPositionManager.sol";
import {EIP712Types} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/EIP712Types.sol";

/// @title EIP712Helpers
/// @notice EIP-712 typed data hash helpers for TakerPositionManager tests.
abstract contract EIP712Helpers is Test {
    function _getTypedDataHash(
        ITakerPositionManager _positionManager,
        ITakerPositionManager.WithdrawPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(_positionManager, vm.eip712HashStruct(EIP712Types.TYPE_WithdrawPermit, abi.encode(_params)));
    }

    function _getTypedDataHash(
        ITakerPositionManager _positionManager,
        ITakerPositionManager.BorrowPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(_positionManager, vm.eip712HashStruct(EIP712Types.TYPE_BorrowPermit, abi.encode(_params)));
    }

    function _typedDataHash(ITakerPositionManager _positionManager, bytes32 typeHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _positionManager.DOMAIN_SEPARATOR(), typeHash));
    }
}
