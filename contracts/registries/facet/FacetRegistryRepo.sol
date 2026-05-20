// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

library FacetRegistryRepo {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("crane.registries.facets"));

    struct Storage {
        mapping(bytes4 interfaceId => IFacet facet) canonicalFacet;
        mapping(IFacet facet => string name) nameOfFacet;
        mapping(IFacet facet => bytes4[] interfaces) interfacesOfFacet;
        mapping(IFacet facet => bytes4[] functions) functionsOfFacet;
        mapping(bytes32 name => AddressSet facets) facetsOfName;
        mapping(bytes4 interfaceId => AddressSet facets) facetsOfInterface;
        mapping(bytes4 functionSelector => AddressSet facets) facetsOfFunction;
        AddressSet allFacets;
    }

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(DEFAULT_SLOT);
    }

    function _registerFacet(
        Storage storage layoutStruct,
        IFacet facet,
        string memory name,
        bytes4[] memory interfaces,
        bytes4[] memory functions
    ) internal {
        layoutStruct.nameOfFacet[facet] = name;
        layoutStruct.interfacesOfFacet[facet] = interfaces;
        layoutStruct.functionsOfFacet[facet] = functions;
        layoutStruct.allFacets._add(address(facet));
        layoutStruct.facetsOfName[abi.encode(name)._hash()]._add(address(facet));
        for (uint256 i = 0; i < interfaces.length; i++) {
            layoutStruct.facetsOfInterface[interfaces[i]]._add(address(facet));
        }
        for (uint256 i = 0; i < functions.length; i++) {
            layoutStruct.facetsOfFunction[functions[i]]._add(address(facet));
        }
    }

    function _registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        internal
    {
        _registerFacet(_layoutStruct(), facet, name, interfaces, functions);
    }

    /* -------------------------------------------------------------------------- */
    /*         mapping(bytes4 interfaceId => IFacet facet) canonicalFacet;        */
    /* -------------------------------------------------------------------------- */

    function _canonicalFacet(Storage storage layoutStruct, bytes4 interfaceId) internal view returns (IFacet facet) {
        facet = layoutStruct.canonicalFacet[interfaceId];
    }

    function _canonicalFacet(bytes4 interfaceId) internal view returns (IFacet facet) {
        return _canonicalFacet(_layoutStruct(), interfaceId);
    }

    function _setCanonicalFacet(Storage storage layoutStruct, bytes4 interfaceId, IFacet facet) internal {
        layoutStruct.canonicalFacet[interfaceId] = facet;
    }

    function _setCanonicalFacet(bytes4 interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layoutStruct(), interfaceId, facet);
    }

    function _setCanonicalFacet(Storage storage layoutStruct, bytes4[] memory interfaceId, IFacet facet) internal {
        for (uint256 i = 0; i < interfaceId.length; i++) {
            layoutStruct.canonicalFacet[interfaceId[i]] = facet;
        }
    }

    function _setCanonicalFacet(bytes4[] memory interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layoutStruct(), interfaceId, facet);
    }

    /* -------------------------------------------------------------------------- */
    /*              mapping(IFacet facet => string name) nameOfFacet;             */
    /* -------------------------------------------------------------------------- */

    function _nameOfFacet(Storage storage layoutStruct, IFacet facet) internal view returns (string memory name) {
        name = layoutStruct.nameOfFacet[facet];
    }

    function _nameOfFacet(IFacet facet) internal view returns (string memory name) {
        return _nameOfFacet(_layoutStruct(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*       mapping(IFacet facet => bytes4[] interfaces) interfacesOfFacet;      */
    /* -------------------------------------------------------------------------- */

    function _interfacesOfFacet(Storage storage layoutStruct, IFacet facet)
        internal
        view
        returns (bytes4[] memory interfaces)
    {
        interfaces = layoutStruct.interfacesOfFacet[facet];
    }

    function _interfacesOfFacet(IFacet facet) internal view returns (bytes4[] memory interfaces) {
        return _interfacesOfFacet(_layoutStruct(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*        mapping(IFacet facet => bytes4[] functions) functionsOfFacet;       */
    /* -------------------------------------------------------------------------- */

    function _functionsOfFacet(Storage storage layoutStruct, IFacet facet) internal view returns (bytes4[] memory functions) {
        functions = layoutStruct.functionsOfFacet[facet];
    }

    function _functionsOfFacet(IFacet facet) internal view returns (bytes4[] memory functions) {
        return _functionsOfFacet(_layoutStruct(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*          mapping(bytes32 name => AddressSet facets) _facetsOfName;         */
    /* -------------------------------------------------------------------------- */

    function _facetsOfName(Storage storage layoutStruct, string memory name) internal view returns (address[] memory facets) {
        facets = layoutStruct.facetsOfName[abi.encode(name)._hash()]._values();
    }

    function _facetsOfName(string memory name) internal view returns (address[] memory facets) {
        return _facetsOfName(_layoutStruct(), name);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(bytes4 interfaceId => AddressSet facets) _facetsOfInterface;    */
    /* -------------------------------------------------------------------------- */

    function _facetsOfInterface(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layoutStruct.facetsOfInterface[interfaceId]._values();
    }

    function _facetsOfInterface(bytes4 interfaceId) internal view returns (address[] memory facets) {
        return _facetsOfInterface(_layoutStruct(), interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*  mapping(bytes4 functionSelector => AddressSet facets) _facetsOfFunction;  */
    /* -------------------------------------------------------------------------- */

    function _facetsOfFunction(Storage storage layoutStruct, bytes4 functionSelector)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layoutStruct.facetsOfFunction[functionSelector]._values();
    }

    function _facetsOfFunction(bytes4 functionSelector) internal view returns (address[] memory facets) {
        return _facetsOfFunction(_layoutStruct(), functionSelector);
    }

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet _allFacets;                           */
    /* -------------------------------------------------------------------------- */

    function _allFacets(Storage storage layoutStruct) internal view returns (address[] memory facets) {
        facets = layoutStruct.allFacets._values();
    }

    function _allFacets() internal view returns (address[] memory facets) {
        return _allFacets(_layoutStruct());
    }
}
