// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3StablePool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3StablePool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3StablePoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolTarget.sol";

/**
 * @title Balancer V3 Stable Pool Facet
 * @notice A facet implementing Balancer V3 stable pool functionality.
 * @dev Exposes stable pool math functions through the diamond pattern.
 * Swap calculations use StableMath from Balancer V3 libraries with configurable
 * amplification parameter for assets that trade near parity.
 */
contract BalancerV3StablePoolFacet is BalancerV3StablePoolTarget, IFacet {
    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(BalancerV3StablePoolFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);

        interfaces[0] = type(IBalancerV3Pool).interfaceId;
        interfaces[1] = type(IBalancerV3StablePool).interfaceId;
    }

    /**
     * @notice Returns the function selectors exposed by this facet.
     * @return funcs Array of function selectors.
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);

        funcs[0] = IBalancerV3Pool.computeInvariant.selector;
        funcs[1] = IBalancerV3Pool.computeBalance.selector;
        funcs[2] = IBalancerV3Pool.onSwap.selector;
        funcs[3] = IBalancerV3StablePool.getAmplificationParameter.selector;
        funcs[4] = IBalancerV3StablePool.getAmplificationState.selector;
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
