// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';

library TokenTransferRelayerRepo {

    bytes32 internal constant STORAGE_SLOT = keccak256('crane.protocols.l2s.superchain.relayers.token');

    struct Storage {
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry;
    }

    // tag::_layout(bytes32)[]
    /**
     * @dev Argumented version of _layout to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layout The bound Storage struct.
     */
    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }
    // end::_layout(bytes32)[]

    // tag::_layout()[]
    /**
     * @dev Default version of _layout binding to the standard STORAGE_SLOT.
     * @return layout The bound Storage struct.
     */
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }
    // end::_layout()[]

    function _initialize(Storage storage layout, IApprovedMessageSenderRegistry approvedMessageSenderRegistry) internal {
        layout.approvedMessageSenderRegistry = approvedMessageSenderRegistry;
    }

    function _initialize(IApprovedMessageSenderRegistry approvedMessageSenderRegistry) internal {
        _initialize(_layout(), approvedMessageSenderRegistry);
    }

    function _approvedMessageSenderRegistry(Storage storage layout) internal view returns (IApprovedMessageSenderRegistry) {
        return layout.approvedMessageSenderRegistry;
    }

    function _approvedMessageSenderRegistry() internal view returns (IApprovedMessageSenderRegistry) {
        return _approvedMessageSenderRegistry(_layout());
    }

}