// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {LogRecord, CallbackResult, IReactive} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {MockSystemContract} from "@crane/contracts/external/reactive-test-lib/mock/MockSystemContract.sol";
import {MockCallbackProxy} from "@crane/contracts/external/reactive-test-lib/mock/MockCallbackProxy.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";

/// @notice Bundled parameters for simulation to avoid stack-too-deep.
struct SimulationParams {
    Vm _vm;
    MockSystemContract sys;
    MockCallbackProxy proxy;
    address rvmId;
    uint256 reactiveChainId;
}

/// @notice A pending event awaiting subscription matching, tagged with its origin chain ID.
struct PendingEvent {
    uint256 chainId;
    address emitter;
    uint256 t0;
    uint256 t1;
    uint256 t2;
    uint256 t3;
    bytes data;
}

/// @notice Parsed Callback event (not yet executed).
struct CallbackSpec {
    uint256 chainId;
    address target;
    uint64 gasLimit;
    bytes payload;
}

/// @title ReactiveSimulator
/// @notice Orchestrates the full reactive lifecycle (event -> react() -> callback) in a Foundry test.
library ReactiveSimulator {
    uint256 internal constant DEFAULT_MAX_ITERATIONS = 20;

    // ---- Single-step simulation (original API) ----

    /// @notice Simulate a single event -> react() -> callback cycle.
    function simulateReaction(
        Vm _vm,
        address origin,
        bytes memory callData,
        uint256 value,
        uint256 originChainId,
        MockSystemContract sys,
        MockCallbackProxy proxy,
        address rvmId,
        uint256 reactiveChainId
    ) internal returns (CallbackResult[] memory) {
        SimulationParams memory p = SimulationParams(_vm, sys, proxy, rvmId, reactiveChainId);

        _vm.recordLogs();
        (bool ok,) = origin.call{value: value}(callData);
        require(ok, "ReactiveSimulator: origin call failed");
        Vm.Log[] memory logs = _vm.getRecordedLogs();

        PendingEvent[] memory pending = _vmLogsToPending(logs, originChainId);
        // Single-step: process events, execute callbacks, don't capture further events
        return _processAndExecute(p, pending);
    }

    // ---- Full-cycle simulation (multi-step) ----

    /// @notice Simulate the full multi-step reactive cycle until quiescence.
    ///         Keeps processing: events -> react() -> callbacks -> new events -> ...
    ///         Stops when no callbacks are produced or maxIterations is reached.
    function simulateFullCycle(
        Vm _vm,
        address origin,
        bytes memory callData,
        uint256 value,
        uint256 originChainId,
        MockSystemContract sys,
        MockCallbackProxy proxy,
        address rvmId,
        uint256 reactiveChainId,
        uint256 maxIterations
    ) internal returns (CallbackResult[] memory) {
        SimulationParams memory p = SimulationParams(_vm, sys, proxy, rvmId, reactiveChainId);

        // Execute initial call and capture events
        _vm.recordLogs();
        (bool ok,) = origin.call{value: value}(callData);
        require(ok, "ReactiveSimulator: origin call failed");
        Vm.Log[] memory logs = _vm.getRecordedLogs();

        PendingEvent[] memory pending = _vmLogsToPending(logs, originChainId);

        CallbackResult[] memory allResults = new CallbackResult[](0);

        for (uint256 iter = 0; iter < maxIterations; iter++) {
            if (pending.length == 0) break;

            // 1. Match pending events → call react() → collect CallbackSpecs (not yet executed)
            CallbackSpec[] memory specs = _matchAndReact(p, pending);

            if (specs.length == 0) break;

            // 2. Execute each callback, capturing events emitted by the target
            CallbackResult[] memory batchResults = new CallbackResult[](specs.length);
            PendingEvent[] memory tempPending = new PendingEvent[](specs.length * 8);
            uint256 pendingCount = 0;

            for (uint256 i = 0; i < specs.length; i++) {
                (CallbackResult memory result, PendingEvent[] memory newEvents) =
                    _executeCallbackWithCapture(p, specs[i]);
                batchResults[i] = result;
                for (uint256 j = 0; j < newEvents.length; j++) {
                    tempPending[pendingCount++] = newEvents[j];
                }
            }

            allResults = _concatResults(allResults, batchResults);
            pending = _trimPending(tempPending, pendingCount);
        }

        return allResults;
    }

    // ---- Event delivery (for cron and manual use) ----

    /// @notice Deliver a specific LogRecord to all matching subscribers and execute callbacks.
    function deliverEvent(
        Vm _vm,
        LogRecord memory log,
        MockSystemContract sys,
        MockCallbackProxy proxy,
        address rvmId,
        uint256 reactiveChainId
    ) internal returns (CallbackResult[] memory) {
        SimulationParams memory p = SimulationParams(_vm, sys, proxy, rvmId, reactiveChainId);

        PendingEvent[] memory pending = new PendingEvent[](1);
        pending[0] = PendingEvent({
            chainId: log.chain_id,
            emitter: log._contract,
            t0: log.topic_0,
            t1: log.topic_1,
            t2: log.topic_2,
            t3: log.topic_3,
            data: log.data
        });

        return _processAndExecute(p, pending);
    }

    /// @notice Manually deliver a LogRecord to a specific reactive contract (no callback processing).
    function deliverRawEvent(
        Vm _vm,
        IReactive target,
        LogRecord memory log
    ) internal {
        _vm.prank(address(ReactiveConstants.SERVICE_ADDR));
        target.react(log);
    }

    // ---- Internal: single-step processing (match → react → execute callbacks) ----

    /// @dev Process pending events: match → react() → execute callbacks. No event capture from callbacks.
    function _processAndExecute(
        SimulationParams memory p,
        PendingEvent[] memory pending
    ) private returns (CallbackResult[] memory) {
        // Collect callback specs from react() calls
        CallbackSpec[] memory specs = _matchAndReact(p, pending);

        // Execute all callbacks
        CallbackResult[] memory results = new CallbackResult[](specs.length);
        for (uint256 i = 0; i < specs.length; i++) {
            results[i] = _executeCallback(p, specs[i]);
        }
        return results;
    }

    // ---- Internal: match events → react() → collect CallbackSpecs ----

    /// @dev For each pending event, find matching subscribers, call react(), collect Callback events.
    function _matchAndReact(
        SimulationParams memory p,
        PendingEvent[] memory pending
    ) private returns (CallbackSpec[] memory) {
        CallbackSpec[] memory tempSpecs = new CallbackSpec[](pending.length * 8);
        uint256 specCount = 0;

        for (uint256 i = 0; i < pending.length; i++) {
            address[] memory subscribers = p.sys.getMatchingSubscribers(
                pending[i].chainId, pending[i].emitter,
                pending[i].t0, pending[i].t1, pending[i].t2, pending[i].t3
            );

            if (subscribers.length == 0) continue;

            LogRecord memory log = _pendingToLogRecord(pending[i]);

            for (uint256 j = 0; j < subscribers.length; j++) {
                CallbackSpec[] memory specs = _reactAndExtractSpecs(p, subscribers[j], log);
                for (uint256 k = 0; k < specs.length; k++) {
                    tempSpecs[specCount++] = specs[k];
                }
            }
        }

        return _trimSpecs(tempSpecs, specCount);
    }

    /// @dev Call react() on a subscriber and parse emitted Callback events into CallbackSpecs.
    function _reactAndExtractSpecs(
        SimulationParams memory p,
        address subscriber,
        LogRecord memory log
    ) private returns (CallbackSpec[] memory) {
        p._vm.recordLogs();
        p._vm.prank(address(ReactiveConstants.SERVICE_ADDR));
        IReactive(subscriber).react(log);
        Vm.Log[] memory reactLogs = p._vm.getRecordedLogs();

        bytes32 cbTopic = ReactiveConstants.CALLBACK_EVENT_TOPIC;

        uint256 cbCount = 0;
        for (uint256 i = 0; i < reactLogs.length; i++) {
            if (reactLogs[i].topics.length >= 4 && reactLogs[i].topics[0] == cbTopic) {
                cbCount++;
            }
        }

        CallbackSpec[] memory specs = new CallbackSpec[](cbCount);
        uint256 idx = 0;

        for (uint256 i = 0; i < reactLogs.length; i++) {
            if (reactLogs[i].topics.length < 4 || reactLogs[i].topics[0] != cbTopic) continue;

            specs[idx++] = CallbackSpec({
                chainId: uint256(reactLogs[i].topics[1]),
                target: address(uint160(uint256(reactLogs[i].topics[2]))),
                gasLimit: uint64(uint256(reactLogs[i].topics[3])),
                payload: abi.decode(reactLogs[i].data, (bytes))
            });
        }

        return specs;
    }

    // ---- Internal: callback execution ----

    /// @dev Execute a callback (no event capture). Used by single-step mode.
    function _executeCallback(
        SimulationParams memory p,
        CallbackSpec memory spec
    ) private returns (CallbackResult memory) {
        bool success;
        bytes memory returnData;

        if (spec.chainId == p.reactiveChainId) {
            _injectRvmId(spec.payload, p.rvmId);
            p._vm.prank(address(ReactiveConstants.SERVICE_ADDR));
            (success, returnData) = spec.target.call{gas: spec.gasLimit}(spec.payload);
        } else {
            (success, returnData) = p.proxy.executeCallback(
                spec.target, spec.payload, spec.gasLimit, p.rvmId
            );
        }

        return CallbackResult({
            chainId: spec.chainId,
            target: spec.target,
            gasLimit: spec.gasLimit,
            payload: spec.payload,
            success: success,
            returnData: returnData
        });
    }

    /// @dev Execute a callback while recording events emitted by the target. Used by full-cycle mode.
    ///      Events emitted during execution are tagged with the callback's chain ID.
    function _executeCallbackWithCapture(
        SimulationParams memory p,
        CallbackSpec memory spec
    ) private returns (CallbackResult memory, PendingEvent[] memory) {
        bool success;
        bytes memory returnData;

        p._vm.recordLogs();

        if (spec.chainId == p.reactiveChainId) {
            _injectRvmId(spec.payload, p.rvmId);
            p._vm.prank(address(ReactiveConstants.SERVICE_ADDR));
            (success, returnData) = spec.target.call{gas: spec.gasLimit}(spec.payload);
        } else {
            (success, returnData) = p.proxy.executeCallback(
                spec.target, spec.payload, spec.gasLimit, p.rvmId
            );
        }

        Vm.Log[] memory logs = p._vm.getRecordedLogs();
        PendingEvent[] memory newEvents = _vmLogsToPending(logs, spec.chainId);

        return (
            CallbackResult({
                chainId: spec.chainId,
                target: spec.target,
                gasLimit: spec.gasLimit,
                payload: spec.payload,
                success: success,
                returnData: returnData
            }),
            newEvents
        );
    }

    // ---- Internal: helpers ----

    function _injectRvmId(bytes memory payload, address rvmId) private pure {
        if (payload.length >= 36) {
            assembly {
                let argStart := add(add(payload, 0x20), 4)
                mstore(argStart, rvmId)
            }
        }
    }

    function _vmLogsToPending(
        Vm.Log[] memory logs,
        uint256 chainId
    ) private pure returns (PendingEvent[] memory) {
        PendingEvent[] memory pending = new PendingEvent[](logs.length);
        for (uint256 i = 0; i < logs.length; i++) {
            pending[i] = PendingEvent({
                chainId: chainId,
                emitter: logs[i].emitter,
                t0: logs[i].topics.length > 0 ? uint256(logs[i].topics[0]) : 0,
                t1: logs[i].topics.length > 1 ? uint256(logs[i].topics[1]) : 0,
                t2: logs[i].topics.length > 2 ? uint256(logs[i].topics[2]) : 0,
                t3: logs[i].topics.length > 3 ? uint256(logs[i].topics[3]) : 0,
                data: logs[i].data
            });
        }
        return pending;
    }

    function _pendingToLogRecord(PendingEvent memory evt) private view returns (LogRecord memory) {
        return LogRecord({
            chain_id: evt.chainId,
            _contract: evt.emitter,
            topic_0: evt.t0,
            topic_1: evt.t1,
            topic_2: evt.t2,
            topic_3: evt.t3,
            data: evt.data,
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
    }

    function _trimResults(
        CallbackResult[] memory temp,
        uint256 count
    ) private pure returns (CallbackResult[] memory) {
        CallbackResult[] memory result = new CallbackResult[](count);
        for (uint256 i = 0; i < count; i++) result[i] = temp[i];
        return result;
    }

    function _trimSpecs(
        CallbackSpec[] memory temp,
        uint256 count
    ) private pure returns (CallbackSpec[] memory) {
        CallbackSpec[] memory result = new CallbackSpec[](count);
        for (uint256 i = 0; i < count; i++) result[i] = temp[i];
        return result;
    }

    function _trimPending(
        PendingEvent[] memory temp,
        uint256 count
    ) private pure returns (PendingEvent[] memory) {
        PendingEvent[] memory result = new PendingEvent[](count);
        for (uint256 i = 0; i < count; i++) result[i] = temp[i];
        return result;
    }

    function _concatResults(
        CallbackResult[] memory a,
        CallbackResult[] memory b
    ) private pure returns (CallbackResult[] memory) {
        CallbackResult[] memory result = new CallbackResult[](a.length + b.length);
        for (uint256 i = 0; i < a.length; i++) result[i] = a[i];
        for (uint256 i = 0; i < b.length; i++) result[a.length + i] = b[i];
        return result;
    }
}
