// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IVault} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol";

library BalancerV3VaultAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.aware");

    struct Storage {
        IVault balancerV3Vault;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, IVault vault) internal {
        layout.balancerV3Vault = vault;
    }

    function _initialize(IVault vault) internal {
        _initialize(_layout(), vault);
    }

    function _balancerV3Vault(Storage storage layout) internal view returns (IVault) {
        return layout.balancerV3Vault;
    }

    function _balancerV3Vault() internal view returns (IVault vault) {
        return _balancerV3Vault(_layout());
    }
}