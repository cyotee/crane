// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IReentrancyLock} from "@crane/contracts/interfaces/IReentrancyLock.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";
import {ReentrancyLockTarget} from "@crane/contracts/access/reentrancy/ReentrancyLockTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

// import {Create3AwareContract} from "@crane/contracts/crane/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/crane/interfaces/ICreate3Aware.sol";

contract ReentrancyLockFacet is ReentrancyLockTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(ReentrancyLockFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces_) {
        interfaces_ = new bytes4[](1);
        interfaces_[0] = IReentrancyLock.isLocked.selector;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs_) {
        funcs_ = new bytes4[](1);
        funcs_[0] = ReentrancyLockTarget.isLocked.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
