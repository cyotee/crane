// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IDiamond,
    IDiamondLoupe,
    DiamondStorage
} from "../utils/introspection/erc2535/utils/DiamondStorage.sol";

import {
    ICreate2Aware,
    Create2AwareTarget
} from "../factories/create2/aware/Create2AwareTarget.sol";

/* ---------------------------------- Crane --------------------------------- */

import {
    Proxy
} from "./Proxy.sol";

/* ----------------------------------- Hammer -------------------------------- */

import {
    IFactoryCallBack
} from "../interfaces/IFactoryCallBack.sol";

import {
    FactoryCallBackAdaptor
} from "../factories/create2/callback/diamondPkg/utils/FactoryCallBackAdaptor.sol";

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