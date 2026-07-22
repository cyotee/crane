// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {CallbackResult, CronType} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";

/// @title IReactiveTest
/// @notice Internal interface defining the test harness contract API.
interface IReactiveTest {
    function triggerAndReact(
        address origin,
        bytes memory callData,
        uint256 originChainId
    ) external returns (CallbackResult[] memory);

    function triggerCron(CronType cronType) external returns (CallbackResult[] memory);
}
