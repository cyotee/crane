// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3GyroECLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3GyroECLPPool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3GyroECLPPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolTarget.sol";

/**
 * @title Balancer V3 Gyro ECLP Pool Facet
 * @notice A facet implementing Balancer V3 Gyro ECLP pool functionality.
 * @dev Exposes ECLP pool math functions through the Diamond pattern.
 * Swap calculations use GyroECLPMath from Balancer V3 libraries with
 * configurable elliptic curve parameters for concentrated liquidity.
 */
contract BalancerV3GyroECLPPoolFacet is BalancerV3GyroECLPPoolTarget, IFacet {
    /**
     * @notice Returns the name of this facet.
     * @return name The facet name.
     */
    function facetName() public pure returns (string memory name) {
        return type(BalancerV3GyroECLPPoolFacet).name;
    }

    /**
     * @notice Returns the interfaces implemented by this facet.
     * @return interfaces Array of interface IDs.
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);

        interfaces[0] = type(IBalancerV3Pool).interfaceId;
        interfaces[1] = type(IBalancerV3GyroECLPPool).interfaceId;
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

        // IBalancerV3GyroECLPPool functions
        funcs[3] = IBalancerV3GyroECLPPool.getECLPParams.selector;
        funcs[4] = IBalancerV3GyroECLPPool.getMinimumSwapFeePercentage.selector;
        funcs[5] = IBalancerV3GyroECLPPool.getMaximumSwapFeePercentage.selector;
        funcs[6] = IBalancerV3GyroECLPPool.getMinimumInvariantRatio.selector;
        funcs[7] = IBalancerV3GyroECLPPool.getMaximumInvariantRatio.selector;
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
