// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ITokenTransferRelayer} from "@crane/contracts/interfaces/ITokenTransferRelayer.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {
    TokenTransferRelayerTarget
} from "@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerTarget.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// tag::TokenTransferRelayerFacet[]
/**
 * @title TokenTransferRelayerFacet - Reusable Diamond facet implementing ITokenTransferRelayer (cross-domain token transfer relayer with nonce tracking and recovery for Superchain).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends TokenTransferRelayerTarget for business logic (delegates to TokenTransferRelayerRepo). Implements IFacet (via FacetBase) to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract TokenTransferRelayerFacet is TokenTransferRelayerTarget, FacetBase {
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
    function facetName() public pure override returns (string memory name) {
        return "TokenTransferRelayerFacet";
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
    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(ITokenTransferRelayer).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        return interfaces;
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
    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = ITokenTransferRelayer.nextNonce.selector;
        funcs[1] = ITokenTransferRelayer.relayTokenTransfer.selector;
        funcs[2] = ITokenTransferRelayer.recoverToken.selector;
        return funcs;
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
        override
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::TokenTransferRelayerFacet[]
