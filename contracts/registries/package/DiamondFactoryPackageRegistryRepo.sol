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

    function _registerPackage(
        Storage storage layout,
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        layout.nameOfPackage[package] = name;
        layout.interfacesOfPackage[package] = interfaces;
        layout.facetsOfPackage[package] = facets;
        layout.packagesOfName[abi.encode(name)._hash()]._add(address(package));
        for (uint256 i = 0; i < interfaces.length; i++) {
            layout.packagesOfInterface[interfaces[i]]._add(address(package));
        }
        for (uint256 i = 0; i < facets.length; i++) {
            layout.packagesOfFacet[IFacet(facets[i])]._add(address(package));
        }
        layout.allPackages._add(address(package));
    }

    function _registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        _registerPackage(_layout(), package, name, interfaces, facets);
    }

    /* -------------------------------------------------------------------------- */
    /*      mapping(bytes4 interfaceId => address package)  canonicalPackage;     */
    /* -------------------------------------------------------------------------- */

    function _canonicalPackage(Storage storage layout, bytes4 interfaceId)
        internal
        view
        returns (IDiamondFactoryPackage package)
    {
        return layout.canonicalPackage[interfaceId];
    }

    function _canonicalPackage(bytes4 interfaceId) internal view returns (IDiamondFactoryPackage package) {
        return _canonicalPackage(_layout(), interfaceId);
    }

    function _setCanonicalPackage(Storage storage layout, bytes4 interfaceId, IDiamondFactoryPackage package) internal {
        layout.canonicalPackage[interfaceId] = package;
    }

    function _setCanonicalPackage(bytes4 interfaceId, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layout(), interfaceId, package);
    }

    function _setCanonicalPackage(Storage storage layout, bytes4[] memory interfaceIds, IDiamondFactoryPackage package)
        internal
    {
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            layout.canonicalPackage[interfaceIds[i]] = package;
        }
    }

    function _setCanonicalPackage(bytes4[] memory interfaceIds, IDiamondFactoryPackage package) internal {
        _setCanonicalPackage(_layout(), interfaceIds, package);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(IDiamondFactoryPackage package => string name) nameOfPackage;   */
    /* -------------------------------------------------------------------------- */

    function _nameOfPackage(Storage storage layout, IDiamondFactoryPackage package)
        internal
        view
        returns (string memory name)
    {
        return layout.nameOfPackage[package];
    }

    function _nameOfPackage(IDiamondFactoryPackage package) internal view returns (string memory name) {
        return _nameOfPackage(_layout(), package);
    }

    /* ---------------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => bytes4[] interfaces) interfacesOfPackage */
    /* ---------------------------------------------------------------------------------- */

    function _interfacesOfPackage(Storage storage layout, IDiamondFactoryPackage package)
        internal
        view
        returns (bytes4[] memory interfaceIds)
    {
        return layout.interfacesOfPackage[package];
    }

    /* --------------------------------------------------------------------------- */
    /* mapping(IDiamondFactoryPackage package => address[] facets) facetsOfPackage */
    /* --------------------------------------------------------------------------- */

    function _facetsOfPackage(Storage storage layout, IDiamondFactoryPackage package)
        internal
        view
        returns (address[] memory facets)
    {
        return layout.facetsOfPackage[package];
    }

    function _facetsOfPackage(IDiamondFactoryPackage package) internal view returns (address[] memory facets) {
        return _facetsOfPackage(_layout(), package);
    }

    /* -------------------------------------------------------------------------- */
    /*         mapping(string name => AddressSet packages) packagesOfName;        */
    /* -------------------------------------------------------------------------- */

    function _packagesOfName(Storage storage layout, string memory name)
        internal
        view
        returns (address[] memory packages)
    {
        return layout.packagesOfName[abi.encode(name)._hash()]._values();
    }

    function _packagesOfName(string memory name) internal view returns (address[] memory packages) {
        return _packagesOfName(_layout(), name);
    }

    /* -------------------------------------------------------------------------- */
    /*   mapping(bytes4 interfaceId => AddressSet packages) packagesOfInterface;  */
    /* -------------------------------------------------------------------------- */

    function _packagesOfInterface(Storage storage layout, bytes4 interfaceId)
        internal
        view
        returns (address[] memory packages)
    {
        return layout.packagesOfInterface[interfaceId]._values();
    }

    function _packagesOfInterface(bytes4 interfaceId) internal view returns (address[] memory packages) {
        return _packagesOfInterface(_layout(), interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*    mapping(IFacet facetAddress => AddressSet packages) packagesOfFacet;    */
    /* -------------------------------------------------------------------------- */

    function _packagesOfFacet(Storage storage layout, IFacet facet) internal view returns (address[] memory facets) {
        return layout.packagesOfFacet[facet]._values();
    }

    function _packagesOfFacet(IFacet facet) internal view returns (address[] memory facets) {
        return _packagesOfFacet(_layout(), facet);
    }

    /* -------------------------------------------------------------------------- */
    /*                           AddressSet allPackages;                          */
    /* -------------------------------------------------------------------------- */

    function _allPackages(Storage storage layout) internal view returns (address[] memory packages) {
        return layout.allPackages._values();
    }

    function _allPackages() internal view returns (address[] memory packages) {
        return _allPackages(_layout());
    }
}
