// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IDiamond,
    IDiamondLoupe,
    DiamondStorage
} from "../introspection/erc2535/storage/DiamondStorage.sol";

import {
    ICreate2Aware,
    Create2AwareTarget
} from "../factories/create2/aware/targets/Create2AwareTarget.sol";

/* ---------------------------------- Crane --------------------------------- */

import {
    Proxy
} from "./Proxy.sol";

/* ----------------------------------- Hammer -------------------------------- */

import {
    IFactoryCallBack
} from "../factories/create2/callback/diamondPkg/interfaces/IFactoryCallBack.sol";

import {
    FactoryCallBackAdaptor
} from "../factories/create2/callback/diamondPkg/libs/utils/FactoryCallBackAdaptor.sol";

contract MinimalDiamondCallBackProxy
is
Proxy
,DiamondStorage
,Create2AwareTarget
{

    using FactoryCallBackAdaptor for IFactoryCallBack;

    constructor() {
        (
            bytes32 initcodeHash,
            bytes32 salt
        ) = IFactoryCallBack(msg.sender)._initAccount();
        ORIGIN = msg.sender;
        INITCODE_HASH = initcodeHash;
        SALT = salt;
    }

    function _getTarget()
    internal virtual override returns (address target_) {
        return _facetAddress(msg.sig);
    }

}