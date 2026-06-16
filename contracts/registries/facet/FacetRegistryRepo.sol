// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

// tag::FacetRegistryRepo[]
/**
 * @title FacetRegistryRepo - Storage library for registering and querying IFacet implementations.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) implementing facet registration and lookup per IFacetRegistry.
 * @dev Provides dual (parameterized + default) functions for all accessors and mutators.
 * @dev Uses AddressSetRepo for collection storage and BetterEfficientHashLib for name hashing.
 * @dev This file is the canonical model for ERC1967 DEFAULT_SLOT derivation in Crane Repos.
 * @dev Typically used by FacetRegistryTarget and FacetRegistryFacet.
 */
library FacetRegistryRepo {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    // tag::DEFAULT_SLOT[]
    /**
     * @dev Standardized storage slot for Facet Registry data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode("crane.registries.facets"))) - 1).
     */
    bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("crane.registries.facets"))) - 1);

    // end::DEFAULT_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for facet registry state.
     * The Storage struct to operate on.
     */
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

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct_ The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard DEFAULT_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(DEFAULT_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_registerFacet(Storage-IFacet-string-bytes4[]-bytes4[])[]
    /**
     * @dev Argumented version of _registerFacet to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facet The IFacet to register.
     * @param name The name of the facet.
     * @param interfaces The interface IDs implemented by the facet.
     * @param functions The function selectors implemented by the facet.
     */
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

    // end::_registerFacet(Storage-IFacet-string-bytes4[]-bytes4[])[]

    // tag::_registerFacet(IFacet-string-bytes4[]-bytes4[])[]
    /**
     * @dev Default version of _registerFacet binding to the standard DEFAULT_SLOT.
     * @param facet The IFacet to register.
     * @param name The name of the facet.
     * @param interfaces The interface IDs implemented by the facet.
     * @param functions The function selectors implemented by the facet.
     */
    function _registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        internal
    {
        _registerFacet(_layoutStruct(), facet, name, interfaces, functions);
    }

    // end::_registerFacet(IFacet-string-bytes4[]-bytes4[])[]

    /* -------------------------------------------------------------------------- */
    /*         mapping(bytes4 interfaceId => IFacet facet) canonicalFacet;        */
    /* -------------------------------------------------------------------------- */

    // tag::_canonicalFacet(Storage-bytes4)[]
    /**
     * @dev Argumented version of _canonicalFacet getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up the canonical facet for.
     * @return facet The registered canonical facet for the interface (or zero if none).
     */
    function _canonicalFacet(Storage storage layoutStruct, bytes4 interfaceId) internal view returns (IFacet facet) {
        facet = layoutStruct.canonicalFacet[interfaceId];
    }

    // end::_canonicalFacet(Storage-bytes4)[]

    // tag::_canonicalFacet(bytes4)[]
    /**
     * @dev Default version of _canonicalFacet getter binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up the canonical facet for.
     * @return facet The registered canonical facet for the interface (or zero if none).
     */
    function _canonicalFacet(bytes4 interfaceId) internal view returns (IFacet facet) {
        return _canonicalFacet(_layoutStruct(), interfaceId);
    }

    // end::_canonicalFacet(bytes4)[]

    // tag::_setCanonicalFacet(Storage-bytes4-IFacet)[]
    /**
     * @dev Argumented version of _setCanonicalFacet to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID for which to set the canonical facet.
     * @param facet The facet to designate as canonical for the interface.
     */
    function _setCanonicalFacet(Storage storage layoutStruct, bytes4 interfaceId, IFacet facet) internal {
        layoutStruct.canonicalFacet[interfaceId] = facet;
    }

    // end::_setCanonicalFacet(Storage-bytes4-IFacet)[]

    // tag::_setCanonicalFacet(bytes4-IFacet)[]
    /**
     * @dev Default version of _setCanonicalFacet binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID for which to set the canonical facet.
     * @param facet The facet to designate as canonical for the interface.
     */
    function _setCanonicalFacet(bytes4 interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layoutStruct(), interfaceId, facet);
    }

    // end::_setCanonicalFacet(bytes4-IFacet)[]

    // tag::_setCanonicalFacet(Storage-bytes4[]-IFacet)[]
    /**
     * @dev Argumented (batch) version of _setCanonicalFacet to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId Array of interface IDs for which to set the same canonical facet.
     * @param facet The facet to designate as canonical for each interface.
     */
    function _setCanonicalFacet(Storage storage layoutStruct, bytes4[] memory interfaceId, IFacet facet) internal {
        for (uint256 i = 0; i < interfaceId.length; i++) {
            layoutStruct.canonicalFacet[interfaceId[i]] = facet;
        }
    }

    // end::_setCanonicalFacet(Storage-bytes4[]-IFacet)[]

    // tag::_setCanonicalFacet(bytes4[]-IFacet)[]
    /**
     * @dev Default (batch) version of _setCanonicalFacet binding to the standard DEFAULT_SLOT.
     * @param interfaceId Array of interface IDs for which to set the same canonical facet.
     * @param facet The facet to designate as canonical for each interface.
     */
    function _setCanonicalFacet(bytes4[] memory interfaceId, IFacet facet) internal {
        _setCanonicalFacet(_layoutStruct(), interfaceId, facet);
    }

    // end::_setCanonicalFacet(bytes4[]-IFacet)[]

    /* -------------------------------------------------------------------------- */
    /*              mapping(IFacet facet => string name) nameOfFacet;             */
    /* -------------------------------------------------------------------------- */

    // tag::_nameOfFacet(Storage-IFacet)[]
    /**
     * @dev Argumented version of _nameOfFacet getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facet The facet to query the name for.
     * @return name The registered name for the facet.
     */
    function _nameOfFacet(Storage storage layoutStruct, IFacet facet) internal view returns (string memory name) {
        name = layoutStruct.nameOfFacet[facet];
    }

    // end::_nameOfFacet(Storage-IFacet)[]

    // tag::_nameOfFacet(IFacet)[]
    /**
     * @dev Default version of _nameOfFacet getter binding to the standard DEFAULT_SLOT.
     * @param facet The facet to query the name for.
     * @return name The registered name for the facet.
     */
    function _nameOfFacet(IFacet facet) internal view returns (string memory name) {
        return _nameOfFacet(_layoutStruct(), facet);
    }

    // end::_nameOfFacet(IFacet)[]

    /* -------------------------------------------------------------------------- */
    /*       mapping(IFacet facet => bytes4[] interfaces) interfacesOfFacet;      */
    /* -------------------------------------------------------------------------- */

    // tag::_interfacesOfFacet(Storage-IFacet)[]
    /**
     * @dev Argumented version of _interfacesOfFacet getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facet The facet to query interfaces for.
     * @return interfaces The array of interface IDs declared for the facet.
     */
    function _interfacesOfFacet(Storage storage layoutStruct, IFacet facet)
        internal
        view
        returns (bytes4[] memory interfaces)
    {
        interfaces = layoutStruct.interfacesOfFacet[facet];
    }

    // end::_interfacesOfFacet(Storage-IFacet)[]

    // tag::_interfacesOfFacet(IFacet)[]
    /**
     * @dev Default version of _interfacesOfFacet getter binding to the standard DEFAULT_SLOT.
     * @param facet The facet to query interfaces for.
     * @return interfaces The array of interface IDs declared for the facet.
     */
    function _interfacesOfFacet(IFacet facet) internal view returns (bytes4[] memory interfaces) {
        return _interfacesOfFacet(_layoutStruct(), facet);
    }

    // end::_interfacesOfFacet(IFacet)[]

    /* -------------------------------------------------------------------------- */
    /*        mapping(IFacet facet => bytes4[] functions) functionsOfFacet;       */
    /* -------------------------------------------------------------------------- */

    // tag::_functionsOfFacet(Storage-IFacet)[]
    /**
     * @dev Argumented version of _functionsOfFacet getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facet The facet to query functions for.
     * @return functions The array of function selectors declared for the facet.
     */
    function _functionsOfFacet(Storage storage layoutStruct, IFacet facet)
        internal
        view
        returns (bytes4[] memory functions)
    {
        functions = layoutStruct.functionsOfFacet[facet];
    }

    // end::_functionsOfFacet(Storage-IFacet)[]

    // tag::_functionsOfFacet(IFacet)[]
    /**
     * @dev Default version of _functionsOfFacet getter binding to the standard DEFAULT_SLOT.
     * @param facet The facet to query functions for.
     * @return functions The array of function selectors declared for the facet.
     */
    function _functionsOfFacet(IFacet facet) internal view returns (bytes4[] memory functions) {
        return _functionsOfFacet(_layoutStruct(), facet);
    }

    // end::_functionsOfFacet(IFacet)[]

    /* -------------------------------------------------------------------------- */
    /*          mapping(bytes32 name => AddressSet facets) _facetsOfName;         */
    /* -------------------------------------------------------------------------- */

    // tag::_facetsOfName(Storage-string)[]
    /**
     * @dev Argumented version of _facetsOfName getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param name The facet name to look up facets for.
     * @return facets Array of facet addresses registered under that name.
     */
    function _facetsOfName(Storage storage layoutStruct, string memory name)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layoutStruct.facetsOfName[abi.encode(name)._hash()]._values();
    }

    // end::_facetsOfName(Storage-string)[]

    // tag::_facetsOfName(string)[]
    /**
     * @dev Default version of _facetsOfName getter binding to the standard DEFAULT_SLOT.
     * @param name The facet name to look up facets for.
     * @return facets Array of facet addresses registered under that name.
     */
    function _facetsOfName(string memory name) internal view returns (address[] memory facets) {
        return _facetsOfName(_layoutStruct(), name);
    }

    // end::_facetsOfName(string)[]

    /* -------------------------------------------------------------------------- */
    /*    mapping(bytes4 interfaceId => AddressSet facets) _facetsOfInterface;    */
    /* -------------------------------------------------------------------------- */

    // tag::_facetsOfInterface(Storage-bytes4)[]
    /**
     * @dev Argumented version of _facetsOfInterface getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up facets implementing it.
     * @return facets Array of facet addresses that declare the interface.
     */
    function _facetsOfInterface(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layoutStruct.facetsOfInterface[interfaceId]._values();
    }

    // end::_facetsOfInterface(Storage-bytes4)[]

    // tag::_facetsOfInterface(bytes4)[]
    /**
     * @dev Default version of _facetsOfInterface getter binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up facets implementing it.
     * @return facets Array of facet addresses that declare the interface.
     */
    function _facetsOfInterface(bytes4 interfaceId) internal view returns (address[] memory facets) {
        return _facetsOfInterface(_layoutStruct(), interfaceId);
    }

    // end::_facetsOfInterface(bytes4)[]

    /* -------------------------------------------------------------------------- */
    /*  mapping(bytes4 functionSelector => AddressSet facets) _facetsOfFunction;  */
    /* -------------------------------------------------------------------------- */

    // tag::_facetsOfFunction(Storage-bytes4)[]
    /**
     * @dev Argumented version of _facetsOfFunction getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param functionSelector The function selector to look up facets implementing it.
     * @return facets Array of facet addresses that declare the function.
     */
    function _facetsOfFunction(Storage storage layoutStruct, bytes4 functionSelector)
        internal
        view
        returns (address[] memory facets)
    {
        facets = layoutStruct.facetsOfFunction[functionSelector]._values();
    }

    // end::_facetsOfFunction(Storage-bytes4)[]

    // tag::_facetsOfFunction(bytes4)[]
    /**
     * @dev Default version of _facetsOfFunction getter binding to the standard DEFAULT_SLOT.
     * @param functionSelector The function selector to look up facets implementing it.
     * @return facets Array of facet addresses that declare the function.
     */
    function _facetsOfFunction(bytes4 functionSelector) internal view returns (address[] memory facets) {
        return _facetsOfFunction(_layoutStruct(), functionSelector);
    }

    // end::_facetsOfFunction(bytes4)[]

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet _allFacets;                           */
    /* -------------------------------------------------------------------------- */

    // tag::_allFacets(Storage)[]
    /**
     * @dev Argumented version of _allFacets getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return facets Array of all registered facet addresses.
     */
    function _allFacets(Storage storage layoutStruct) internal view returns (address[] memory facets) {
        facets = layoutStruct.allFacets._values();
    }

    // end::_allFacets(Storage)[]

    // tag::_allFacets()[]
    /**
     * @dev Default version of _allFacets getter binding to the standard DEFAULT_SLOT.
     * @return facets Array of all registered facet addresses.
     */
    function _allFacets() internal view returns (address[] memory facets) {
        return _allFacets(_layoutStruct());
    }

    // end::_allFacets()[]
}
// end::FacetRegistryRepo[]
