// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {ICowPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowPool.sol";
import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {CowPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolTarget.sol";

/**
 * @title CowPoolFacet
 * @notice Diamond facet implementing Balancer V3 CoW Pool functionality.
 * @dev Exposes CoW pool functions through the diamond pattern.
 * Includes weighted pool math, hook-based access control, and CoW-specific data retrieval.
 *
 * Implements:
 * - ICowPool: CoW-specific data and router management
 * - IHooks: Balancer V3 hook interface for access control
 * - IBalancerV3Pool: Pool math (computeInvariant, computeBalance, onSwap)
 * - IBalancerV3WeightedPool: Weighted pool functions (getNormalizedWeights)
 */
contract CowPoolFacet is CowPoolTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                IFacet Interface                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(CowPoolFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](4);

        interfaces[0] = type(ICowPool).interfaceId;
        interfaces[1] = type(IHooks).interfaceId;
        interfaces[2] = type(IBalancerV3Pool).interfaceId;
        interfaces[3] = type(IBalancerV3WeightedPool).interfaceId;
    }

    /**
     * @notice Returns the function selectors exposed by this facet.
     * @return funcs Array of function selectors.
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](19);

        // ICowPool functions
        funcs[0] = ICowPool.getTrustedCowRouter.selector;
        funcs[1] = ICowPool.refreshTrustedCowRouter.selector;
        funcs[2] = ICowPool.getCowPoolDynamicData.selector;
        funcs[3] = ICowPool.getCowPoolImmutableData.selector;

        // IHooks functions
        funcs[4] = IHooks.onRegister.selector;
        funcs[5] = IHooks.getHookFlags.selector;
        funcs[6] = IHooks.onBeforeInitialize.selector;
        funcs[7] = IHooks.onAfterInitialize.selector;
        funcs[8] = IHooks.onBeforeAddLiquidity.selector;
        funcs[9] = IHooks.onAfterAddLiquidity.selector;
        funcs[10] = IHooks.onBeforeRemoveLiquidity.selector;
        funcs[11] = IHooks.onAfterRemoveLiquidity.selector;
        funcs[12] = IHooks.onBeforeSwap.selector;
        funcs[13] = IHooks.onAfterSwap.selector;
        funcs[14] = IHooks.onComputeDynamicSwapFeePercentage.selector;

        // IBalancerV3Pool functions
        funcs[15] = IBalancerV3Pool.computeInvariant.selector;
        funcs[16] = IBalancerV3Pool.computeBalance.selector;
        funcs[17] = IBalancerV3Pool.onSwap.selector;

        // IBalancerV3WeightedPool functions
        funcs[18] = IBalancerV3WeightedPool.getNormalizedWeights.selector;

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
