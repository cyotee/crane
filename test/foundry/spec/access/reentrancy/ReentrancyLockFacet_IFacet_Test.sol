// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { CraneTest } from "../../../../../contracts/test/CraneTest.sol";
import { IFacet } from "../../../../../contracts/interfaces/IFacet.sol";
import { IReentrancyLock } from "../../../../../contracts/interfaces/IReentrancyLock.sol";
// import { ReentrancyLockFacet } from "../../../../../contracts/access/reentrancy/ReentrancyLockFacet.sol";

contract ReentrancyLockFacet_IFacet_Test is CraneTest {
    function test_IFacet_facetInterfaces_ReentrancyLockFacet() public {
        bytes4[] memory expectedInterfaces = new bytes4[](1);
        expectedInterfaces[0] = type(IReentrancyLock).interfaceId;

        expect_IFacet_facetInterfaces(
            IFacet(address(reentrancyLockFacet())),
            expectedInterfaces
        );

        assertTrue(
            hasValid_IFacet_facetInterfaces(
                IFacet(address(reentrancyLockFacet()))
            ),
            "ReentrancyLockFacet should expose correct interface IDs"
        );
    }

    function test_IFacet_facetFuncs_ReentrancyLockFacet() public {
        bytes4[] memory expectedFuncs = new bytes4[](1);
        expectedFuncs[0] = IReentrancyLock.isLocked.selector;

        expect_IFacet_facetFuncs(
            IFacet(address(reentrancyLockFacet())),
            expectedFuncs
        );

        assertTrue(
            hasValid_IFacet_facetFuncs(
                IFacet(address(reentrancyLockFacet()))
            ),
            "ReentrancyLockFacet should expose correct function selectors"
        );
    }
} 