// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

interface ICreate3FactoryBootstrap {
    function initFactory() external returns (bool);
    function deployCanonicalFacet(bytes calldata initCode, bytes32 salt) external returns (IFacet facet);
    function deployCanonicalPackageWithArgs(bytes calldata initCode, bytes calldata constructorArgs, bytes32 salt, bytes4 interfaceId)
        external
        returns (IDiamondFactoryPackage package);
}
