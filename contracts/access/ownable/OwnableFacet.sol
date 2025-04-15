// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IOwnable
} from "../../interfaces/IOwnable.sol";

import {
    IOwnableStorage,
    OwnableStorage
} from "./utils/OwnableStorage.sol";

import {
    OwnableTarget
} from "./OwnableTarget.sol";

import {
    IFacet
} from "../../interfaces/IFacet.sol";

import {
    Create3AwareContract
} from "../../factories/create2/aware/Create3AwareContract.sol";
import {
    ICreate3Aware
} from "../../interfaces/ICreate3Aware.sol";

contract OwnableFacet
is
OwnableTarget,
Create3AwareContract
,IFacet
{

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        // No additional initialization needed for facets
    }

    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces()
    public pure virtual returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](1);
        interfaces[0] = type(IOwnable).interfaceId;
    }

    /**
     * @inheritdoc IFacet
     */
    function facetFuncs()
    public pure virtual returns(bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = IOwnable.owner.selector;
        funcs[1] = IOwnable.proposedOwner.selector;
        funcs[2] = IOwnable.transferOwnership.selector;
        funcs[3] = IOwnable.acceptOwnership.selector;
        funcs[4] = IOwnable.renounceOwnership.selector;
    }

}