// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {
    DiamondFactoryPackageRegistryTarget
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryTarget.sol";

// tag::DiamondFactoryPackageRegistryFacet[]
/**
 * @title DiamondFactoryPackageRegistryFacet - Reusable Diamond facet providing registry for deployed Diamond Factory Packages (by name, interface, facet, canonical per interface).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends DiamondFactoryPackageRegistryTarget for business logic (delegates to DiamondFactoryPackageRegistryService + DiamondFactoryPackageRegistryRepo). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract DiamondFactoryPackageRegistryFacet is DiamondFactoryPackageRegistryTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory name) {
        return type(DiamondFactoryPackageRegistryFacet).name;
    }

    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondFactoryPackageRegistry).interfaceId;
    }

    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
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

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::DiamondFactoryPackageRegistryFacet[]
