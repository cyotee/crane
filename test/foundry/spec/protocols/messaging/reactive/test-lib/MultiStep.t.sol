// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {MiniOrigin, MiniBridge, MiniReactive} from "./mocks/SampleMultiStepContracts.sol";

/// @notice Tests multi-step reactive cycles where callback execution produces new events
///         that trigger further react() calls and callbacks.
///
///         Flow: Deposit → react() → Callback to Bridge → Confirmation event
///               → react() → self-Callback → deliver()
contract MultiStepTest is ReactiveTest {
    MiniOrigin origin;
    MiniBridge bridge;
    MiniReactive rc;

    uint256 constant ORIGIN_CHAIN = 11155111; // Sepolia
    uint256 constant DEST_CHAIN = 42161;      // Arbitrum

    function setUp() public override {
        super.setUp();

        origin = new MiniOrigin();
        bridge = new MiniBridge(address(proxy));

        rc = new MiniReactive(
            address(sys),
            ORIGIN_CHAIN,
            DEST_CHAIN,
            reactiveChainId,
            address(origin),
            address(bridge)
        );
    }

    function testSingleStepOnlyGetsFirstHop() public {
        // Single-step should only produce the first callback (to bridge)
        deal(address(this), 1 ether);
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.1 ether,
            ORIGIN_CHAIN
        );

        // Only the first hop: Callback to bridge
        assertCallbackCount(results, 1);
        assertCallbackEmitted(results, address(bridge));
        assertCallbackSuccess(results, 0);

        // Bridge received the callback
        assertEq(bridge.confirmationCount(), 1);

        // But delivery did NOT happen (needs second hop)
        assertEq(rc.deliveryCount(), 0);
    }

    function testFullCycleCompletesAllHops() public {
        // Full-cycle should process both hops
        deal(address(this), 1 ether);
        CallbackResult[] memory results = triggerFullCycleWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.1 ether,
            ORIGIN_CHAIN,
            10 // max iterations
        );

        // Both callbacks should have been produced
        assertGt(results.length, 1, "Expected multiple callbacks");
        assertCallbackEmitted(results, address(bridge));
        assertCallbackEmitted(results, address(rc));

        // Bridge received the first callback
        assertEq(bridge.confirmationCount(), 1);

        // Delivery completed (second hop via self-callback)
        assertEq(rc.deliveryCount(), 1);
        assertEq(rc.deliveredAmount(), 0.1 ether);
    }

    function testFullCycleStopsWhenQuiescent() public {
        deal(address(this), 1 ether);
        CallbackResult[] memory results = triggerFullCycleWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.1 ether,
            ORIGIN_CHAIN,
            100 // high max iterations — should still stop early
        );

        // Exactly 2 callbacks: one to bridge, one self-callback for delivery
        assertCallbackCount(results, 2);
    }

    function testFullCycleAllCallbacksSucceed() public {
        deal(address(this), 1 ether);
        CallbackResult[] memory results = triggerFullCycleWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.1 ether,
            ORIGIN_CHAIN,
            10
        );

        for (uint256 i = 0; i < results.length; i++) {
            assertCallbackSuccess(results, i);
        }
    }

    function testFullCycleWithZeroValue() public {
        // Zero-value deposit should still trigger the full cycle
        CallbackResult[] memory results = triggerFullCycle(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            ORIGIN_CHAIN,
            10
        );

        assertCallbackCount(results, 2);
        assertEq(rc.deliveryCount(), 1);
        assertEq(rc.deliveredAmount(), 0);
    }
}
