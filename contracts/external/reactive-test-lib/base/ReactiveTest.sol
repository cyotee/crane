// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockSystemContract} from "@crane/contracts/external/reactive-test-lib/mock/MockSystemContract.sol";
import {MockCallbackProxy} from "@crane/contracts/external/reactive-test-lib/mock/MockCallbackProxy.sol";
import {ReactiveSimulator} from "@crane/contracts/external/reactive-test-lib/simulator/ReactiveSimulator.sol";
import {CronSimulator} from "@crane/contracts/external/reactive-test-lib/simulator/CronSimulator.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {CallbackResult, CronType} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";

/// @title ReactiveTest
/// @notice Base test contract for testing Reactive Network contracts locally.
///         Extends forge-std/Test.sol and wires up the mock environment automatically.
///
/// @dev Usage:
///   1. Inherit from ReactiveTest
///   2. Call super.setUp() in your setUp()
///   3. Deploy your reactive/callback contracts — they will interact with MockSystemContract
///   4. Use triggerAndReact() / triggerCron() to simulate the reactive lifecycle
///   5. Optionally register contracts with registerChain() for auto chain ID detection
abstract contract ReactiveTest is Test {
    MockSystemContract internal sys;
    MockCallbackProxy internal proxy;
    address internal rvmId;

    /// @notice The reactive chain ID used to distinguish same-chain callbacks from cross-chain ones.
    ///         Callbacks targeting this chain ID are delivered via vm.prank(SERVICE_ADDR) instead of
    ///         through the proxy. Defaults to REACTIVE_CHAIN_ID (0x512512).
    ///         Override in setUp() if your reactive contract uses a different value.
    uint256 internal reactiveChainId;

    /// @notice Maps contract addresses to their logical chain IDs.
    ///         Used by auto-detect overloads to determine the chain ID of event emitters.
    mapping(address => uint256) internal chainRegistry;

    /// @notice Tracks whether an address has been registered (needed because chain ID 0 is valid as wildcard).
    mapping(address => bool) internal chainRegistrySet;

    function setUp() public virtual {
        // 1. Deploy MockSystemContract to a regular address
        MockSystemContract sysImpl = new MockSystemContract();

        // 2. Etch its runtime code to SERVICE_ADDR so AbstractReactive constructors detect code
        //    and subscribe() calls route to our mock
        address serviceAddr = address(ReactiveConstants.SERVICE_ADDR);
        vm.etch(serviceAddr, address(sysImpl).code);
        sys = MockSystemContract(payable(serviceAddr));

        // 3. Deploy MockCallbackProxy
        proxy = new MockCallbackProxy();

        // 4. Set rvmId to the test contract address (simulates the deployer)
        rvmId = address(this);

        // 5. Default reactive chain ID
        reactiveChainId = ReactiveConstants.REACTIVE_CHAIN_ID;
    }

    // ---- Chain registry ----

    /// @notice Register a contract as belonging to a specific logical chain.
    ///         Used by auto-detect methods to resolve chain IDs from event emitters.
    /// @param contractAddr The contract address.
    /// @param chainId The logical chain ID events from this contract belong to.
    function registerChain(address contractAddr, uint256 chainId) internal {
        chainRegistry[contractAddr] = chainId;
        chainRegistrySet[contractAddr] = true;
    }

    /// @notice Look up the chain ID for a contract. Returns the registered chain ID,
    ///         or the fallback if the contract is not registered.
    function resolveChainId(address contractAddr, uint256 fallback_) internal view returns (uint256) {
        if (chainRegistrySet[contractAddr]) {
            return chainRegistry[contractAddr];
        }
        return fallback_;
    }

    // ---- Convenience: Enable VM mode on a reactive contract ----

    /// @notice Enables VM mode on a reactive contract so vmOnly modifiers pass.
    /// @dev After etching SERVICE_ADDR, detectVm() sets vm=false (code exists).
    ///      This flips the `vm` storage slot (slot 2 in AbstractReactive) to true.
    ///      Call this after deploying each reactive contract.
    function enableVmMode(address rc) internal {
        vm.store(rc, ReactiveConstants.VM_STORAGE_SLOT, bytes32(uint256(1)));
    }

    // ---- Convenience: Single-step trigger with explicit chain ID ----

    /// @notice Trigger an event on an origin contract and run a single reactive cycle.
    function triggerAndReact(
        address origin,
        bytes memory callData,
        uint256 originChainId
    ) internal returns (CallbackResult[] memory results) {
        return ReactiveSimulator.simulateReaction(
            vm, origin, callData, 0, originChainId, sys, proxy, rvmId, reactiveChainId
        );
    }

    /// @notice Trigger an event with ETH value and run a single reactive cycle.
    function triggerAndReactWithValue(
        address origin,
        bytes memory callData,
        uint256 value,
        uint256 originChainId
    ) internal returns (CallbackResult[] memory results) {
        return ReactiveSimulator.simulateReaction(
            vm, origin, callData, value, originChainId, sys, proxy, rvmId, reactiveChainId
        );
    }

    // ---- Convenience: Single-step trigger with auto chain ID detection ----

    /// @notice Trigger an event using the chain registry to resolve the origin's chain ID.
    ///         The origin contract must be registered via registerChain().
    function triggerAndReact(
        address origin,
        bytes memory callData
    ) internal returns (CallbackResult[] memory results) {
        require(chainRegistrySet[origin], "ReactiveTest: origin not registered in chain registry");
        return triggerAndReact(origin, callData, chainRegistry[origin]);
    }

    /// @notice Trigger an event with ETH value, using the chain registry for chain ID.
    function triggerAndReactWithValue(
        address origin,
        bytes memory callData,
        uint256 value
    ) internal returns (CallbackResult[] memory results) {
        require(chainRegistrySet[origin], "ReactiveTest: origin not registered in chain registry");
        return triggerAndReactWithValue(origin, callData, value, chainRegistry[origin]);
    }

    // ---- Convenience: Full-cycle with explicit chain ID ----

    /// @notice Trigger an event and run the full multi-step reactive cycle until quiescence.
    function triggerFullCycle(
        address origin,
        bytes memory callData,
        uint256 originChainId,
        uint256 maxIterations
    ) internal returns (CallbackResult[] memory results) {
        return ReactiveSimulator.simulateFullCycle(
            vm, origin, callData, 0, originChainId, sys, proxy, rvmId, reactiveChainId, maxIterations
        );
    }

    /// @notice Full-cycle with ETH value.
    function triggerFullCycleWithValue(
        address origin,
        bytes memory callData,
        uint256 value,
        uint256 originChainId,
        uint256 maxIterations
    ) internal returns (CallbackResult[] memory results) {
        return ReactiveSimulator.simulateFullCycle(
            vm, origin, callData, value, originChainId, sys, proxy, rvmId, reactiveChainId, maxIterations
        );
    }

    // ---- Convenience: Full-cycle with auto chain ID detection ----

    /// @notice Full-cycle using the chain registry for the origin's chain ID.
    function triggerFullCycle(
        address origin,
        bytes memory callData,
        uint256 maxIterations
    ) internal returns (CallbackResult[] memory results) {
        require(chainRegistrySet[origin], "ReactiveTest: origin not registered in chain registry");
        return triggerFullCycle(origin, callData, chainRegistry[origin], maxIterations);
    }

    /// @notice Full-cycle with ETH value, using the chain registry for chain ID.
    function triggerFullCycleWithValue(
        address origin,
        bytes memory callData,
        uint256 value,
        uint256 maxIterations
    ) internal returns (CallbackResult[] memory results) {
        require(chainRegistrySet[origin], "ReactiveTest: origin not registered in chain registry");
        return triggerFullCycleWithValue(origin, callData, value, chainRegistry[origin], maxIterations);
    }

    // ---- Convenience: Cron ----

    /// @notice Trigger a cron event and deliver to matching subscribers.
    function triggerCron(CronType cronType) internal returns (CallbackResult[] memory) {
        return CronSimulator.triggerCron(vm, cronType, sys, proxy, rvmId, reactiveChainId);
    }

    /// @notice Advance blocks and trigger a cron event.
    function advanceAndTriggerCron(uint256 blocks, CronType cronType)
        internal
        returns (CallbackResult[] memory)
    {
        return CronSimulator.advanceAndTriggerCron(vm, blocks, cronType, sys, proxy, rvmId, reactiveChainId);
    }

    // ---- Assertion helpers ----

    /// @notice Assert that a callback was emitted targeting a specific address.
    function assertCallbackEmitted(CallbackResult[] memory results, address expectedTarget) internal pure {
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].target == expectedTarget) return;
        }
        revert("ReactiveTest: no callback emitted to expected target");
    }

    /// @notice Assert the exact number of callbacks produced.
    function assertCallbackCount(CallbackResult[] memory results, uint256 expected) internal pure {
        require(
            results.length == expected,
            string.concat(
                "ReactiveTest: expected ",
                vm.toString(expected),
                " callbacks, got ",
                vm.toString(results.length)
            )
        );
    }

    /// @notice Assert no callbacks were produced.
    function assertNoCallbacks(CallbackResult[] memory results) internal pure {
        require(results.length == 0, "ReactiveTest: expected no callbacks");
    }

    /// @notice Assert that a specific callback succeeded.
    function assertCallbackSuccess(CallbackResult[] memory results, uint256 index) internal pure {
        require(index < results.length, "ReactiveTest: callback index out of bounds");
        require(results[index].success, "ReactiveTest: callback did not succeed");
    }

    /// @notice Assert that a specific callback failed.
    function assertCallbackFailure(CallbackResult[] memory results, uint256 index) internal pure {
        require(index < results.length, "ReactiveTest: callback index out of bounds");
        require(!results[index].success, "ReactiveTest: callback did not fail");
    }
}
