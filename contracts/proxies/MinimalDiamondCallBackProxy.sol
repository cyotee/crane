// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "contracts/interfaces/IDiamondLoupe.sol";

import {ICreate2Aware, Create2AwareTarget} from "contracts/factories/create2/aware/Create2AwareTarget.sol";

/* ---------------------------------- Crane --------------------------------- */

import {Proxy} from "./Proxy.sol";

/* ----------------------------------- Hammer -------------------------------- */

import {IFactoryCallBack} from "contracts/interfaces/IFactoryCallBack.sol";

import {FactoryCallBackAdaptor} from "contracts/factories/create2/callback/diamondPkg/utils/FactoryCallBackAdaptor.sol";
import {ERC2535Repo} from "contracts/introspection/ERC2535/ERC2535Repo.sol";

contract MinimalDiamondCallBackProxy is Proxy, Create2AwareTarget {
    using FactoryCallBackAdaptor for IFactoryCallBack;

    constructor() {
        (bytes32 initcodeHash, bytes32 salt) = IFactoryCallBack(msg.sender)._initAccount();
        ORIGIN = msg.sender;
        INITCODE_HASH = initcodeHash;
        SALT = salt;
    }

    function _getTarget() internal virtual override returns (address target_) {
        return ERC2535Repo._facetAddress(msg.sig);
    }
}
