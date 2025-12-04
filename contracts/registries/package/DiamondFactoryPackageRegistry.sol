// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {OperableRepo} from "@crane/contracts/access/operable/OperableRepo.sol";
import {MultiStepOwnableTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableTarget.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";

contract DiamondFactoryPackageRegistry is MultiStepOwnableTarget, OperableModifiers, OperableTarget {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;

    ICreate3Factory public immutable create3Factory;

    mapping(IDiamondFactoryPackage package => string name) public nameOfPackage;
    mapping(IDiamondFactoryPackage package => bytes4[] interfaces) public interfacesOfPackage;
    mapping(IDiamondFactoryPackage package => address[] facets) public facetsOfPackage;
    mapping(string name => AddressSet packages) internal _packagesOfName;
    mapping(bytes4 interfaceId => AddressSet packages) internal _packagesOfInterface;
    mapping(IFacet facetAddress => AddressSet packages) internal _packagesOfFacet;
    AddressSet internal _allPackages;

    constructor(address owner_, ICreate3Factory create3Factory_) {
        create3Factory = create3Factory_;
        MultiStepOwnableRepo._initialize(owner_, 3 days);
        OperableRepo._setOperatorStatus(address(create3Factory_), true);
    }

    function deplayPackage(bytes calldata initCode, bytes calldata constructorArgs, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(create3Factory.create3WithArgs(initCode, constructorArgs, salt));
        _registerPackage(package);
        return package;
    }

    function deployPackage(bytes calldata initCode, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(create3Factory.create3(initCode, salt));
        _registerPackage(package);
        return package;
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

    function _registerPackage(IDiamondFactoryPackage package) internal {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
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
