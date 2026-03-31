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

    // tag::_layout(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout(bytes32)[]

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(DEFAULT_SLOT);
    }

    function _registerFacet(
        Storage storage layout,
        IFacet facet,
        string memory name,
        bytes4[] memory interfaces,
        bytes4[] memory functions
    ) internal {
        layout.nameOfFacet[facet] = name;
        layout.interfacesOfFacet[facet] = interfaces;
        layout.functionsOfFacet[facet] = functions;
        layout.allFacets._add(address(facet));
        layout.facetsOfName[abi.encode(name)._hash()]._add(address(facet));
        for (uint256 i = 0; i < interfaces.length; i++) {
            layout.facetsOfInterface[interfaces[i]]._add(address(facet));
        }
        for (uint256 i = 0; i < functions.length; i++) {
            layout.facetsOfFunction[functions[i]]._add(address(facet));
        }
    }

    function _registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        internal
    {
        _registerFacet(_layout(), facet, name, interfaces, functions);
    }

    /* -------------------------------------------------------------------------- */
    /*         mapping(bytes4 interfaceId => IFacet facet) canonicalFacet;        */
    /* -------------------------------------------------------------------------- */

    function _canonicalFacet(Storage storage layout, bytes4 interfaceId) internal view returns (IFacet facet) {
        facet = layout.canonicalFacet[interfaceId];
    }

    function _canonicalFacet(bytes4 interfaceId) internal view returns (IFacet facet) {
        return _canonicalFacet(_layout(), interfaceId);
    }

    function _setCanonicalFacet(Storage storage layout, bytes4 interfaceId, IFacet facet) internal {
        layout.canonicalFacet[interfaceId] = facet;
    }

    function _setCanonicalFacet(bytes4 interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layout(), interfaceId, facet);
    }

    function _setCanonicalFacet(Storage storage layout, bytes4[] memory interfaceId, IFacet facet) internal {
        for (uint256 i = 0; i < interfaceId.length; i++) {
            layout.canonicalFacet[interfaceId[i]] = facet;
        }
    }

    function _setCanonicalFacet(bytes4[] memory interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layout(), interfaceId, facet);
    }

    /* -------------------------------------------------------------------------- */
    /*              mapping(IFacet facet => string name) nameOfFacet;             */
    /* -------------------------------------------------------------------------- */

    function _nameOfFacet(Storage storage layout, IFacet facet) internal view returns (string memory name) {
        name = layout.nameOfFacet[facet];
    }

    function _nameOfFacet(IFacet facet) internal view returns (string memory name) {
        return _nameOfFacet(_layout(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*       mapping(IFacet facet => bytes4[] interfaces) interfacesOfFacet;      */
    /* -------------------------------------------------------------------------- */

    function _interfacesOfFacet(Storage storage layout, IFacet facet)
        internal
        view
        returns (bytes4[] memory interfaces)
    {
        interfaces = layout.interfacesOfFacet[facet];
    }

    function _interfacesOfFacet(IFacet facet) internal view returns (bytes4[] memory interfaces) {
        return _interfacesOfFacet(_layout(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*        mapping(IFacet facet => bytes4[] functions) functionsOfFacet;       */
    /* -------------------------------------------------------------------------- */

    function _functionsOfFacet(Storage storage layout, IFacet facet) internal view returns (bytes4[] memory functions) {
        functions = layout.functionsOfFacet[facet];
    }

    function _functionsOfFacet(IFacet facet) internal view returns (bytes4[] memory functions) {
        return _functionsOfFacet(_layout(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*          mapping(bytes32 name => AddressSet facets) _facetsOfName;         */
    /* -------------------------------------------------------------------------- */

    function _facetsOfName(Storage storage layout, string memory name) internal view returns (address[] memory facets) {
        facets = layout.facetsOfName[abi.encode(name)._hash()]._values();
    }

    function _facetsOfName(string memory name) internal view returns (address[] memory facets) {
        return _facetsOfName(_layout(), name);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(bytes4 interfaceId => AddressSet facets) _facetsOfInterface;    */
    /* -------------------------------------------------------------------------- */

    function _facetsOfInterface(Storage storage layout, bytes4 interfaceId)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layout.facetsOfInterface[interfaceId]._values();
    }

    function _facetsOfInterface(bytes4 interfaceId) internal view returns (address[] memory facets) {
        return _facetsOfInterface(_layout(), interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*  mapping(bytes4 functionSelector => AddressSet facets) _facetsOfFunction;  */
    /* -------------------------------------------------------------------------- */

    function _facetsOfFunction(Storage storage layout, bytes4 functionSelector)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layout.facetsOfFunction[functionSelector]._values();
    }

    function _facetsOfFunction(bytes4 functionSelector) internal view returns (address[] memory facets) {
        return _facetsOfFunction(_layout(), functionSelector);
    }

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet _allFacets;                           */
    /* -------------------------------------------------------------------------- */

    function _allFacets(Storage storage layout) internal view returns (address[] memory facets) {
        facets = layout.allFacets._values();
    }

    function _allFacets() internal view returns (address[] memory facets) {
        return _allFacets(_layout());
    }
}
