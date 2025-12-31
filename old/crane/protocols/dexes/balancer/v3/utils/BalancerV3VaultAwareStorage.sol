// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3VaultAware} from "contracts/crane/interfaces/IBalancerV3VaultAware.sol";

struct BalancerV3VaultAwareLayout {
    IVault vault;
}

library BalancerV3VaultAwareRepo {
    function layout(bytes32 slot_) internal pure returns (BalancerV3VaultAwareLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
}

contract BalancerV3VaultAwareStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using BalancerV3VaultAwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant _LAYOUT_ID = keccak256(abi.encode(type(BalancerV3VaultAwareRepo).name));
    bytes32 private constant _STORAGE_RANGE_OFFSET = bytes32(uint256(keccak256(abi.encode(_LAYOUT_ID))) - 1);
    bytes32 private constant _STORAGE_RANGE = type(IBalancerV3VaultAware).interfaceId;
    bytes32 private constant _STORAGE_SLOT = keccak256(abi.encode(_STORAGE_RANGE, _STORAGE_RANGE_OFFSET));

    // tag::_balV3VaultAware()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _balV3VaultAware() internal pure virtual returns (BalancerV3VaultAwareLayout storage) {
        return _STORAGE_SLOT.layout();
    }
    // end::_balV3VaultAware()[]

    function _initBalancerV3VaultAware(IVault vault_) internal {
        _balV3VaultAware().vault = vault_;
    }

    function _balV3Vault() internal view returns (IVault) {
        return _balV3VaultAware().vault;
    }
}
