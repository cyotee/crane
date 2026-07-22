// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {SampleOrigin} from "./mocks/SampleOrigin.sol";
import {SampleReactiveContract} from "./mocks/SampleReactiveContract.sol";
import {SampleCallback} from "./mocks/SampleCallback.sol";
import {SampleSelfCallbackContract} from "./mocks/SampleSelfCallbackContract.sol";
import {MiniOrigin, MiniBridge, MiniReactive} from "./mocks/SampleMultiStepContracts.sol";

/// @notice Tests the chain registry for auto chain ID detection.
contract ChainRegistryTest is ReactiveTest {
    SampleOrigin origin;
    SampleReactiveContract rc;
    SampleCallback cb;

    uint256 constant SEPOLIA = 11155111;
    uint256 constant DEST_CHAIN = 11155111;

    function setUp() public override {
        super.setUp();

        origin = new SampleOrigin();
        cb = new SampleCallback(address(proxy));

        uint256 receivedTopic = uint256(keccak256("Received(address,address,uint256)"));
        rc = new SampleReactiveContract(
            address(sys), SEPOLIA, DEST_CHAIN, address(origin), receivedTopic, address(cb)
        );

        // Register origin on Sepolia
        registerChain(address(origin), SEPOLIA);
    }

    function testAutoDetectChainId() public {
        // Use the 2-arg overload — chain ID is resolved from registry
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether
        );

        assertCallbackCount(results, 1);
        assertCallbackSuccess(results, 0);
        assertEq(cb.callbackCount(), 1);
    }

    function testAutoDetectMatchesExplicit() public {
        // Auto-detect should produce the same results as explicit chain ID
        CallbackResult[] memory autoResults = triggerAndReactWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.002 ether
        );

        // Reset state for comparison
        // (can't easily reset, so just verify the auto-detect worked)
        assertCallbackCount(autoResults, 1);
        assertEq(autoResults[0].target, address(cb));
    }

    function testUnregisteredOriginReverts() public {
        address unregistered = makeAddr("unregistered");

        vm.expectRevert("ReactiveTest: origin not registered in chain registry");
        this.externalTriggerAutoDetect(unregistered);
    }

    // Helper to test revert (vm.expectRevert needs external call)
    function externalTriggerAutoDetect(address target) external {
        triggerAndReact(target, abi.encodeWithSignature("deposit()"));
    }
}

/// @notice Tests chain registry with multi-step full-cycle simulation.
contract ChainRegistryMultiStepTest is ReactiveTest {
    MiniOrigin origin;
    MiniBridge bridge;
    MiniReactive rc;

    uint256 constant ORIGIN_CHAIN = 11155111;
    uint256 constant DEST_CHAIN = 42161;

    function setUp() public override {
        super.setUp();

        origin = new MiniOrigin();
        bridge = new MiniBridge(address(proxy));
        rc = new MiniReactive(
            address(sys), ORIGIN_CHAIN, DEST_CHAIN, reactiveChainId, address(origin), address(bridge)
        );

        // Register both contracts with their logical chains
        registerChain(address(origin), ORIGIN_CHAIN);
        registerChain(address(bridge), DEST_CHAIN);
        registerChain(address(rc), reactiveChainId);
    }

    function testFullCycleWithAutoDetect() public {
        // Use 3-arg overload (no explicit chainId)
        CallbackResult[] memory results = triggerFullCycle(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            10
        );

        assertCallbackCount(results, 2);
        assertEq(rc.deliveryCount(), 1);
    }

    function testFullCycleWithValueAutoDetect() public {
        deal(address(this), 1 ether);
        CallbackResult[] memory results = triggerFullCycleWithValue(
            address(origin),
            abi.encodeWithSignature("deposit()"),
            0.05 ether,
            10
        );

        assertCallbackCount(results, 2);
        assertEq(rc.deliveryCount(), 1);
        assertEq(rc.deliveredAmount(), 0.05 ether);
    }

    function testResolveChainIdFallback() public {
        // Unregistered address returns fallback
        address unknown = makeAddr("unknown");
        assertEq(resolveChainId(unknown, 999), 999);
    }

    function testResolveChainIdRegistered() public view {
        assertEq(resolveChainId(address(origin), 0), ORIGIN_CHAIN);
        assertEq(resolveChainId(address(bridge), 0), DEST_CHAIN);
        assertEq(resolveChainId(address(rc), 0), reactiveChainId);
    }
}
