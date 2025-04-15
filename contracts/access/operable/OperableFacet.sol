// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IOperable
} from "../../interfaces/IOperable.sol";

import {
    IOperableStorage,
    OperableStorage
} from "./utils/OperableStorage.sol";

import {
    OperableTarget
} from "./OperableTarget.sol";

import {
    IFacet
} from "../../interfaces/IFacet.sol";

import {
    Create3AwareContract
} from "../../factories/create2/aware/Create3AwareContract.sol";
import {
    ICreate3Aware
} from "../../interfaces/ICreate3Aware.sol";


/**
 * @title OperatableFacet - Facet for Diamond proxies to expose IOwnable and IOperatable.
 * @author cyotee doge <doge.cyotee>
 */
contract OperableFacet
is
OperableTarget,
Create3AwareContract,
IFacet
{

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        // No additional initialization needed for facets
    }

    // /**
    //  * @inheritdoc IFacet
    //  */
    // function supportedInterfaces()
    // public view virtual override returns(bytes4[] memory interfaces) {
    //     interfaces =  new bytes4[](2);
    //     interfaces[0] = type(IOwnable).interfaceId;
    //     interfaces[1] = type(IOperatable).interfaceId;
    // }

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces()
    public view virtual override returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](1);
        // interfaces[0] = type(IOwnable).interfaceId;
        interfaces[0] = type(IOperable).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs()
    public view virtual override returns(bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        // funcs[0] = IOwnable.owner.selector;
        // funcs[1] = IOwnable.proposedOwner.selector;
        // funcs[2] = IOwnable.transferOwnership.selector;
        // funcs[3] = IOwnable.acceptOwnership.selector;
        // funcs[4] = IOwnable.renounceOwnership.selector;
        funcs[0] = IOperable.isOperator.selector;
        funcs[1] = IOperable.isOperatorFor.selector;
        funcs[2] = IOperable.setOperator.selector;
        funcs[3] = IOperable.setOperatorFor.selector;
    }

}
