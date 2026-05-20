// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

library ERC4626RateProviderRepo {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("crane.contracts.protocols.dexes.balancer.v3.rateProviders.erc4626");

    struct Storage {
        IERC4626 erc4626Vault;
        uint8 assetDecimals;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct_, IERC4626 erc4626Vault_, uint8 assetDecimals) internal {
        layoutStruct_.erc4626Vault = erc4626Vault_;
        layoutStruct_.assetDecimals = assetDecimals;
    }

    function _initialize(IERC4626 erc4626Vault_, uint8 assetDecimals) internal {
        _initialize(_layoutStruct(), erc4626Vault_, assetDecimals);
    }

    function _erc4626Vault(Storage storage layoutStruct_) internal view returns (IERC4626) {
        return layoutStruct_.erc4626Vault;
    }

    function _erc4626Vault() internal view returns (IERC4626) {
        return _erc4626Vault(_layoutStruct());
    }

    function _assetDecimals(Storage storage layoutStruct_) internal view returns (uint8) {
        return layoutStruct_.assetDecimals;
    }

    function _assetDecimals() internal view returns (uint8) {
        return _assetDecimals(_layoutStruct());
    }
}
