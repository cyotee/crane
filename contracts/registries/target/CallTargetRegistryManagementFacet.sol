// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Imports                                  */
/* -------------------------------------------------------------------------- */

/* --------------------------- Imported Interfaces -------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";

/* --------------------------- Imported Contracts --------------------------- */

import {
    CallTargetRegistryManagementTarget
} from "@crane/contracts/registries/target/CallTargetRegistryManagementTarget.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

// tag::CallTargetRegistryManagementFacet[]
/**
 * @title CallTargetRegistryManagementFacet - Reusable Diamond facet providing management (write) access to the CallTargetRegistry (default and caller-specific targets per interface ID).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends CallTargetRegistryManagementTarget for business logic (onlyOwner protected sets to CallTargetRegistryRepo). Implements IFacet (via FacetBase) to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract CallTargetRegistryManagementFacet is CallTargetRegistryManagementTarget, FacetBase {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure override returns (string memory name) {
        return type(CallTargetRegistryManagementFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICallTargetRegistryManagement).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = ICallTargetRegistryManagement.setDefaultCallTargetForID.selector;
        funcs[1] = ICallTargetRegistryManagement.setCallTargetForIDForCaller.selector;
    }
    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
     */
    function facetMetadata()
        public
        pure
        override
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::CallTargetRegistryManagementFacet[]
