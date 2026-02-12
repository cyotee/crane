// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

interface IFactoryCallBack {
    function initAccount() external returns (bool);

    function pkgConfig() external view returns (IDiamondFactoryPackage pkg, bytes memory args);
}
