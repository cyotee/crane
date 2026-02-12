// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {Creation} from "@crane/contracts/utils/Creation.sol";
import {MultiStepOwnableTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableTarget.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";

/**
 * @title Create2CallBackFactory
 * @author cyotee doge <doge.cyotee>
 * @notice A factory contract that allows a contract to exepose it's initialization data.
 * @notice Provided to enable deterministic deployments regardless of initialization data.
 * @notice Include
 */
contract Create3Factory is

    // Include the ownership management.
    // This includes the onwership modifiers.
    MultiStepOwnableTarget,
    OperableModifiers,
    // Include the operability management.
    OperableTarget,
    // Include the factory interface.
    ICreate3Factory
{
    using Address for address;
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;
    using BetterEfficientHashLib for bytes;

    IDiamondPackageCallBackFactory public diamondPackageFactory;

    mapping(IFacet facet => string name) public nameOfFacet;
    mapping(IFacet facet => bytes4[] interfaces) public interfacesOfFacet;
    mapping(IFacet facet => bytes4[] functions) public functionsOfFacet;

    mapping(IDiamondFactoryPackage package => string name) public nameOfPackage;
    mapping(IDiamondFactoryPackage package => bytes4[] interfaces) public interfacesOfPackage;
    mapping(IDiamondFactoryPackage package => address[] facets) public facetsOfPackage;

    mapping(bytes32 name => AddressSet facets) internal _facetsOfName;
    mapping(bytes4 interfaceId => AddressSet facets) internal _facetsOfInterface;
    mapping(bytes4 functionSelector => AddressSet facets) internal _facetsOfFunction;
    AddressSet internal _allFacets;

    mapping(string name => AddressSet packages) internal _packagesOfName;
    mapping(bytes4 interfaceId => AddressSet packages) internal _packagesOfInterface;
    mapping(IFacet facetAddress => AddressSet packages) internal _packagesOfFacet;
    AddressSet internal _allPackages;

    constructor(address owner_) {
        MultiStepOwnableRepo._initialize(owner_, 3 days);
    }

    function setDiamondPackageFactory(IDiamondPackageCallBackFactory diamondPackageFactory_)
        public
        onlyOwner
        returns (bool)
    {
        diamondPackageFactory = diamondPackageFactory_;
        return true;
    }

    function create3(bytes memory initCode, bytes32 salt) public virtual onlyOwnerOrOperator returns (address proxy) {
        address predictedTarget = Creation._create3AddressOf(salt);
        if (predictedTarget.isContract()) {
            return predictedTarget;
        }
        return Creation.create3(initCode, salt);
    }

    function create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (address proxy)
    {
        return Creation.create3WithArgs(initCode, initData_, salt);
    }

    function deployFacetWithArgs(bytes calldata initCode, bytes calldata initArgs, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IFacet facet)
    {
        return _deployFacet(initCode, initArgs, salt);
    }

    function deployFacet(bytes calldata initCode, bytes32 salt) public onlyOwnerOrOperator returns (IFacet facet) {
        return _deployFacet(initCode, salt);
    }

    function deployPackageWithArgs(bytes calldata initCode, bytes calldata constructorArgs, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IDiamondFactoryPackage package)
    {
        return _deplayPackage(initCode, constructorArgs, salt);
    }

    function deployPackage(bytes calldata initCode, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IDiamondFactoryPackage package)
    {
        return _deployPackage(initCode, salt);
    }

    function registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        public
        onlyOwnerOrOperator
        returns (bool)
    {
        _registerFacet(facet, name, interfaces, functions);
        return true;
    }

    function registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) public onlyOwnerOrOperator returns (bool) {
        _registerPackage(package, name, interfaces, facets);
        return true;
    }

    function allFacets() public view returns (address[] memory facetAddresses) {
        return _allFacets._values();
    }

    function facetsOfName(string calldata name) public view returns (address[] memory facetAddresses) {
        return _facetsOfName[abi.encode(name)._hash()]._values();
    }

    function facetsOfInterface(bytes4 interfaceId) public view returns (address[] memory facetAddresses) {
        return _facetsOfInterface[interfaceId]._values();
    }

    function facetsOfFunction(bytes4 functionSelector) public view returns (address[] memory facetAddresses) {
        return _facetsOfFunction[functionSelector]._values();
    }

    function allPackages() public view returns (address[] memory packages) {
        return _allPackages._values();
    }

    function packagesByName(string calldata name) public view returns (address[] memory packages) {
        return _packagesOfName[name]._values();
    }

    function packagesByInterface(bytes4 interfaceId) public view returns (address[] memory packages) {
        return _packagesOfInterface[interfaceId]._values();
    }

    function packagesByFacet(IFacet facet) public view returns (address[] memory packages) {
        return _packagesOfFacet[facet]._values();
    }

    function _deployFacet(bytes memory initCode, bytes memory initArgs, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(create3WithArgs(initCode, initArgs, salt));
        _registerFacet(facet);
        return facet;
    }

    function _deployFacet(bytes memory initCode, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(create3(initCode, salt));
        _registerFacet(facet);
        return facet;
    }

    function _deplayPackage(bytes memory initCode, bytes memory constructorArgs, bytes32 salt)
        internal
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(create3WithArgs(initCode, constructorArgs, salt));
        _registerPackage(package);
        return package;
    }

    function _deployPackage(bytes memory initCode, bytes32 salt) internal returns (IDiamondFactoryPackage package) {
        package = IDiamondFactoryPackage(create3(initCode, salt));
        _registerPackage(package);
        return package;
    }

    function _registerFacet(IFacet facet) internal {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        _registerFacet(facet, name, interfaces, functions);
    }

    function _registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        internal
    {
        nameOfFacet[facet] = name;
        interfacesOfFacet[facet] = interfaces;
        functionsOfFacet[facet] = functions;
        _allFacets._add(address(facet));
        _facetsOfName[abi.encode(name)._hash()]._add(address(facet));
        for (uint256 i = 0; i < interfaces.length; i++) {
            _facetsOfInterface[interfaces[i]]._add(address(facet));
        }
        for (uint256 i = 0; i < functions.length; i++) {
            _facetsOfFunction[functions[i]]._add(address(facet));
        }
    }

    function _registerPackage(IDiamondFactoryPackage package) internal {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
        _registerPackage(package, name, interfaces, facets);
    }

    function _registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        nameOfPackage[package] = name;
        interfacesOfPackage[package] = interfaces;
        facetsOfPackage[package] = facets;
        _packagesOfName[name]._add(address(package));
        for (uint256 i = 0; i < interfaces.length; i++) {
            _packagesOfInterface[interfaces[i]]._add(address(package));
        }
        for (uint256 i = 0; i < facets.length; i++) {
            _packagesOfFacet[IFacet(facets[i])]._add(address(package));
        }
        _allPackages._add(address(package));
    }
}
