// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/**
 * @title OperableFacet - Facet for Diamond proxies to expose IOperable.
 * @author cyotee doge <doge.cyotee>
 * @dev Reusable across proxies.
 * @dev Do not inherit into your own Facets.
 * @dev Include in your Package to reuse deployed Facet.
 */
contract OperableFacet is

    // Some functions are restricted to Owner.
    MultiStepOwnableModifiers,
    OperableTarget,
    IFacet
{
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(OperableFacet).name;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IOperable).interfaceId;
    }

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

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
