// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AerodromeRouterAwareRepo} from "@crane/contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";

/**
 * @title AerodromeRouterAwareHarness
 * @notice Exposes AerodromeRouterAwareRepo library functions for testing.
 */
contract AerodromeRouterAwareHarness {
    function initialize(IRouter router_) external {
        AerodromeRouterAwareRepo._initialize(router_);
    }

    function initializeWithSlot(bytes32 slot, IRouter router_) external {
        AerodromeRouterAwareRepo._initialize(AerodromeRouterAwareRepo._layout(slot), router_);
    }

    function aerodromeRouter() external view returns (IRouter) {
        return AerodromeRouterAwareRepo._aerodromeRouter();
    }

    function aerodromeRouterFromSlot(bytes32 slot) external view returns (IRouter) {
        return AerodromeRouterAwareRepo._aerodromeRouter(AerodromeRouterAwareRepo._layout(slot));
    }

    function storageSlot() external pure returns (bytes32) {
        return AerodromeRouterAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title AerodromeRouterAwareRepo_Test
 * @notice Tests for AerodromeRouterAwareRepo library.
 */
contract AerodromeRouterAwareRepo_Test is Test {
    AerodromeRouterAwareHarness internal harness;
    IRouter internal mockRouter;

    function setUp() public {
        harness = new AerodromeRouterAwareHarness();
        mockRouter = IRouter(address(0xABCD));
    }

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("crane.aerodrome.router.aware");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    function test_initialize_storesRouter() public {
        harness.initialize(mockRouter);
        assertEq(address(harness.aerodromeRouter()), address(mockRouter), "Router should be stored");
    }

    function test_initialize_canOverwrite() public {
        IRouter router1 = IRouter(address(0x1111));
        IRouter router2 = IRouter(address(0x2222));

        harness.initialize(router1);
        harness.initialize(router2);
        assertEq(address(harness.aerodromeRouter()), address(router2), "Router should be overwritten");
    }

    function test_initializeWithSlot_storesAtCustomSlot() public {
        bytes32 customSlot = keccak256("custom.aerodrome.slot");

        harness.initializeWithSlot(customSlot, mockRouter);

        assertEq(address(harness.aerodromeRouter()), address(0), "Default slot should be empty");
        assertEq(
            address(harness.aerodromeRouterFromSlot(customSlot)),
            address(mockRouter),
            "Custom slot should have router"
        );
    }

    function test_slotIsolation_differentSlotsAreIndependent() public {
        bytes32 slot1 = keccak256("aero.slot1");
        bytes32 slot2 = keccak256("aero.slot2");
        IRouter router1 = IRouter(address(0x1111));
        IRouter router2 = IRouter(address(0x2222));

        harness.initializeWithSlot(slot1, router1);
        harness.initializeWithSlot(slot2, router2);

        assertEq(address(harness.aerodromeRouterFromSlot(slot1)), address(router1));
        assertEq(address(harness.aerodromeRouterFromSlot(slot2)), address(router2));
    }

    function test_aerodromeRouter_returnsZeroBeforeInit() public view {
        assertEq(address(harness.aerodromeRouter()), address(0), "Should return zero before init");
    }

    function testFuzz_initialize_anyAddress(address routerAddr) public {
        vm.assume(routerAddr != address(0));
        harness.initialize(IRouter(routerAddr));
        assertEq(address(harness.aerodromeRouter()), routerAddr);
    }
}
