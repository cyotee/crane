// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3Gyro2CLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3Gyro2CLPPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3Gyro2CLPPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolTarget.sol";

/**
 * @title Balancer V3 Gyro 2-CLP Pool Facet
 * @notice A facet implementing Balancer V3 Gyro 2-CLP pool functionality.
 * @dev Exposes 2-CLP pool math functions through the Diamond pattern.
 * Swap calculations use Gyro2CLPMath from Balancer V3 libraries with
 * configurable sqrtAlpha and sqrtBeta parameters for concentrated liquidity.
 */
contract BalancerV3Gyro2CLPPoolFacet is BalancerV3Gyro2CLPPoolTarget, IFacet {
    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(BalancerV3Gyro2CLPPoolFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);

        interfaces[0] = type(IBalancerV3Pool).interfaceId;
        interfaces[1] = type(IBalancerV3Gyro2CLPPool).interfaceId;
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

        // IBalancerV3Gyro2CLPPool functions
        funcs[3] = IBalancerV3Gyro2CLPPool.get2CLPParams.selector;
        funcs[4] = IBalancerV3Gyro2CLPPool.getMinimumSwapFeePercentage.selector;
        funcs[5] = IBalancerV3Gyro2CLPPool.getMaximumSwapFeePercentage.selector;
        funcs[6] = IBalancerV3Gyro2CLPPool.getMinimumInvariantRatio.selector;
        funcs[7] = IBalancerV3Gyro2CLPPool.getMaximumInvariantRatio.selector;
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
