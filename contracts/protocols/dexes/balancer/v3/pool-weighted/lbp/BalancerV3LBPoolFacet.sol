// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3LBPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3LBPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3LBPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolTarget.sol";

/**
 * @title Balancer V3 LBPool Facet
 * @notice A facet implementing Balancer V3 Liquidity Bootstrapping Pool functionality.
 * @dev Exposes LBP functions through the diamond pattern for token launches with
 * time-based gradual weight transitions.
 */
contract BalancerV3LBPoolFacet is BalancerV3LBPoolTarget, IFacet {
    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(BalancerV3LBPoolFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);

        interfaces[0] = type(IBalancerV3Pool).interfaceId;
        interfaces[1] = type(IBalancerV3LBPool).interfaceId;
    }

    /**
     * @notice Returns the function selectors exposed by this facet.
     * @return funcs Array of function selectors.
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](8);

        // IBalancerV3Pool functions
        funcs[0] = IBalancerV3Pool.computeInvariant.selector;
        funcs[1] = IBalancerV3Pool.computeBalance.selector;
        funcs[2] = IBalancerV3Pool.onSwap.selector;

        // IBalancerV3LBPool functions
        funcs[3] = IBalancerV3LBPool.getNormalizedWeights.selector;
        funcs[4] = IBalancerV3LBPool.getGradualWeightUpdateParams.selector;
        funcs[5] = IBalancerV3LBPool.isSwapEnabled.selector;
        funcs[6] = IBalancerV3LBPool.getTokenIndices.selector;
        funcs[7] = IBalancerV3LBPool.isProjectTokenSwapInBlocked.selector;
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
