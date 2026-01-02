// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { ISenderGuard } from "@balancer-labs/v3-interfaces/contracts/vault/ISenderGuard.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import { StorageSlotExtension } from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {
    TransientStorageHelpers
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";
import {SenderGuardTarget} from "@crane/contracts/protocols/dexes/balancer/v3/vault/SenderGuardTarget.sol";

/**
 * @notice Abstract base contract for functions shared among all Routers.
 * @dev Common functionality includes access to the sender (which would normally be obscured, since msg.sender in the
 * Vault is the Router contract itself, not the account that invoked the Router), versioning, and the external
 * invocation functions (`permitBatchAndCall` and `multicall`).
 */
contract SenderGuardFacet is SenderGuardTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory name) {
        return type(ISenderGuard).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure override(IFacet) returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISenderGuard).interfaceId;
        return interfaces;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = ISenderGuard.getSender.selector;
        return funcs;
    }
    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]

}
