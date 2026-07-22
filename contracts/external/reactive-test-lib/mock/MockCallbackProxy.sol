// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {CallbackResult} from "@crane/contracts/external/reactive-test-lib/interfaces/IReactiveInterfaces.sol";

/// @title MockCallbackProxy
/// @notice Simulates the Reactive Network callback proxy for local Foundry testing.
///         Executes callback payloads on destination contracts, injecting the RVM ID
///         into the first argument of the payload (replicating real network behavior).
contract MockCallbackProxy {
    /// @notice Executes a callback on the target contract.
    /// @param target Destination contract address.
    /// @param payload ABI-encoded function call data.
    /// @param gasLimit Gas limit for the callback execution.
    /// @param rvmId Deployer address to inject as the first argument (RVM ID).
    /// @return success Whether the call succeeded.
    /// @return result Return data from the call.
    function executeCallback(
        address target,
        bytes memory payload,
        uint64 gasLimit,
        address rvmId
    ) external returns (bool success, bytes memory result) {
        // Overwrite first 160 bits of the first argument with rvmId.
        // In ABI encoding, function selector is 4 bytes, then the first argument
        // starts at byte 4. The address is right-aligned in a 32-byte word,
        // so it occupies bytes 16-35 (0-indexed from start of the argument word).
        // We overwrite bytes 4+12 through 4+31 (the last 20 bytes of the first 32-byte arg).
        if (payload.length >= 36) {
            assembly {
                // payload data starts at payload + 0x20 (skip length prefix)
                // first arg word starts at offset 4 (after selector)
                // address is in the low 20 bytes of the 32-byte word
                let argStart := add(add(payload, 0x20), 4)
                // Clear and set: store rvmId as a 256-bit value (left-padded with zeros)
                mstore(argStart, rvmId)
            }
        }

        (success, result) = target.call{gas: gasLimit}(payload);
    }

    /// @notice Allows receiving ETH (for IPayable compatibility).
    receive() external payable {}

    /// @notice No-op debt function for IPayable compatibility.
    function debt(address) external pure returns (uint256) {
        return 0;
    }
}
