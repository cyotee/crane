// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IVault} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol";

library BalancerV3VaultAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.aware");

    struct Storage {
        IVault balancerV3Vault;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IVault vault) internal {
        layoutStruct.balancerV3Vault = vault;
    }

    function _initialize(IVault vault) internal {
        _initialize(_layoutStruct(), vault);
    }

    function _balancerV3Vault(Storage storage layoutStruct) internal view returns (IVault) {
        return layoutStruct.balancerV3Vault;
    }

    function _balancerV3Vault() internal view returns (IVault vault) {
        return _balancerV3Vault(_layoutStruct());
    }
}
