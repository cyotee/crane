// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

interface IDiamondFactoryPackageRegistry {
    function deployPackage(bytes calldata initCode, bytes32 salt) external returns (IDiamondFactoryPackage package);

    function deployCanonicalPackage(bytes calldata initCode, bytes32 salt, bytes4 interfaceId)
        external
        returns (IDiamondFactoryPackage package);

    function deployPackageWithArgs(bytes calldata initCode, bytes calldata constructorArgs, bytes32 salt)
        external
        returns (IDiamondFactoryPackage package);

    function deployCanonicalPackageWithArgs(
        bytes calldata initCode,
        bytes calldata constructorArgs,
        bytes32 salt,
        bytes4 interfaceId
    ) external returns (IDiamondFactoryPackage package);

    function registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) external returns (bool);

    function setCanonicalPackage(bytes4 interfaceId, IDiamondFactoryPackage package) external returns (bool);

    function canonicalPackage(bytes4 interfaceId) external view returns (IDiamondFactoryPackage package);

    function allPackages() external view returns (address[] memory packages);

    function nameOfPackage(IDiamondFactoryPackage package) external view returns (string memory);

    function packagesByName(string calldata name) external view returns (address[] memory packages);

    function packagesByInterface(bytes4 interfaceId) external view returns (address[] memory packages);

    function packagesByFacet(IFacet facet) external view returns (address[] memory packages);
}
