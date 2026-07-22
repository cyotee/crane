// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {SampleOrigin} from "./mocks/SampleOrigin.sol";
import {SampleReactiveContract} from "./mocks/SampleReactiveContract.sol";
import {SampleCallback} from "./mocks/SampleCallback.sol";

contract BasicDemoTest is ReactiveTest {
    SampleOrigin origin;
    SampleReactiveContract rc;
    SampleCallback cb;

    uint256 constant ORIGIN_CHAIN = 11155111; // Sepolia
    uint256 constant DEST_CHAIN = 11155111;

    // topic0 for Received(address,address,uint256)
    uint256 receivedTopic;

    function setUp() public override {
        super.setUp();

        receivedTopic = uint256(keccak256("Received(address,address,uint256)"));

        // Deploy origin contract
        origin = new SampleOrigin();

        // Deploy callback contract — pass proxy address as callback_sender
        cb = new SampleCallback(address(proxy));

        // Deploy reactive contract — constructor calls subscribe() on MockSystemContract
        rc = new SampleReactiveContract(
            address(sys),
            ORIGIN_CHAIN,
            DEST_CHAIN,
            address(origin),
            receivedTopic,
            address(cb)
        );
    }

    function testCallbackTriggeredAboveThreshold() public {
        // Send 0.002 ETH to origin — emits Received event with value > 0.001 ether
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        // Callback should have fired
        assertCallbackCount(results, 1);
        assertCallbackSuccess(results, 0);
        assertCallbackEmitted(results, address(cb));

        // Verify the callback contract received the call
        assertEq(cb.callbackCount(), 1);
        assertEq(cb.lastAmount(), 0.002 ether);
    }

    function testNoCallbackBelowThreshold() public {
        // Send 0.0005 ETH — below 0.001 threshold
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.0005 ether,
            ORIGIN_CHAIN
        );

        assertNoCallbacks(results);
        assertEq(cb.callbackCount(), 0);
    }

    function testReactCalledOnMatchingEvent() public {
        triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        // react() should have been called
        assertEq(rc.reactCallCount(), 1);
    }

    function testRvmIdInjection() public {
        // Verify the RVM ID (deployer address) is injected into callback payload
        triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        // The callback should have received rvmId (address(this)) as the first arg
        assertEq(cb.lastRvmId(), rvmId);
    }
}
