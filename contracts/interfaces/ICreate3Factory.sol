// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

/**
 * @title ICreate2CallbackFactory
 * @author cyotee doge <doge.cyotee>
 * @notice A interface for a CREATE2 callback factory.
 * @notice Exposed to deploy contracts that will callback to get their metadata and initialization data.
 */
interface ICreate3Factory {
    function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory factory);

    function setDiamondPackageFactory(IDiamondPackageCallBackFactory diamondPackageFactory_) external returns (bool);

    function create3(bytes memory initCode, bytes32 salt) external returns (address proxy);

    function create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
        external
        returns (address proxy);

    function deployFacetWithArgs(bytes calldata initCode, bytes calldata initArgs, bytes32 salt)
        external
        returns (IFacet facet);

    function deployFacet(bytes calldata initCode, bytes32 salt) external returns (IFacet facet);

    function deployPackageWithArgs(bytes calldata initCode, bytes calldata constructorArgs, bytes32 salt)
        external
        returns (IDiamondFactoryPackage package);

    function deployPackage(bytes calldata initCode, bytes32 salt) external returns (IDiamondFactoryPackage package);

    function registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        external
        returns (bool);

    function registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) external returns (bool);

    function allFacets() external view returns (address[] memory facetAddresses);

    function facetsOfName(string calldata name) external view returns (address[] memory facetAddresses);

    function facetsOfInterface(bytes4 interfaceId) external view returns (address[] memory facetAddresses);

    function facetsOfFunction(bytes4 functionSelector) external view returns (address[] memory facetAddresses);

    function allPackages() external view returns (address[] memory packages);

    function packagesByName(string calldata name) external view returns (address[] memory packages);

    function packagesByInterface(bytes4 interfaceId) external view returns (address[] memory packages);

    function packagesByFacet(IFacet facet) external view returns (address[] memory packages);
}
