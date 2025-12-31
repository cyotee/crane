// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {ISwapFeePercentageBounds} from "@balancer-labs/v3-interfaces/contracts/vault/ISwapFeePercentageBounds.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

contract StandardSwapFeePercentageBoundsFacet is Create3AwareContract, ISwapFeePercentageBounds, IFacet {
    // uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%

    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISwapFeePercentageBounds).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = ISwapFeePercentageBounds.getMinimumSwapFeePercentage.selector;
        funcs[1] = ISwapFeePercentageBounds.getMaximumSwapFeePercentage.selector;
    }

    //The minimum swap fee percentage for a pool
    function getMinimumSwapFeePercentage() external pure returns (uint256) {
        return _MIN_SWAP_FEE_PERCENTAGE;
    }

    // The maximum swap fee percentage for a pool
    function getMaximumSwapFeePercentage() external pure returns (uint256) {
        return _MAX_SWAP_FEE_PERCENTAGE;
    }
}
