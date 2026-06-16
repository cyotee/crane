// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {
    ISignatureGateway
} from "@crane/contracts/protocols/lending/aave/v4/position-manager/interfaces/ISignatureGateway.sol";
import {EIP712Types} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/EIP712Types.sol";

/// @title EIP712Helpers
/// @notice EIP-712 typed data hash helpers for SignatureGateway tests.
abstract contract EIP712Helpers is Test {
    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.Supply memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_Supply, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.Withdraw memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_Withdraw, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.Borrow memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_Borrow, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.Repay memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_Repay, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.SetUsingAsCollateral memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_SetUsingAsCollateral, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.UpdateUserRiskPremium memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_UpdateUserRiskPremium, abi.encode(_params)));
    }

    function _getTypedDataHash(ISignatureGateway _gateway, ISignatureGateway.UpdateUserDynamicConfig memory _params)
        internal
        view
        returns (bytes32)
    {
        return _typedDataHash(_gateway, vm.eip712HashStruct(EIP712Types.TYPE_UpdateUserDynamicConfig, abi.encode(_params)));
    }

    function _typedDataHash(ISignatureGateway _gateway, bytes32 typeHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _gateway.DOMAIN_SEPARATOR(), typeHash));
    }
}
