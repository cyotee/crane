// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {CallbackResult, CronType} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";
import {SampleCronContract} from "./mocks/SampleCronContract.sol";
import {SampleCallback} from "./mocks/SampleCallback.sol";

contract CronDemoTest is ReactiveTest {
    SampleCronContract rc;
    SampleCallback cb;

    uint256 constant DEST_CHAIN = 11155111;

    function setUp() public override {
        super.setUp();

        cb = new SampleCallback(address(proxy));

        rc = new SampleCronContract(
            address(sys),
            ReactiveConstants.CRON_TOPIC_1,
            DEST_CHAIN,
            address(cb)
        );
    }

    function testCronTriggersCallback() public {
        CallbackResult[] memory results = triggerCron(CronType.Cron1);

        assertCallbackCount(results, 1);
        assertCallbackSuccess(results, 0);
        assertEq(rc.lastCronBlock(), block.number);
    }

    function testCronPauseResume() public {
        rc.pause();
        CallbackResult[] memory results = triggerCron(CronType.Cron1);
        assertNoCallbacks(results);

        rc.resume();
        results = triggerCron(CronType.Cron1);
        assertCallbackCount(results, 1);
    }

    function testAdvanceAndTriggerCron() public {
        uint256 startBlock = block.number;
        CallbackResult[] memory results = advanceAndTriggerCron(10, CronType.Cron1);

        assertCallbackCount(results, 1);
        assertEq(block.number, startBlock + 10);
        assertEq(rc.lastCronBlock(), startBlock + 10);
    }
}
