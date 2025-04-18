// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IDiamondFactoryPackage
} from "./IDiamondFactoryPackage.sol";

interface IDiamondPackageCallBackFactory {

    function PROXY_INIT_HASH()
    external view returns(bytes32);

    function pkgOfAccount(
        address account
    ) external view returns(IDiamondFactoryPackage pkg);

    function pkgArgsOfAccount(
        address account
    ) external view returns(bytes memory);

    function create2SaltOfAccount(
        address account
    ) external view returns(bytes32);

    function deploy(
        IDiamondFactoryPackage pkg,
        bytes memory pkgArgs
    ) external returns(address proxy);

}
