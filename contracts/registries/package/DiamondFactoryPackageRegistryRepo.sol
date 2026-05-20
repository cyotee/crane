// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

library DiamondFactoryPackageRegistryRepo {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("crane.registries.packages"));

    struct Storage {
        mapping(bytes4 interfaceId => IDiamondFactoryPackage package) canonicalPackage;
        mapping(IDiamondFactoryPackage package => string name) nameOfPackage;
        mapping(IDiamondFactoryPackage package => bytes4[] interfaces) interfacesOfPackage;
        mapping(IDiamondFactoryPackage package => address[] facets) facetsOfPackage;
        mapping(bytes32 nameHash => AddressSet packages) packagesOfName;
        mapping(bytes4 interfaceId => AddressSet packages) packagesOfInterface;
        mapping(IFacet facetAddress => AddressSet packages) packagesOfFacet;
        AddressSet allPackages;
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

    function _registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        _registerPackage(_layoutStruct(), package, name, interfaces, facets);
    }

    /* -------------------------------------------------------------------------- */
    /*      mapping(bytes4 interfaceId => address package)  canonicalPackage;     */
    /* -------------------------------------------------------------------------- */

    function _canonicalPackage(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (IDiamondFactoryPackage package)
    {
        return layoutStruct.canonicalPackage[interfaceId];
    }

    function _canonicalPackage(bytes4 interfaceId) internal view returns (IDiamondFactoryPackage package) {
        return _canonicalPackage(_layoutStruct(), interfaceId);
    }

    function _setCanonicalPackage(Storage storage layoutStruct, bytes4 interfaceId, IDiamondFactoryPackage package) internal {
        layoutStruct.canonicalPackage[interfaceId] = package;
    }

    function _setCanonicalPackage(bytes4 interfaceId, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layoutStruct(), interfaceId, package);
    }

    function _setCanonicalPackage(Storage storage layoutStruct, bytes4[] memory interfaceIds, IDiamondFactoryPackage package)
        internal
    {
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            layoutStruct.canonicalPackage[interfaceIds[i]] = package;
        }
    }

    function _setCanonicalPackage(bytes4[] memory interfaceIds, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layoutStruct(), interfaceIds, package);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(IDiamondFactoryPackage package => string name) nameOfPackage;   */
    /* -------------------------------------------------------------------------- */

    function _nameOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (string memory name)
    {
        return layoutStruct.nameOfPackage[package];
    }

    function _nameOfPackage(IDiamondFactoryPackage package) internal view returns (string memory name) {
        return _nameOfPackage(_layoutStruct(), package);
    }

    /* ---------------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => bytes4[] interfaces) interfacesOfPackage */
    /* ---------------------------------------------------------------------------------- */

    function _interfacesOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (bytes4[] memory interfaceIds)
    {
        return layoutStruct.interfacesOfPackage[package];
    }

    /* --------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => address[] facets) facetsOfPackage */
    /* --------------------------------------------------------------------------- */

    function _facetsOfPackage(Storage storage layoutStruct, IDiamondFactoryPackage package)
        internal
        view
        returns (address[] memory facets)
    {
        return layoutStruct.facetsOfPackage[package];
    }

    function _facetsOfPackage(IDiamondFactoryPackage package) internal view returns (address[] memory facets) {
        return _facetsOfPackage(_layoutStruct(), package);
    }

    /* -------------------------------------------------------------------------- */
    /*         mapping(string name => AddressSet packages) packagesOfName;        */
    /* -------------------------------------------------------------------------- */

    function _packagesOfName(Storage storage layoutStruct, string memory name)
        internal
        view
        returns (address[] memory packages)
    {
        return layoutStruct.packagesOfName[abi.encode(name)._hash()]._values();
    }

    function _packagesOfName(string memory name) internal view returns (address[] memory packages) {
        return _packagesOfName(_layoutStruct(), name);
    }

    /* -------------------------------------------------------------------------- */
    /*   mapping(bytes4 interfaceId => AddressSet packages) packagesOfInterface;  */
    /* -------------------------------------------------------------------------- */

    function _packagesOfInterface(Storage storage layoutStruct, bytes4 interfaceId)
        internal
        view
        returns (address[] memory packages)
    {
        return layoutStruct.packagesOfInterface[interfaceId]._values();
    }

    function _packagesOfInterface(bytes4 interfaceId) internal view returns (address[] memory packages) {
        return _packagesOfInterface(_layoutStruct(), interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(IFacet facetAddress => AddressSet packages) packagesOfFacet;    */
    /* -------------------------------------------------------------------------- */

    function _packagesOfFacet(Storage storage layoutStruct, IFacet facet) internal view returns (address[] memory facets) {
        return layoutStruct.packagesOfFacet[facet]._values();
    }

    function _packagesOfFacet(IFacet facet) internal view returns (address[] memory facets) {
        return _packagesOfFacet(_layoutStruct(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet allPackages;                          */
    /* -------------------------------------------------------------------------- */

    function _allPackages(Storage storage layoutStruct) internal view returns (address[] memory packages) {
        return layoutStruct.allPackages._values();
    }

    function _allPackages() internal view returns (address[] memory packages) {
        return _allPackages(_layoutStruct());
    }
}
