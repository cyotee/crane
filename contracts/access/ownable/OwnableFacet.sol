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
    Create2CallbackContract
} from "../../factories/create2/callback/Create2CallbackContract.sol";

contract OwnableFacet
is
OwnableTarget,
Create2CallbackContract
,IFacet
{

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