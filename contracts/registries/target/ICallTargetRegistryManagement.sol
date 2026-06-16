// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::ICallTargetRegistryManagement[]
/**
 * @title ICallTargetRegistryManagement
 * @notice Declares management functions for call targets.
 * @dev Intended to be used by authorized actors to update call target configurations.
 * @custom:interfaceid 0x9400c76a
 */
interface ICallTargetRegistryManagement {
    // tag::setDefaultCallTargetForID(bytes4,address)[]
    /**
     * @notice Sets the default call target for a given interface ID.
     * @param interfaceId The ID of the interface for which to set the call target.
     * @param callTarget The address of the call target to set.
     * @return success_ A boolean indicating whether the operation was successful.
     * @custom:selector 0xaf87fa1d
     * @custom:signature setDefaultCallTargetForID(bytes4,address)
     */
    function setDefaultCallTargetForID(bytes4 interfaceId, address callTarget) external returns (bool success_);
    // end::setDefaultCallTargetForID(bytes4,address)[]

    // tag::setCallTargetForIDForCaller(bytes4,address,address)[]
    /**
     * @notice Sets the call target for a given interface ID and caller.
     * @param interfaceId The ID of the interface for which to set the call target.
     * @param callTarget The address of the call target to set.
     * @param caller The address of the caller for which to set the call target.
     * @return success_ A boolean indicating whether the operation was successful.
     * @custom:selector 0x3b873d77
     * @custom:signature setCallTargetForIDForCaller(bytes4,address,address)
     */
    function setCallTargetForIDForCaller(bytes4 interfaceId, address callTarget, address caller)
        external
        returns (bool success_);
    // end::setCallTargetForIDForCaller(bytes4,address,address)[]
}
// end::ICallTargetRegistryManagement[]
