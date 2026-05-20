// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';

library TokenTransferRelayerRepo {

    bytes32 internal constant STORAGE_SLOT = keccak256('crane.protocols.l2s.superchain.relayers.token');

    struct Storage {
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry;
    }

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    function _initialize(Storage storage layoutStruct, IApprovedMessageSenderRegistry approvedMessageSenderRegistry) internal {
        layoutStruct.approvedMessageSenderRegistry = approvedMessageSenderRegistry;
    }

    function _initialize(IApprovedMessageSenderRegistry approvedMessageSenderRegistry) internal {
        _initialize(_layoutStruct(), approvedMessageSenderRegistry);
    }

    function _approvedMessageSenderRegistry(Storage storage layoutStruct) internal view returns (IApprovedMessageSenderRegistry) {
        return layoutStruct.approvedMessageSenderRegistry;
    }

    function _approvedMessageSenderRegistry() internal view returns (IApprovedMessageSenderRegistry) {
        return _approvedMessageSenderRegistry(_layoutStruct());
    }

}