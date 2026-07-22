// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {MockSystemContract} from "@crane/contracts/external/reactive-test-lib/mock/MockSystemContract.sol";
import {MockCallbackProxy} from "@crane/contracts/external/reactive-test-lib/mock/MockCallbackProxy.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";

/// @title ReactiveFixtures
/// @notice Factory helpers and common setup patterns for reactive contract testing.
library ReactiveFixtures {
    /// @notice Deploy and wire MockSystemContract at SERVICE_ADDR.
    /// @param _vm Foundry VM instance.
    /// @return sys The MockSystemContract instance at SERVICE_ADDR.
    function deployMockSystem(Vm _vm) internal returns (MockSystemContract sys) {
        MockSystemContract impl = new MockSystemContract();
        address serviceAddr = address(ReactiveConstants.SERVICE_ADDR);
        _vm.etch(serviceAddr, address(impl).code);
        sys = MockSystemContract(payable(serviceAddr));
    }

    /// @notice Deploy MockCallbackProxy.
    /// @return proxy The MockCallbackProxy instance.
    function deployMockProxy() internal returns (MockCallbackProxy proxy) {
        proxy = new MockCallbackProxy();
    }

    /// @notice Enable VM mode on a reactive contract (sets the `vm` storage slot to true).
    /// @param _vm Foundry VM instance.
    /// @param rc Address of the reactive contract.
    function enableVmMode(Vm _vm, address rc) internal {
        _vm.store(rc, ReactiveConstants.VM_STORAGE_SLOT, bytes32(uint256(1)));
    }

    /// @notice Deploy the full mock environment in one call.
    /// @param _vm Foundry VM instance.
    /// @return sys The MockSystemContract at SERVICE_ADDR.
    /// @return proxy The MockCallbackProxy.
    function deployAll(Vm _vm)
        internal
        returns (MockSystemContract sys, MockCallbackProxy proxy)
    {
        sys = deployMockSystem(_vm);
        proxy = deployMockProxy();
    }
}
