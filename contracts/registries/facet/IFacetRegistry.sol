// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

interface IFacetRegistry {
    function allFacets() external view returns (address[] memory facetAddresses);

    function facetsOfName(string calldata name) external view returns (address[] memory facetAddresses);

    function facetsOfInterface(bytes4 interfaceId) external view returns (address[] memory facetAddresses);

    function facetsOfFunction(bytes4 functionSelector) external view returns (address[] memory facetAddresses);

    function canonicalFacet(bytes4 interfaceId) external view returns (IFacet facet);

    function nameOfFacet(IFacet facet) external view returns (string memory name);

    function interfacesOfFacet(IFacet facet) external view returns (bytes4[] memory interfaces);

    function functionsOfFacet(IFacet facet) external view returns (bytes4[] memory functions);

    function deployFacet(bytes calldata initCode, bytes32 salt) external returns (IFacet facet);

    function deployCanonicalFacetOverride(bytes calldata initCode, bytes32 salt, bytes4 interfaceId) external returns (IFacet facet);

    function deployFacetWithArgs(bytes calldata initCode, bytes calldata initArgs, bytes32 salt)
        external
        returns (IFacet facet);

    function deployCanonicalFacetWithArgsOverride(bytes calldata initCode, bytes calldata initArgs, bytes32 salt, bytes4 interfaceId)
        external
        returns (IFacet facet);

    function registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        external
        returns (bool);

    function setCanonicalFacet(bytes4 interfaceId, IFacet facet) external returns (bool);
}
