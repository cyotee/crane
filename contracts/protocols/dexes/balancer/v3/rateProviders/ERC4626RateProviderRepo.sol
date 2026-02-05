// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

library ERC4626RateProviderRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.contracts.protocols.dexes.balancer.v3.rateProviders.erc4626");

    struct Storage {
        IERC4626 erc4626Vault;
        uint8 assetDecimals;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout_, IERC4626 erc4626Vault_, uint8 assetDecimals) internal {
        layout_.erc4626Vault = erc4626Vault_;
        layout_.assetDecimals = assetDecimals;
    }

    function _initialize(IERC4626 erc4626Vault_, uint8 assetDecimals) internal {
        _initialize(_layout(), erc4626Vault_, assetDecimals);
    }

    function _erc4626Vault(Storage storage layout_) internal view returns (IERC4626) {
        return layout_.erc4626Vault;
    }

    function _erc4626Vault() internal view returns (IERC4626) {
        return _erc4626Vault(_layout());
    }

    function _assetDecimals(Storage storage layout_) internal view returns (uint8) {
        return layout_.assetDecimals;
    }

    function _assetDecimals() internal view returns (uint8) {
        return _assetDecimals(_layout());
    }
}