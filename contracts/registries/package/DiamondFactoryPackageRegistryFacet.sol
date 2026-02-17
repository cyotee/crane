// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {
    DiamondFactoryPackageRegistryTarget
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryTarget.sol";

contract DiamondFactoryPackageRegistryFacet is DiamondFactoryPackageRegistryTarget, IFacet {
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(DiamondFactoryPackageRegistryFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondFactoryPackageRegistry).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](12);
        funcs[0] = IDiamondFactoryPackageRegistry.deployPackage.selector;
        funcs[1] = IDiamondFactoryPackageRegistry.deployCanonicalPackage.selector;
        funcs[2] = IDiamondFactoryPackageRegistry.deployPackageWithArgs.selector;
        funcs[3] = IDiamondFactoryPackageRegistry.deployCanonicalPackageWithArgs.selector;
        funcs[4] = IDiamondFactoryPackageRegistry.registerPackage.selector;
        funcs[5] = IDiamondFactoryPackageRegistry.setCanonicalPackage.selector;
        funcs[6] = IDiamondFactoryPackageRegistry.canonicalPackage.selector;
        funcs[7] = IDiamondFactoryPackageRegistry.allPackages.selector;
        funcs[8] = IDiamondFactoryPackageRegistry.nameOfPackage.selector;
        funcs[9] = IDiamondFactoryPackageRegistry.packagesByName.selector;
        funcs[10] = IDiamondFactoryPackageRegistry.packagesByInterface.selector;
        funcs[11] = IDiamondFactoryPackageRegistry.packagesByFacet.selector;
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
