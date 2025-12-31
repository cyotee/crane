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

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

contract StandardUnbalancedLiquidityInvariantRatioBoundsFacet is
    Create3AwareContract,
    IUnbalancedLiquidityInvariantRatioBounds,
    IFacet
{
    uint256 private constant _MIN_INVARIANT_RATIO = 70e16; // 70%
    uint256 private constant _MAX_INVARIANT_RATIO = 300e16; // 300%

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
        return _MIN_INVARIANT_RATIO;
    }

    // Invariant growth limit: non-proportional add cannot cause the invariant to increase by more than this ratio
    function getMaximumInvariantRatio() external pure returns (uint256) {
        return _MAX_INVARIANT_RATIO;
    }
}
