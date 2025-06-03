// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IOperable,
    OperableTarget
} from "./OperableTarget.sol";

import {
    IOwnable,
    OwnableTarget
} from "../ownable/OwnableTarget.sol";

import {
    IFacet
} from "../../interfaces/IFacet.sol";

/**
 * @title OperatableFacet - Facet for Diamond proxies to expose IOwnable and IOperatable.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableEmbeddedOwnableFacet
is
OperableTarget
,OwnableTarget
,IFacet
{

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces()
    public view virtual override returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](2);
        interfaces[0] = type(IOwnable).interfaceId;
        interfaces[1] = type(IOperable).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs()
    public view virtual override returns(bytes4[] memory funcs) {
        funcs = new bytes4[](7);
        funcs[0] = IOwnable.owner.selector;
        funcs[1] = IOwnable.proposedOwner.selector;
        funcs[2] = IOwnable.transferOwnership.selector;
        funcs[3] = IOwnable.acceptOwnership.selector;
        funcs[4] = IOwnable.renounceOwnership.selector;
        funcs[5] = IOperable.isOperator.selector;
        funcs[6] = IOperable.setOperator.selector;
    }

}