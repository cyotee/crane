// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {FacetRegistryTarget} from "@crane/contracts/registries/facet/FacetRegistryTarget.sol";

contract FacetRegistryFacet is FacetRegistryTarget, IFacet {
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(FacetRegistryFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IFacetRegistry).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](14);
        funcs[0] = IFacetRegistry.allFacets.selector;
        funcs[1] = IFacetRegistry.facetsOfName.selector;
        funcs[2] = IFacetRegistry.facetsOfInterface.selector;
        funcs[3] = IFacetRegistry.facetsOfFunction.selector;
        funcs[4] = IFacetRegistry.canonicalFacet.selector;
        funcs[5] = IFacetRegistry.nameOfFacet.selector;
        funcs[6] = IFacetRegistry.interfacesOfFacet.selector;
        funcs[7] = IFacetRegistry.functionsOfFacet.selector;
        funcs[8] = IFacetRegistry.deployFacet.selector;
        funcs[9] = IFacetRegistry.deployCanonicalFacetOverride.selector;
        funcs[10] = IFacetRegistry.deployFacetWithArgs.selector;
        funcs[11] = IFacetRegistry.deployCanonicalFacetWithArgsOverride.selector;
        funcs[12] = IFacetRegistry.registerFacet.selector;
        funcs[13] = IFacetRegistry.setCanonicalFacet.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
