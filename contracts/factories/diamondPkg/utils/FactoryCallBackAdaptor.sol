// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* ---------------------------------- Crane --------------------------------- */

import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

/* ----------------------------------- Ham ---------------------------------- */

import {IFactoryCallBack} from "@crane/contracts/interfaces/IFactoryCallBack.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

library FactoryCallBackAdaptor {
    using BetterAddress for address;

    function _initAccount(IFactoryCallBack callBack) internal {
        // bytes memory returnData =
        address(callBack).functionDelegateCall(bytes.concat(IFactoryCallBack.initAccount.selector));
        // (initHash, salt) = abi.decode(returnData, (bytes32, bytes32));
    }
}
