// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {NonReentrantGreeterStub} from "contracts/test/stubs/greeter/NonReentrantGreeterStub.sol";
import {IReentrancyLock} from "contracts/interfaces/IReentrancyLock.sol";

// Handler contract — all external calls go through this
contract ReentrancyHandler is Test {
    NonReentrantGreeterStub public greeter;

    constructor(NonReentrantGreeterStub _greeter) {
        greeter = _greeter;
    }

    // Controlled way to arm reentrancy attempt
    function enableReentrancyAttempt() external {
        greeter.enableReentrancy(); // sets shouldReenter = true inside the contract
    }

    // Useful for bounded sequences
    function disableReentrancyAttempt() external {
        greeter.disableReentrancy();
    }

    // Main external entry point — this is what Foundry will fuzz
    function setMessage(string calldata message) external {
        // If the flag is set, the contract will attempt reentrancy → must revert
        if (greeter.shouldReenter()) {
            vm.expectRevert(abi.encodeWithSelector(IReentrancyLock.IsLocked.selector));
        }

        greeter.setMessage(message);
    }

    // Additional harmless call to increase coverage and state space
    function getMessage() external view returns (string memory) {
        return greeter.getMessage();
    }
}

contract NonReentrantGreeterInvariantTest is StdInvariant, Test {
    NonReentrantGreeterStub public greeter;
    ReentrancyHandler public handler;

    function setUp() public {
        greeter = new NonReentrantGreeterStub("Hello Foundry!");
        handler = new ReentrancyHandler(greeter);

        // Tell Foundry to only call functions on the handler
        targetContract(address(handler));

        // Select which handler functions to call during fuzzing
        // We bound calldata to reduce noise — getMessage() is cheap and harmless
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.setMessage.selector;
        selectors[1] = handler.getMessage.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        // Optional: limit number of calls per run for faster feedback
        // excludeSender(address(0)); etc. if needed
    }

    // ──────────────────────────────────────────────────────────────
    // Invariant A: The contract is NEVER locked after any call sequence
    // ──────────────────────────────────────────────────────────────
    function invariant_NeverLocked() public view {
        assertFalse(greeter.isLocked(), "Reentrancy lock stuck - contract is still locked after external call!");
    }

    // ──────────────────────────────────────────────────────────────
    // Invariant B: When reentrancy is attempted, the recursive call MUST revert
    //             (We enforce this in the handler with expectRevert)
    // ──────────────────────────────────────────────────────────────
    // This is enforced at runtime in the handler — see above.
    // We also add a manual test to ensure the expectation is actually hit.

    // Helper: ensure the reentrancy path is reachable and correctly reverts
    function test_ReentrancyAttemptReverts() public {
        greeter.enableReentrancy();
        // Adjust to match your exact revert (same as in handler)
        vm.expectRevert(abi.encodeWithSelector(IReentrancyLock.IsLocked.selector));
        greeter.setMessage("this will try to reenter");
    }
}
