// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IVault} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol";

// tag::BalancerV3VaultAwareRepo[]
/**
 * @title BalancerV3VaultAwareRepo - Storage library for Balancer V3 vault dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the Balancer V3 IVault.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by Balancer protocol ports (pool factories, services, etc.) for dependency injection of the Balancer V3 vault.
 */
library BalancerV3VaultAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.vault.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("protocols.dexes.balancer.v3.vault.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for balancer v3 vault reference (Aware).
     *      balancerV3Vault: reference to IVault.
     */
    struct Storage {
        IVault balancerV3Vault;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-IVault)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param vault_ The IVault instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IVault vault_) internal {
        layoutStruct.balancerV3Vault = vault_;
    }
    // end::_initialize(Storage-IVault)[]

    // tag::_initialize(IVault)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param vault_ The IVault instance to inject.
     */
    function _initialize(IVault vault_) internal {
        _initialize(_layoutStruct(), vault_);
    }
    // end::_initialize(IVault)[]

    // tag::_balancerV3Vault(Storage)[]
    /**
     * @dev Argumented version of _balancerV3Vault to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return vault_ The stored IVault (or zero if not initialized).
     */
    function _balancerV3Vault(Storage storage layoutStruct)
        internal
        view
        returns (IVault vault_)
    {
        return layoutStruct.balancerV3Vault;
    }
    // end::_balancerV3Vault(Storage)[]

    // tag::_balancerV3Vault()[]
    /**
     * @dev Default version of _balancerV3Vault binding to the standard STORAGE_SLOT.
     * @return vault_ The stored IVault.
     */
    function _balancerV3Vault() internal view returns (IVault vault_) {
        return _balancerV3Vault(_layoutStruct());
    }
    // end::_balancerV3Vault()[]
}
// end::BalancerV3VaultAwareRepo[]
