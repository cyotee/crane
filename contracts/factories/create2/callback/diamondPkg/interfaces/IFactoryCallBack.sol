// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IDiamondFactoryPackage
} from "./IDiamondFactoryPackage.sol";

interface IFactoryCallBack {

    function initAccount()
    external returns(
        bytes32 initHash,
        bytes32 salt
    );

    function pkgConfig()
    external view returns(
        IDiamondFactoryPackage pkg,
        bytes memory args
    );
}
