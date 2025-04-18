// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IOwnable
} from "../interfaces/IOwnable.sol";

import {
    IOwnableStorage,
    OwnableStorage
} from "../storage/OwnableStorage.sol";

import {
    OwnableTarget
} from "../targets/OwnableTarget.sol";

import {
    IFacet
} from "../../../factories/create2/callback/diamondPkg/interfaces/IFacet.sol";

import {
    Create2CallbackContract
} from "../../../factories/create2/callback/targets/Create2CallbackContract.sol";

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