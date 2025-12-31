// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {
    IUnbalancedLiquidityInvariantRatioBounds
} from "@balancer-labs/v3-interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "@crane/src/constants/Constants.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

/**
 * @title BalancedLiquidityInvariantRatioBoundsFacet
 * @notice For Balancer V3 pools that require a balanced liquidity invariant ratio bounds.
 * @notice Most useful for pools containing only one token as liquidity.
 */
contract BalancedLiquidityInvariantRatioBoundsFacet is
    Create3AwareContract,
    IUnbalancedLiquidityInvariantRatioBounds,
    IFacet
{
    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IUnbalancedLiquidityInvariantRatioBounds.getMinimumInvariantRatio.selector;
        funcs[1] = IUnbalancedLiquidityInvariantRatioBounds.getMaximumInvariantRatio.selector;
    }

    // Invariant shrink limit: non-proportional remove cannot cause the invariant to decrease by less than this ratio
    function getMinimumInvariantRatio() external pure returns (uint256) {
        return ONE_WAD;
    }

    // Invariant growth limit: non-proportional add cannot cause the invariant to increase by more than this ratio
    function getMaximumInvariantRatio() external pure returns (uint256) {
        return 0;
    }
}
