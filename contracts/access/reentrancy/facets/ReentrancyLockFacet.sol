// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IReentrancyLock} from "../interfaces/IReentrancyLock.sol";
import {ReentrancyLockTarget} from "../targets/ReentrancyLockTarget.sol";
import {IFacet} from "../../../factories/create2/callback/diamondPkg/interfaces/IFacet.sol";

import {Create2CallbackContract} from "../../../factories/create2/callback/targets/Create2CallbackContract.sol";

contract ReentrancyLockFacet
is
ReentrancyLockTarget,
Create2CallbackContract,
IFacet
{

    function facetInterfaces()
    public pure returns(bytes4[] memory interfaces_) {
        interfaces_ = new bytes4[](1);
        interfaces_[0] = IReentrancyLock.isLocked.selector;
    }

    function facetFuncs()
    public pure returns(bytes4[] memory funcs_) {
        funcs_ = new bytes4[](1);
        funcs_[0] = ReentrancyLockTarget.isLocked.selector;
    }

}