// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {SampleOrigin} from "./mocks/SampleOrigin.sol";
import {SampleSelfCallbackContract} from "./mocks/SampleSelfCallbackContract.sol";

/// @notice Tests same-chain (self) callbacks where react() emits Callback targeting
///         the reactive contract itself on the reactive chain. These callbacks must be
///         delivered via SERVICE_ADDR, not the proxy.
contract SelfCallbackTest is ReactiveTest {
    SampleOrigin origin;
    SampleSelfCallbackContract rc;

    uint256 constant ORIGIN_CHAIN = 11155111; // Sepolia

    function setUp() public override {
        super.setUp();

        origin = new SampleOrigin();

        uint256 receivedTopic = uint256(keccak256("Received(address,address,uint256)"));

        rc = new SampleSelfCallbackContract(
            address(sys),
            reactiveChainId,    // reactive chain ID for self-callbacks
            ORIGIN_CHAIN,
            address(origin),
            receivedTopic
        );
    }

    function testSelfCallbackDeliveredViaServiceAddr() public {
        // Trigger an event that causes react() to emit a self-callback
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.01 ether,
            ORIGIN_CHAIN
        );

        // Callback should succeed (delivered via SERVICE_ADDR, not proxy)
        assertCallbackCount(results, 1);
        assertCallbackSuccess(results, 0);

        // Verify the self-callback was actually executed
        assertEq(rc.deliveryCount(), 1);
        assertEq(rc.deliveredAmount(), 0.01 ether);
    }

    function testSelfCallbackRvmIdInjected() public {
        triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.01 ether,
            ORIGIN_CHAIN
        );

        // RVM ID should be injected even for self-callbacks
        assertEq(rc.deliveredRvmId(), rvmId);
    }

    function testSelfCallbackTargetsReactiveChain() public {
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.01 ether,
            ORIGIN_CHAIN
        );

        // Callback chain ID should be the reactive chain
        assertEq(results[0].chainId, reactiveChainId);
        assertEq(results[0].target, address(rc));
    }
}
