// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

// tag::OperableFacet[]
/**
 * @title OperableFacet - Facet for Diamond proxies to expose IOperable.
 * @author cyotee doge <doge.cyotee>
 * @dev Reusable across proxies.
 * @dev Do not inherit into your own Facets.
 * @dev Include in your Package to reuse the deployed Facet.
 */
contract OperableFacet is
    OperableTarget,
    IFacet
{
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory name) {
        return type(OperableFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IOperable).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
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