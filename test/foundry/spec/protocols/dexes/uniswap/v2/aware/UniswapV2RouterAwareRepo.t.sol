// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV2RouterAwareRepo} from "@crane/contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title UniswapV2RouterAwareHarness
 * @notice Exposes UniswapV2RouterAwareRepo library functions for testing.
 */
contract UniswapV2RouterAwareHarness {
    function initialize(IUniswapV2Router router_) external {
        UniswapV2RouterAwareRepo._initialize(router_);
    }

    function initializeWithSlot(bytes32 slot, IUniswapV2Router router_) external {
        UniswapV2RouterAwareRepo._initialize(UniswapV2RouterAwareRepo._layout(slot), router_);
    }

    function uniswapV2Router() external view returns (IUniswapV2Router) {
        return UniswapV2RouterAwareRepo._uniswapV2Router();
    }

    function uniswapV2RouterFromSlot(bytes32 slot) external view returns (IUniswapV2Router) {
        return UniswapV2RouterAwareRepo._uniswapV2Router(UniswapV2RouterAwareRepo._layout(slot));
    }

    function storageSlot() external pure returns (bytes32) {
        return UniswapV2RouterAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title UniswapV2RouterAwareRepo_Test
 * @notice Tests for UniswapV2RouterAwareRepo library.
 */
contract UniswapV2RouterAwareRepo_Test is Test {
    UniswapV2RouterAwareHarness internal harness;
    IUniswapV2Router internal mockRouter;

    function setUp() public {
        harness = new UniswapV2RouterAwareHarness();
        mockRouter = IUniswapV2Router(address(0x5678));
    }

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("crane.uniswap.v2.router.aware");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    function test_initialize_storesRouter() public {
        harness.initialize(mockRouter);
        assertEq(address(harness.uniswapV2Router()), address(mockRouter), "Router should be stored");
    }

    function test_initialize_canOverwrite() public {
        IUniswapV2Router router1 = IUniswapV2Router(address(0x1111));
        IUniswapV2Router router2 = IUniswapV2Router(address(0x2222));

        harness.initialize(router1);
        harness.initialize(router2);
        assertEq(address(harness.uniswapV2Router()), address(router2), "Router should be overwritten");
    }

    function test_initializeWithSlot_storesAtCustomSlot() public {
        bytes32 customSlot = keccak256("custom.router.slot");

        harness.initializeWithSlot(customSlot, mockRouter);

        assertEq(address(harness.uniswapV2Router()), address(0), "Default slot should be empty");
        assertEq(
            address(harness.uniswapV2RouterFromSlot(customSlot)),
            address(mockRouter),
            "Custom slot should have router"
        );
    }

    function test_slotIsolation_differentSlotsAreIndependent() public {
        bytes32 slot1 = keccak256("router.slot1");
        bytes32 slot2 = keccak256("router.slot2");
        IUniswapV2Router router1 = IUniswapV2Router(address(0x1111));
        IUniswapV2Router router2 = IUniswapV2Router(address(0x2222));

        harness.initializeWithSlot(slot1, router1);
        harness.initializeWithSlot(slot2, router2);

        assertEq(address(harness.uniswapV2RouterFromSlot(slot1)), address(router1));
        assertEq(address(harness.uniswapV2RouterFromSlot(slot2)), address(router2));
    }

    function test_uniswapV2Router_returnsZeroBeforeInit() public view {
        assertEq(address(harness.uniswapV2Router()), address(0), "Should return zero before init");
    }

    function testFuzz_initialize_anyAddress(address routerAddr) public {
        vm.assume(routerAddr != address(0));
        harness.initialize(IUniswapV2Router(routerAddr));
        assertEq(address(harness.uniswapV2Router()), routerAddr);
    }
}
