// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ISuperChainBridgeTokenRegistry} from "@crane/contracts/interfaces/ISuperChainBridgeTokenRegistry.sol";
import {
    SuperChainBridgeTokenRegistryTarget
} from "@crane/contracts/protocols/l2s/superchain/registries/token/bridge/SuperChainBridgeTokenRegistryTarget.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::SuperChainBridgeTokenRegistryFacet[]
/**
 * @title SuperChainBridgeTokenRegistryFacet - Reusable Diamond facet implementing ISuperChainBridgeTokenRegistry (personal SuperChain bridge token registry of remote tokens + min gas limits).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends SuperChainBridgeTokenRegistryTarget for business logic (delegates to SuperChainBridgeTokenRegistryRepo). Implements IFacet (via FacetBase) to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract SuperChainBridgeTokenRegistryFacet is SuperChainBridgeTokenRegistryTarget, FacetBase {
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
    function facetName() public view virtual override returns (string memory name) {
        return type(SuperChainBridgeTokenRegistryFacet).name;
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
    function facetInterfaces() public view virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISuperChainBridgeTokenRegistry).interfaceId;
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
    function facetFuncs() public view virtual override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = ISuperChainBridgeTokenRegistry.getRemoteToken.selector;
        funcs[1] = ISuperChainBridgeTokenRegistry.getMinGasLimit.selector;
        funcs[2] = ISuperChainBridgeTokenRegistry.getRemoteTokenAndLimit.selector;
        funcs[3] = ISuperChainBridgeTokenRegistry.setRemoteToken.selector;
        funcs[4] = ISuperChainBridgeTokenRegistry.setRemoteTokenMinGasLimit.selector;
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
        public
        view
        virtual
        override
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::SuperChainBridgeTokenRegistryFacet[]
