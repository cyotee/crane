// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {
    IConfigPositionManager
} from "@crane/contracts/protocols/lending/aave/v4/position-manager/interfaces/IConfigPositionManager.sol";
import {EIP712Types} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/EIP712Types.sol";

/// @title EIP712Helpers
/// @notice EIP-712 typed data hash helpers for ConfigPositionManager tests.
abstract contract EIP712Helpers is Test {
    function _getTypedDataHash(
        IConfigPositionManager _positionManager,
        IConfigPositionManager.SetGlobalPermissionPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(_positionManager, vm.eip712HashStruct(EIP712Types.TYPE_SetGlobalPermissionPermit, abi.encode(_params)));
    }

    function _getTypedDataHash(
        IConfigPositionManager _positionManager,
        IConfigPositionManager.SetCanSetUsingAsCollateralPermissionPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(
            _positionManager, vm.eip712HashStruct(EIP712Types.TYPE_SetCanSetUsingAsCollateralPermissionPermit, abi.encode(_params))
        );
    }

    function _getTypedDataHash(
        IConfigPositionManager _positionManager,
        IConfigPositionManager.SetCanUpdateUserRiskPremiumPermissionPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(
            _positionManager, vm.eip712HashStruct(EIP712Types.TYPE_SetCanUpdateUserRiskPremiumPermissionPermit, abi.encode(_params))
        );
    }

    function _getTypedDataHash(
        IConfigPositionManager _positionManager,
        IConfigPositionManager.SetCanUpdateUserDynamicConfigPermissionPermit memory _params
    ) internal view returns (bytes32) {
        return _typedDataHash(
            _positionManager, vm.eip712HashStruct(EIP712Types.TYPE_SetCanUpdateUserDynamicConfigPermissionPermit, abi.encode(_params))
        );
    }

    function _typedDataHash(IConfigPositionManager _positionManager, bytes32 typeHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _positionManager.DOMAIN_SEPARATOR(), typeHash));
    }
}
