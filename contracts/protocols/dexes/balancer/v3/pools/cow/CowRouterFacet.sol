// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {ICowRouter} from "@balancer-labs/v3-interfaces/contracts/pool-cow/ICowRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {CowRouterTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterTarget.sol";

/**
 * @title CowRouterFacet
 * @notice Diamond facet implementing Balancer V3 CoW Router functionality.
 * @dev Exposes CoW router functions through the diamond pattern.
 * Handles MEV-protected swaps with surplus donations for CoW Protocol integration.
 *
 * Implements:
 * - ICowRouter: Swap+donate, donate, fee management
 */
contract CowRouterFacet is CowRouterTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                IFacet Interface                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(CowRouterFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICowRouter).interfaceId;
    }

    /**
     * @notice Returns the function selectors exposed by this facet.
     * @return funcs Array of function selectors.
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](12);

        // ICowRouter getters
        funcs[0] = ICowRouter.getProtocolFeePercentage.selector;
        funcs[1] = ICowRouter.getMaxProtocolFeePercentage.selector;
        funcs[2] = ICowRouter.getCollectedProtocolFees.selector;
        funcs[3] = ICowRouter.getFeeSweeper.selector;

        // ICowRouter setters
        funcs[4] = ICowRouter.setProtocolFeePercentage.selector;
        funcs[5] = ICowRouter.setFeeSweeper.selector;

        // ICowRouter operations
        funcs[6] = ICowRouter.swapExactInAndDonateSurplus.selector;
        funcs[7] = ICowRouter.swapExactOutAndDonateSurplus.selector;
        funcs[8] = ICowRouter.donate.selector;
        funcs[9] = ICowRouter.withdrawCollectedProtocolFees.selector;

        // Internal hooks (called by vault)
        funcs[10] = CowRouterTarget.swapAndDonateSurplusHook.selector;
        funcs[11] = CowRouterTarget.donateHook.selector;
    }

    /**
     * @notice Returns comprehensive metadata about this facet.
     * @return name_ The facet name.
     * @return interfaces Array of interface IDs.
     * @return functions Array of function selectors.
     */
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
