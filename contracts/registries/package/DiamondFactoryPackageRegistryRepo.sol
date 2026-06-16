// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

// tag::DiamondFactoryPackageRegistryRepo[]
/**
 * @title DiamondFactoryPackageRegistryRepo - Storage library for registering/querying DiamondFactoryPackages.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) implementing package registration and lookup per IDiamondFactoryPackageRegistry.
 * @dev Provides dual (parameterized + default) functions for all accessors/mutators.
 * @dev Typically used by DiamondFactoryPackageRegistryTarget / Facet.
 */
library DiamondFactoryPackageRegistryRepo {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    // tag::DEFAULT_SLOT[]
    /**
     * @dev Standardized storage slot for Diamond Factory Package Registry data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("crane.registries.packages"))) - 1);

    // end::DEFAULT_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for package registry state.
     */
    struct Storage {
        // Canonical package per supported interface (for default selection).
        mapping(bytes4 interfaceId => IDiamondFactoryPackage package) canonicalPackage;
        // Reverse lookup: package => its declared name.
        mapping(IDiamondFactoryPackage package => string name) nameOfPackage;
        // Reverse lookup: package => declared supported interfaces.
        mapping(IDiamondFactoryPackage package => bytes4[] interfaces) interfacesOfPackage;
        // Reverse lookup: package => its facet implementation addresses.
        mapping(IDiamondFactoryPackage package => address[] facets) facetsOfPackage;
        // Packages grouped by name hash (supports multiple versions per name).
        mapping(bytes32 nameHash => AddressSet packages) packagesOfName;
        // Packages grouped by supported interface.
        mapping(bytes4 interfaceId => AddressSet packages) packagesOfInterface;
        // Packages grouped by included facet.
        mapping(IFacet facetAddress => AddressSet packages) packagesOfFacet;
        // All registered packages.
        AddressSet allPackages;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ Storage slot to bind to the Repo's Storage struct.
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

    // tag::_registerPackage(Storage-IDiamondFactoryPackage-string-bytes4[]-address[])[]
    /**
     * @dev Argumented version of _registerPackage to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param package The IDiamondFactoryPackage to register.
     * @param name The name of the package.
     * @param interfaces The interface IDs implemented by facets in this package.
     * @param facets The addresses of the facets included in the package.
     */
    function _registerPackage(
        Storage storage layoutStruct,
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        layoutStruct.nameOfPackage[package] = name;
        layoutStruct.interfacesOfPackage[package] = interfaces;
        layoutStruct.facetsOfPackage[package] = facets;
        layoutStruct.packagesOfName[abi.encode(name)._hash()]._add(address(package));
        for (uint256 i = 0; i < interfaces.length; i++) {
            layoutStruct.packagesOfInterface[interfaces[i]]._add(address(package));
        }
        for (uint256 i = 0; i < facets.length; i++) {
            layoutStruct.packagesOfFacet[IFacet(facets[i])]._add(address(package));
        }
        layoutStruct.allPackages._add(address(package));
    }

    // end::_registerPackage(Storage-IDiamondFactoryPackage-string-bytes4[]-address[])[]

    // tag::_registerPackage(IDiamondFactoryPackage-string-bytes4[]-address[])[]
    /**
     * @dev Default version of _registerPackage binding to the standard DEFAULT_SLOT.
     * @param package The IDiamondFactoryPackage to register.
     * @param name The name of the package.
     * @param interfaces The interface IDs implemented by facets in this package.
     * @param facets The addresses of the facets included in the package.
     */
    function _registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        _registerPackage(_layoutStruct(), package, name, interfaces, facets);
    }

    // end::_registerPackage(IDiamondFactoryPackage-string-bytes4[]-address[])[]

    /* -------------------------------------------------------------------------- */
    /*      mapping(bytes4 interfaceId => address package)  canonicalPackage;     */
    /* -------------------------------------------------------------------------- */

    // tag::_canonicalPackage(Storage-bytes4)[]
    /**
     * @dev Argumented version of _canonicalPackage getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up the canonical package for.
     * @return package The registered canonical package for the interface (or zero if none).
     */
    function _canonicalPackage(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (IDiamondFactoryPackage package)
    {
        return layoutStruct.canonicalPackage[interfaceId];
    }

    // end::_canonicalPackage(Storage-bytes4)[]

    // tag::_canonicalPackage(bytes4)[]
    /**
     * @dev Default version of _canonicalPackage getter binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up the canonical package for.
     * @return package The registered canonical package for the interface (or zero if none).
     */
    function _canonicalPackage(bytes4 interfaceId) internal view returns (IDiamondFactoryPackage package) {
        return _canonicalPackage(_layoutStruct(), interfaceId);
    }

    // end::_canonicalPackage(bytes4)[]

    // tag::_setCanonicalPackage(Storage-bytes4-IDiamondFactoryPackage)[]
    /**
     * @dev Argumented version of _setCanonicalPackage to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID for which to set the canonical package.
     * @param package The package to designate as canonical for the interface.
     */
    function _setCanonicalPackage(Storage storage layoutStruct, bytes4 interfaceId, IDiamondFactoryPackage package)
        internal
    {
        layoutStruct.canonicalPackage[interfaceId] = package;
    }

    // end::_setCanonicalPackage(Storage-bytes4-IDiamondFactoryPackage)[]

    // tag::_setCanonicalPackage(bytes4-IDiamondFactoryPackage)[]
    /**
     * @dev Default version of _setCanonicalPackage binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID for which to set the canonical package.
     * @param package The package to designate as canonical for the interface.
     */
    function _setCanonicalPackage(bytes4 interfaceId, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layoutStruct(), interfaceId, package);
    }

    // end::_setCanonicalPackage(bytes4-IDiamondFactoryPackage)[]

    // tag::_setCanonicalPackage(Storage-bytes4[]-IDiamondFactoryPackage)[]
    /**
     * @dev Argumented (batch) version of _setCanonicalPackage to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceIds Array of interface IDs for which to set the same canonical package.
     * @param package The package to designate as canonical for each interface.
     */
    function _setCanonicalPackage(
        Storage storage layoutStruct,
        bytes4[] memory interfaceIds,
        IDiamondFactoryPackage package
    ) internal {
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            layoutStruct.canonicalPackage[interfaceIds[i]] = package;
        }
    }

    // end::_setCanonicalPackage(Storage-bytes4[]-IDiamondFactoryPackage)[]

    // tag::_setCanonicalPackage(bytes4[]-IDiamondFactoryPackage)[]
    /**
     * @dev Default (batch) version of _setCanonicalPackage binding to the standard DEFAULT_SLOT.
     * @param interfaceIds Array of interface IDs for which to set the same canonical package.
     * @param package The package to designate as canonical for each interface.
     */
    function _setCanonicalPackage(bytes4[] memory interfaceIds, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layoutStruct(), interfaceIds, package);
    }

    // end::_setCanonicalPackage(bytes4[]-IDiamondFactoryPackage)[]

    /* -------------------------------------------------------------------------- */
    /*    mapping(IDiamondFactoryPackage package => string name) nameOfPackage;   */
    /* -------------------------------------------------------------------------- */

    // tag::_nameOfPackage(Storage-IDiamondFactoryPackage)[]
    /**
     * @dev Argumented version of _nameOfPackage getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param package The package to query the name for.
     * @return name The registered name for the package.
     */
    function _nameOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (string memory name)
    {
        return layoutStruct.nameOfPackage[package];
    }

    // end::_nameOfPackage(Storage-IDiamondFactoryPackage)[]

    // tag::_nameOfPackage(IDiamondFactoryPackage)[]
    /**
     * @dev Default version of _nameOfPackage getter binding to the standard DEFAULT_SLOT.
     * @param package The package to query the name for.
     * @return name The registered name for the package.
     */
    function _nameOfPackage(IDiamondFactoryPackage package) internal view returns (string memory name) {
        return _nameOfPackage(_layoutStruct(), package);
    }

    // end::_nameOfPackage(IDiamondFactoryPackage)[]

    /* ---------------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => bytes4[] interfaces) interfacesOfPackage */
    /* ---------------------------------------------------------------------------------- */

    // tag::_interfacesOfPackage(Storage-IDiamondFactoryPackage)[]
    /**
     * @dev Argumented version of _interfacesOfPackage getter (note: only Storage overload present).
     * @param layoutStruct The Storage struct to operate on.
     * @param package The package to query interfaces for.
     * @return interfaceIds The array of interface IDs declared for the package.
     */
    function _interfacesOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (bytes4[] memory interfaceIds)
    {
        return layoutStruct.interfacesOfPackage[package];
    }

    // end::_interfacesOfPackage(Storage-IDiamondFactoryPackage)[]

    /* --------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => address[] facets) facetsOfPackage */
    /* --------------------------------------------------------------------------- */

    // tag::_facetsOfPackage(Storage-IDiamondFactoryPackage)[]
    /**
     * @dev Argumented version of _facetsOfPackage getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param package The package to query facets for.
     * @return facets The array of facet addresses declared for the package.
     */
    function _facetsOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (address[] memory facets)
    {
        return layoutStruct.facetsOfPackage[package];
    }

    // end::_facetsOfPackage(Storage-IDiamondFactoryPackage)[]

    // tag::_facetsOfPackage(IDiamondFactoryPackage)[]
    /**
     * @dev Default version of _facetsOfPackage getter binding to the standard DEFAULT_SLOT.
     * @param package The package to query facets for.
     * @return facets The array of facet addresses declared for the package.
     */
    function _facetsOfPackage(IDiamondFactoryPackage package) internal view returns (address[] memory facets) {
        return _facetsOfPackage(_layoutStruct(), package);
    }

    // end::_facetsOfPackage(IDiamondFactoryPackage)[]

    /* -------------------------------------------------------------------------- */
    /*         mapping(string name => AddressSet packages) packagesOfName;        */
    /* -------------------------------------------------------------------------- */

    // tag::_packagesOfName(Storage-string)[]
    /**
     * @dev Argumented version of _packagesOfName getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param name The package name to look up packages for.
     * @return packages Array of package addresses registered under that name.
     */
    function _packagesOfName(Storage storage layoutStruct, string memory name)
        internal
        view
        returns (address[] memory packages)
    {
        return layoutStruct.packagesOfName[abi.encode(name)._hash()]._values();
    }

    // end::_packagesOfName(Storage-string)[]

    // tag::_packagesOfName(string)[]
    /**
     * @dev Default version of _packagesOfName getter binding to the standard DEFAULT_SLOT.
     * @param name The package name to look up packages for.
     * @return packages Array of package addresses registered under that name.
     */
    function _packagesOfName(string memory name) internal view returns (address[] memory packages) {
        return _packagesOfName(_layoutStruct(), name);
    }

    // end::_packagesOfName(string)[]

    /* -------------------------------------------------------------------------- */
    /*   mapping(bytes4 interfaceId => AddressSet packages) packagesOfInterface;  */
    /* -------------------------------------------------------------------------- */

    // tag::_packagesOfInterface(Storage-bytes4)[]
    /**
     * @dev Argumented version of _packagesOfInterface getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param interfaceId The interface ID to look up packages implementing it.
     * @return packages Array of package addresses that declare the interface.
     */
    function _packagesOfInterface(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (address[] memory packages)
    {
        return layoutStruct.packagesOfInterface[interfaceId]._values();
    }

    // end::_packagesOfInterface(Storage-bytes4)[]

    // tag::_packagesOfInterface(bytes4)[]
    /**
     * @dev Default version of _packagesOfInterface getter binding to the standard DEFAULT_SLOT.
     * @param interfaceId The interface ID to look up packages implementing it.
     * @return packages Array of package addresses that declare the interface.
     */
    function _packagesOfInterface(bytes4 interfaceId) internal view returns (address[] memory packages) {
        return _packagesOfInterface(_layoutStruct(), interfaceId);
    }

    // end::_packagesOfInterface(bytes4)[]

    /* -------------------------------------------------------------------------- */
    /*    mapping(IFacet facetAddress => AddressSet packages) packagesOfFacet;    */
    /* -------------------------------------------------------------------------- */

    // tag::_packagesOfFacet(Storage-IFacet)[]
    /**
     * @dev Argumented version of _packagesOfFacet getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facet The facet address to look up packages containing it.
     * @return packages Array of package addresses that include the facet.
     */
    function _packagesOfFacet(Storage storage layoutStruct, IFacet facet)
        internal
        view
        returns (address[] memory packages)
    {
        return layoutStruct.packagesOfFacet[facet]._values();
    }

    // end::_packagesOfFacet(Storage-IFacet)[]

    // tag::_packagesOfFacet(IFacet)[]
    /**
     * @dev Default version of _packagesOfFacet getter binding to the standard DEFAULT_SLOT.
     * @param facet The facet address to look up packages containing it.
     * @return packages Array of package addresses that include the facet.
     */
    function _packagesOfFacet(IFacet facet) internal view returns (address[] memory packages) {
        return _packagesOfFacet(_layoutStruct(), facet);
    }

    // end::_packagesOfFacet(IFacet)[]

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet allPackages;                          */
    /* -------------------------------------------------------------------------- */

    // tag::_allPackages(Storage)[]
    /**
     * @dev Argumented version of _allPackages getter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return packages Array of all registered package addresses.
     */
    function _allPackages(Storage storage layoutStruct) internal view returns (address[] memory packages) {
        return layoutStruct.allPackages._values();
    }

    // end::_allPackages(Storage)[]

    // tag::_allPackages()[]
    /**
     * @dev Default version of _allPackages getter binding to the standard DEFAULT_SLOT.
     * @return packages Array of all registered package addresses.
     */
    function _allPackages() internal view returns (address[] memory packages) {
        return _allPackages(_layoutStruct());
    }

    // end::_allPackages()[]
}
// end::DiamondFactoryPackageRegistryRepo[]
