// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "contracts/access/reentrancy/ReentrancyLockRepo.sol";
import {ReentrancyLockTarget} from "contracts/access/reentrancy/ReentrancyLockTarget.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";

// import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "contracts/crane/interfaces/ICreate3Aware.sol";

contract ReentrancyLockFacet is ReentrancyLockTarget, IFacet {
    function facetInterfaces() public pure returns (bytes4[] memory interfaces_) {
        interfaces_ = new bytes4[](1);
        interfaces_[0] = IReentrancyLock.isLocked.selector;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs_) {
        funcs_ = new bytes4[](1);
        funcs_[0] = ReentrancyLockTarget.isLocked.selector;
    }
}
