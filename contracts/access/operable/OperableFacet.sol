// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::OperableFacet[]
/**
 * @title OperableFacet - Reusable Diamond facet implementing IOperable (operator-based access control) per Facet-Target-Repo.
 * @author cyotee doge <doge.cyotee>
 * @dev Extends OperableTarget for business logic (delegates to OperableRepo, guarded by MultiStepOwnable). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 *      The facet surface exposes IOperable (isOperator, isOperatorFor, setOperator, setOperatorFor) plus the IFacet declaration methods.
 * @custom:contractlistipfs
 */
contract OperableFacet is OperableTarget, IFacet {
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
    function facetName() public pure returns (string memory name) {
        return type(OperableFacet).name;
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
    function facetInterfaces() public pure virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IOperable).interfaceId;
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
    function facetFuncs() public pure virtual override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = IOperable.isOperator.selector;
        funcs[1] = IOperable.isOperatorFor.selector;
        funcs[2] = IOperable.setOperator.selector;
        funcs[3] = IOperable.setOperatorFor.selector;
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
// end::OperableFacet[]
