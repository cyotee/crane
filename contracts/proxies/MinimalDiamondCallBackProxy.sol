// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";

// import {ICreate2Aware, Create2AwareTarget} from "@crane/contracts/factories/create2/aware/Create2AwareTarget.sol";

/* ---------------------------------- Crane --------------------------------- */

import {Proxy} from "./Proxy.sol";

/* ----------------------------------- Hammer -------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {IFactoryCallBack} from "@crane/contracts/interfaces/IFactoryCallBack.sol";

import {FactoryCallBackAdaptor} from "@crane/contracts/factories/diamondPkg/utils/FactoryCallBackAdaptor.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";

contract MinimalDiamondCallBackProxy is Proxy {
    using FactoryCallBackAdaptor for IFactoryCallBack;

    constructor() {
        // (bytes32 initcodeHash, bytes32 salt) =
        // console.log("MinimalDiamondCallBackProxy deployed, initializing via IFactoryCallBack");
        IFactoryCallBack(msg.sender)._initAccount();
        // ORIGIN = msg.sender;
        // INITCODE_HASH = initcodeHash;
        // SALT = salt;
    }

    function _getTarget() internal virtual override returns (address target_) {
        return ERC2535Repo._facetAddress(msg.sig);
    }
}
