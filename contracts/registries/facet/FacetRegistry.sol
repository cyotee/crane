// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
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

contract FacetRegistry is MultiStepOwnableTarget, OperableModifiers, OperableTarget {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;
    using BetterEfficientHashLib for bytes;

    ICreate3Factory public immutable create3Factory;

    mapping(IFacet facet => string name) public nameOfFacet;
    mapping(IFacet facet => bytes4[] interfaces) public interfacesOfFacet;
    mapping(IFacet facet => bytes4[] functions) public functionsOfFacet;
    mapping(bytes32 name => AddressSet facets) internal _facetsOfName;
    mapping(bytes4 interfaceId => AddressSet facets) internal _facetsOfInterface;
    mapping(bytes4 functionSelector => AddressSet facets) internal _facetsOfFunction;
    AddressSet internal _allFacets;

    constructor(address owner_, ICreate3Factory create3Factory_) {
        create3Factory = create3Factory_;
        MultiStepOwnableRepo._initialize(owner_, 3 days);
        OperableRepo._setOperatorStatus(address(create3Factory_), true);
    }

    function deployFacet(bytes calldata initCode, bytes calldata initArgs, bytes32 salt)
        public
        onlyOwnerOrOperator
        returns (IFacet facet)
    {
        facet = IFacet(create3Factory.create3WithArgs(initCode, initArgs, salt));
        _registerFacet(facet);
        return facet;
    }

    function deployFacet(bytes calldata initCode, bytes32 salt) public onlyOwnerOrOperator returns (IFacet facet) {
        facet = IFacet(create3Factory.create3(initCode, salt));
        _registerFacet(facet);
        return facet;
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

    function _registerFacet(IFacet facet) internal {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
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
}
