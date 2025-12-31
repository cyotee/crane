// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {IReentrancyLock} from "contracts/crane/interfaces/IReentrancyLock.sol";
import {NonReentrantGreeterStub} from "contracts/crane/test/stubs/greeter/NonReentrantGreeterStub.sol";

contract ReentrancyLockModifiers_Test is Test_Crane {
    NonReentrantGreeterStub public greeter;

    string constant INITIAL_MESSAGE = "Hello, World!";
    string constant NEW_MESSAGE = "Hello, Reentrancy Test!";

    function setUp() public override {
        super.setUp();
        greeter = new NonReentrantGreeterStub(INITIAL_MESSAGE);
    }

    /* ========================================================================== */
    /*                              BASIC FUNCTIONALITY                          */
    /* ========================================================================== */

    function test_getMessage_WhenNotLocked_ShouldSucceed() public view {
        string memory message = greeter.getMessage();
        assertEq(message, INITIAL_MESSAGE, "Should return initial message");
    }

    function test_setMessage_WhenNotLocked_ShouldSucceed() public {
        bool success = greeter.setMessage(NEW_MESSAGE);
        assertTrue(success, "setMessage should succeed when not locked");

        string memory message = greeter.getMessage();
        assertEq(message, NEW_MESSAGE, "Message should be updated");
    }

    function test_isLocked_InitialState_ShouldBeFalse() public view {
        bool locked = IReentrancyLock(address(greeter)).isLocked();
        assertFalse(locked, "Contract should not be locked initially");
    }

    /* ========================================================================== */
    /*                            REENTRANCY PROTECTION                          */
    /* ========================================================================== */

    function test_lock_PreventsReentrancy() public {
        // Enable reentrancy attempt in the stub
        greeter.enableReentrancy();

        // This should revert when setMessage attempts to call itself
        vm.expectRevert(IReentrancyLock.IsLocked.selector);
        greeter.setMessage("trigger reentrancy");

        // Verify the message wasn't changed due to the revert
        string memory message = greeter.getMessage();
        assertEq(message, INITIAL_MESSAGE, "Message should not change due to reentrancy revert");
    }

    function test_lock_AfterExecution_ShouldBeUnlocked() public {
        greeter.setMessage(NEW_MESSAGE);

        bool locked = IReentrancyLock(address(greeter)).isLocked();
        assertFalse(locked, "Contract should be unlocked after execution");
    }

    function test_lock_MultipleSequentialCalls_ShouldSucceed() public {
        string memory message1 = greeter.getMessage();
        bool success = greeter.setMessage(NEW_MESSAGE);
        string memory message2 = greeter.getMessage();

        assertEq(message1, INITIAL_MESSAGE, "First call should succeed");
        assertTrue(success, "setMessage should succeed");
        assertEq(message2, NEW_MESSAGE, "Second call should return updated message");
    }
}
