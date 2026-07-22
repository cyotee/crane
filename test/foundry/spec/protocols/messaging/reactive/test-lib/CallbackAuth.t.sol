// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {MockCallbackProxy} from "@crane/contracts/external/reactive-test-lib/mock/MockCallbackProxy.sol";
import {SampleOrigin} from "./mocks/SampleOrigin.sol";
import {SampleReactiveContract} from "./mocks/SampleReactiveContract.sol";
import {SampleCallback} from "./mocks/SampleCallback.sol";

contract CallbackAuthTest is ReactiveTest {
    SampleOrigin origin;
    SampleReactiveContract rc;
    SampleCallback cb;

    uint256 constant ORIGIN_CHAIN = 11155111;
    uint256 constant DEST_CHAIN = 11155111;

    function setUp() public override {
        super.setUp();

        origin = new SampleOrigin();
        cb = new SampleCallback(address(proxy));

        uint256 receivedTopic = uint256(keccak256("Received(address,address,uint256)"));

        rc = new SampleReactiveContract(
            address(sys),
            ORIGIN_CHAIN,
            DEST_CHAIN,
            address(origin),
            receivedTopic,
            address(cb)
        );
    }

    function testRvmIdOverwrite() public {
        // Trigger a callback and verify the RVM ID is correctly injected
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        assertCallbackCount(results, 1);
        // The first argument in the callback should be rvmId (address(this))
        assertEq(cb.lastRvmId(), rvmId);
    }

    function testCallbackExecutedByProxy() public {
        // Verify callback is executed via the proxy (not direct)
        triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        assertEq(cb.callbackCount(), 1);
    }

    function testCustomRvmId() public {
        // Override rvmId and verify it propagates
        address customRvmId = makeAddr("customDeployer");
        rvmId = customRvmId;

        triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether,
            ORIGIN_CHAIN
        );

        assertEq(cb.lastRvmId(), customRvmId);
    }
}
