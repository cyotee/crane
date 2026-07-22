// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

import { IPayable } from "@crane/contracts/external/reactive-omni/interfaces/IPayable.sol";
import { ISubscriptionService } from "@crane/contracts/external/reactive-omni/interfaces/ISubscriptionService.sol";

/**
 * @title Interface for the Reactive Network's system contract.
 */
interface ISystemContract is IPayable, ISubscriptionService {
    /// @title List of supported callback configuration versions.
    enum CallbackVersion { V_1_0 }

    /// @title Callback configuration struct for legacy-style callbacks.
    struct CallbackConfiguration_V_1_0 { // forge-lint: disable-line(pascal-case-struct)
        uint256 chainId;
        address recipient;
        uint64 gasLimit;
        bytes payload;
    }

    /// @notice Requests the posting of a callback to some destination network.
    /// @param version_ Version of the callback configuration used.
    /// @param config_  ABI-encoded callback configration in a format corresponding to the version specified.
    function requestCallback(CallbackVersion version_, bytes memory config_) external;

    /// @notice Requests the posting of a legacy style callback to some destination network.
    /// @param config_  Callback configration in V_1_0 format.
    function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external; // forge-lint: disable-line(mixed-case-function)
}
