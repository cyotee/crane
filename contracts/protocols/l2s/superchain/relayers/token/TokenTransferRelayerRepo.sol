// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IApprovedMessageSenderRegistry} from "@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::TokenTransferRelayerRepo[]
/**
 * @title TokenTransferRelayerRepo
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage library for Superchain token transfer relayer (holds approved message sender registry reference).
 * @dev Implements the Repo tier of the Facet-Target-Repo pattern for TokenTransferRelayer.
 *      All functions have dual overloads: parameterized (explicit `Storage storage layoutStruct`) and default
 *      (using the internal ERC1967 STORAGE_SLOT). Follows gold standards from SuperChainBridgeTokenRegistryRepo,
 *      ApprovedMessageSenderRegistryRepo, MultiStepOwnableRepo, OperableRepo, ERC2535Repo.
 * @dev This library is intended for internal use by the corresponding Target/Facet and related services
 *      (TokenTransferRelayerTarget, TokenTransferRelayerFactoryService, TokenTransferRelayerDFPkg).
 *      Initialization is typically performed via package initAccount delegatecall (higher layers).
 */
library TokenTransferRelayerRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.relayers.token"))) - 1).
     *      This follows the canonical pattern used by SuperChainBridgeTokenRegistryRepo, ApprovedMessageSenderRegistryRepo,
     *      OperableRepo, MultiStepOwnableRepo, ERC2535Repo, FacetRegistryRepo and other gold-standard Repos for
     *      collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.relayers.token"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Storage layout for Superchain token transfer relayer.
     *      approvedMessageSenderRegistry: reference to the IApprovedMessageSenderRegistry used to gate
     *      cross-chain token relay operations.
     */
    struct Storage {
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Parameterized _layoutStruct allowing custom slot (for testing or special cases).
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

    // tag::_initialize(Storage-IApprovedMessageSenderRegistry)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param approvedMessageSenderRegistry The registry of approved cross-domain message senders for relays.
     */
    function _initialize(Storage storage layoutStruct, IApprovedMessageSenderRegistry approvedMessageSenderRegistry)
        internal
    {
        layoutStruct.approvedMessageSenderRegistry = approvedMessageSenderRegistry;
    }
    // end::_initialize(Storage-IApprovedMessageSenderRegistry)[]

    // tag::_initialize(IApprovedMessageSenderRegistry)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param approvedMessageSenderRegistry The registry of approved cross-domain message senders for relays.
     */
    function _initialize(IApprovedMessageSenderRegistry approvedMessageSenderRegistry) internal {
        _initialize(_layoutStruct(), approvedMessageSenderRegistry);
    }
    // end::_initialize(IApprovedMessageSenderRegistry)[]

    // tag::_approvedMessageSenderRegistry(Storage)[]
    /**
     * @dev Argumented version of _approvedMessageSenderRegistry to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return approvedMessageSenderRegistry The configured approved message sender registry.
     */
    function _approvedMessageSenderRegistry(Storage storage layoutStruct)
        internal
        view
        returns (IApprovedMessageSenderRegistry)
    {
        return layoutStruct.approvedMessageSenderRegistry;
    }
    // end::_approvedMessageSenderRegistry(Storage)[]

    // tag::_approvedMessageSenderRegistry()[]
    /**
     * @dev Default version of _approvedMessageSenderRegistry binding to the standard STORAGE_SLOT.
     * @return approvedMessageSenderRegistry The configured approved message sender registry.
     */
    function _approvedMessageSenderRegistry() internal view returns (IApprovedMessageSenderRegistry) {
        return _approvedMessageSenderRegistry(_layoutStruct());
    }
    // end::_approvedMessageSenderRegistry()[]
}
// end::TokenTransferRelayerRepo[]
