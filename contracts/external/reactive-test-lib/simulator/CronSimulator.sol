// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {LogRecord, CallbackResult, CronType} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {MockSystemContract} from "@crane/contracts/external/reactive-test-lib/mock/MockSystemContract.sol";
import {MockCallbackProxy} from "@crane/contracts/external/reactive-test-lib/mock/MockCallbackProxy.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {ReactiveSimulator} from "@crane/contracts/external/reactive-test-lib/simulator/ReactiveSimulator.sol";

/// @title CronSimulator
/// @notice Simulates cron-based event triggers for time-based reactive contracts.
library CronSimulator {
    /// @notice Emit a synthetic cron event and deliver it to all matching subscribers.
    function triggerCron(
        Vm _vm,
        CronType cronType,
        MockSystemContract sys,
        MockCallbackProxy proxy,
        address rvmId,
        uint256 reactiveChainId
    ) internal returns (CallbackResult[] memory results) {
        uint256 cronTopic = _getCronTopic(cronType);

        LogRecord memory log = LogRecord({
            chain_id: reactiveChainId,
            _contract: address(ReactiveConstants.SERVICE_ADDR),
            topic_0: cronTopic,
            topic_1: 0,
            topic_2: 0,
            topic_3: 0,
            data: abi.encode(block.number),
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });

        return ReactiveSimulator.deliverEvent(_vm, log, sys, proxy, rvmId, reactiveChainId);
    }

    /// @notice Advance block number, then trigger a cron event.
    function advanceAndTriggerCron(
        Vm _vm,
        uint256 blocks,
        CronType cronType,
        MockSystemContract sys,
        MockCallbackProxy proxy,
        address rvmId,
        uint256 reactiveChainId
    ) internal returns (CallbackResult[] memory results) {
        _vm.roll(block.number + blocks);
        _vm.warp(block.timestamp + blocks * 12); // ~12s per block
        return triggerCron(_vm, cronType, sys, proxy, rvmId, reactiveChainId);
    }

    /// @notice Maps CronType enum to the corresponding topic constant.
    function _getCronTopic(CronType cronType) internal pure returns (uint256) {
        if (cronType == CronType.Cron1) return ReactiveConstants.CRON_TOPIC_1;
        if (cronType == CronType.Cron10) return ReactiveConstants.CRON_TOPIC_10;
        if (cronType == CronType.Cron100) return ReactiveConstants.CRON_TOPIC_100;
        if (cronType == CronType.Cron1000) return ReactiveConstants.CRON_TOPIC_1000;
        if (cronType == CronType.Cron10000) return ReactiveConstants.CRON_TOPIC_10000;
        revert("CronSimulator: invalid cron type");
    }
}
