// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* ---------------------------------- Crane --------------------------------- */

import {Address} from "../../../../../../utils/primitives/Address.sol";

/* ----------------------------------- Ham ---------------------------------- */

import {IFactoryCallBack} from "../../interfaces/IFactoryCallBack.sol";

library FactoryCallBackAdaptor {

    using Address for address;

    function _initAccount(
        IFactoryCallBack callBack
    ) internal returns(
        bytes32 initHash,
        bytes32 salt
    ) {
        bytes memory returnData = address(callBack)
            ._delegateCall(
                IFactoryCallBack.initAccount.selector
            );
        (
            initHash,
            salt
        ) = abi.decode(
            returnData,
            (bytes32, bytes32)
        );
    }

}
