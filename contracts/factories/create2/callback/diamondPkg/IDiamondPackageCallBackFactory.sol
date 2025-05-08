// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

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
