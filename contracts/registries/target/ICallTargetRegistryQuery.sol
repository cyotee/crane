// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::ICallTargetRegistryQuery[]
/**
 * @title ICallTargetRegistryQuery
 * @notice Declares call targets for interfaces.
 * @dev Intended to be used a configuration oracle for contracts that need to call other contracts, but want to be able to change the target of those calls without redeploying.
 * @custom:interfaceid 0xb6dd59b7
 */
interface ICallTargetRegistryQuery {
    // tag::defaultCallTargetForID(bytes4)[]
    /**
     * @notice Returns the default call target for a given interface ID.
     * @param interfaceId The ID of the interface for which to return the call target.
     * @return callTarget_ The address of the default call target.
     * @custom:selector 0xd2cfb6ed
     * @custom:signature defaultCallTargetForID(bytes4)
     */
    function defaultCallTargetForID(bytes4 interfaceId) external view returns (address callTarget_);
    // end::defaultCallTargetForID(bytes4)[]

    // tag::callTargetForIDForCaller(bytes4,address)[]
    /**
     * @notice Returns the call target for a given interface ID and caller.
     * @param interfaceId The ID of the interface for which to return the call target.
     * @param caller The address of the caller for which to return the call target.
     * @return callTarget_ The address of the call target.
     * @custom:selector 0x6412ef5a
     * @custom:signature callTargetForIDForCaller(bytes4,address)
     */
    function callTargetForIDForCaller(bytes4 interfaceId, address caller) external view returns (address callTarget_);
    // end::callTargetForIDForCaller(bytes4,address)[]
}
// end::ICallTargetRegistryQuery[]
