// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IReentrancyLock} from "contracts/crane/interfaces/IReentrancyLock.sol";
// import { ReentrancyLockFacet } from "contracts/crane/access/reentrancy/ReentrancyLockFacet.sol";

contract ReentrancyLockFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(reentrancyLockFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IReentrancyLock).interfaceId;
    }

    function controlFacetFuncs() public pure virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);
        controlFuncs[0] = IReentrancyLock.isLocked.selector;
    }
}
