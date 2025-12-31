// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";

import {OperableTargetStub} from "contracts/crane/test/stubs/OperableTargetStub.sol";
import {OperableGreeterStub} from "contracts/crane/test/stubs/OperableGreeterStub.sol";
import {IOperable} from "contracts/crane/interfaces/IOperable.sol";
import {IGreeter} from "contracts/crane/test/stubs/greeter/IGreeter.sol";

contract OperableTargetTest is Test_Crane {
    address owner_ = vm.addr(uint256(keccak256(abi.encode("owner"))));
    address globalOperator = vm.addr(uint256(keccak256(abi.encode("globalOperator"))));
    address functionOperator = vm.addr(uint256(keccak256(abi.encode("functionOperator"))));
    address unauthorizedUser = vm.addr(uint256(keccak256(abi.encode("unauthorizedUser"))));

    OperableTargetStub operableStub;
    OperableGreeterStub greeterStub;

    bytes4 setMessageSelector = bytes4(keccak256("setMessage(string)"));
    bytes4 updateMessageSelector = bytes4(keccak256("updateMessage(string)"));

    function setUp() public virtual override {
        declare("owner_", address(owner_));
        declare("globalOperator", address(globalOperator));
        declare("functionOperator", address(functionOperator));
        declare("unauthorizedUser", address(unauthorizedUser));

        operableStub = new OperableTargetStub(owner_);
        greeterStub = new OperableGreeterStub("Hello World", owner_);

        declare("operableStub", address(operableStub));
        declare("greeterStub", address(greeterStub));
    }

    /* ---------------------------------------------------------------------- */
    /*                           IOperable.isOperator                         */
    /* ---------------------------------------------------------------------- */

    function test_IOperable_isOperator_false_default() public view {
        assertFalse(operableStub.isOperator(globalOperator));
    }

    function test_IOperable_isOperator_true_after_set() public {
        vm.startPrank(owner_);
        operableStub.setOperator(globalOperator, true);
        assertTrue(operableStub.isOperator(globalOperator));
    }

    function test_IOperable_isOperator_false_after_revoke() public {
        vm.startPrank(owner_);
        operableStub.setOperator(globalOperator, true);
        operableStub.setOperator(globalOperator, false);
        assertFalse(operableStub.isOperator(globalOperator));
    }

    /* ---------------------------------------------------------------------- */
    /*                        IOperable.isOperatorFor                         */
    /* ---------------------------------------------------------------------- */

    function test_IOperable_isOperatorFor_false_default() public view {
        assertFalse(operableStub.isOperatorFor(setMessageSelector, functionOperator));
    }

    function test_IOperable_isOperatorFor_true_after_set() public {
        vm.startPrank(owner_);
        operableStub.setOperatorFor(setMessageSelector, functionOperator, true);
        assertTrue(operableStub.isOperatorFor(setMessageSelector, functionOperator));
    }

    function test_IOperable_isOperatorFor_true_global_operator() public {
        vm.startPrank(owner_);
        operableStub.setOperator(globalOperator, true);
        assertTrue(operableStub.isOperatorFor(setMessageSelector, globalOperator));
    }

    function test_IOperable_isOperatorFor_false_different_function() public {
        vm.startPrank(owner_);
        operableStub.setOperatorFor(setMessageSelector, functionOperator, true);
        assertFalse(operableStub.isOperatorFor(updateMessageSelector, functionOperator));
    }

    /* ---------------------------------------------------------------------- */
    /*                         IOperable.setOperator                          */
    /* ---------------------------------------------------------------------- */

    function test_IOperable_setOperator_success() public {
        vm.startPrank(owner_);
        vm.expectEmit(true, false, false, false, address(operableStub));
        emit IOperable.NewGlobalOperator(globalOperator);

        assertTrue(operableStub.setOperator(globalOperator, true));
        assertTrue(operableStub.isOperator(globalOperator));
    }

    function test_IOperable_setOperator_revoke() public {
        vm.startPrank(owner_);
        operableStub.setOperator(globalOperator, true);
        assertTrue(operableStub.setOperator(globalOperator, false));
        assertFalse(operableStub.isOperator(globalOperator));
    }

    function test_IOperable_setOperator_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert();
        operableStub.setOperator(globalOperator, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                       IOperable.setOperatorFor                         */
    /* ---------------------------------------------------------------------- */

    function test_IOperable_setOperatorFor_success() public {
        vm.startPrank(owner_);
        vm.expectEmit(true, true, false, false, address(operableStub));
        emit IOperable.NewFunctionOperator(functionOperator, setMessageSelector);

        assertTrue(operableStub.setOperatorFor(setMessageSelector, functionOperator, true));
        assertTrue(operableStub.isOperatorFor(setMessageSelector, functionOperator));
    }

    function test_IOperable_setOperatorFor_revoke() public {
        vm.startPrank(owner_);
        operableStub.setOperatorFor(setMessageSelector, functionOperator, true);
        assertTrue(operableStub.setOperatorFor(setMessageSelector, functionOperator, false));
        assertFalse(operableStub.isOperatorFor(setMessageSelector, functionOperator));
    }

    function test_IOperable_setOperatorFor_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert();
        operableStub.setOperatorFor(setMessageSelector, functionOperator, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                    Protected Function: setMessage                      */
    /* ---------------------------------------------------------------------- */

    function test_setMessage_owner_access() public {
        vm.startPrank(owner_);
        vm.expectEmit(true, true, false, false, address(greeterStub));
        emit IGreeter.NewMessage("Hello World", "Updated by Owner");

        assertTrue(greeterStub.setMessage("Updated by Owner"));
        assertEq(greeterStub.getMessage(), "Updated by Owner");
    }

    function test_setMessage_global_operator_access() public {
        // Set global operator
        vm.startPrank(owner_);
        greeterStub.setOperator(globalOperator, true);

        // Test global operator can call setMessage
        vm.startPrank(globalOperator);
        vm.expectEmit(true, true, false, false, address(greeterStub));
        emit IGreeter.NewMessage("Hello World", "Updated by Global Operator");

        assertTrue(greeterStub.setMessage("Updated by Global Operator"));
        assertEq(greeterStub.getMessage(), "Updated by Global Operator");
    }

    function test_setMessage_function_operator_access() public {
        // Set function-specific operator for setMessage
        vm.startPrank(owner_);
        greeterStub.setOperatorFor(setMessageSelector, functionOperator, true);

        // Test function operator can call setMessage
        vm.startPrank(functionOperator);
        vm.expectEmit(true, true, false, false, address(greeterStub));
        emit IGreeter.NewMessage("Hello World", "Updated by Function Operator");

        assertTrue(greeterStub.setMessage("Updated by Function Operator"));
        assertEq(greeterStub.getMessage(), "Updated by Function Operator");
    }

    function test_setMessage_unauthorized_access() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, unauthorizedUser));
        greeterStub.setMessage("Should Fail");
    }

    function test_setMessage_revoked_access() public {
        // Grant and then revoke function operator access
        vm.startPrank(owner_);
        greeterStub.setOperatorFor(setMessageSelector, functionOperator, true);
        greeterStub.setOperatorFor(setMessageSelector, functionOperator, false);

        // Test revoked operator cannot call setMessage
        vm.startPrank(functionOperator);
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, functionOperator));
        greeterStub.setMessage("Should Fail");
    }

    /* ---------------------------------------------------------------------- */
    /*                   Protected Function: updateMessage                    */
    /* ---------------------------------------------------------------------- */

    function test_updateMessage_global_operator_access() public {
        // Set global operator
        vm.startPrank(owner_);
        greeterStub.setOperator(globalOperator, true);

        // Test global operator can call updateMessage
        vm.startPrank(globalOperator);
        assertTrue(greeterStub.updateMessage("Updated via updateMessage"));
        assertEq(greeterStub.getMessage(), "Updated via updateMessage");
    }

    function test_updateMessage_function_operator_access() public {
        // Set function-specific operator for updateMessage
        vm.startPrank(owner_);
        greeterStub.setOperatorFor(updateMessageSelector, functionOperator, true);

        // Test function operator can call updateMessage
        vm.startPrank(functionOperator);
        assertTrue(greeterStub.updateMessage("Function Operator Update"));
        assertEq(greeterStub.getMessage(), "Function Operator Update");
    }

    function test_updateMessage_owner_denied() public {
        // Owner should NOT be able to call updateMessage (onlyOperator modifier)
        vm.startPrank(owner_);
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, owner_));
        greeterStub.updateMessage("Should Fail");
    }

    function test_updateMessage_unauthorized_access() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, unauthorizedUser));
        greeterStub.updateMessage("Should Fail");
    }

    /* ---------------------------------------------------------------------- */
    /*                        Cross-Function Authorization                     */
    /* ---------------------------------------------------------------------- */

    function test_function_specific_authorization_isolation() public {
        // Set operator for setMessage only
        vm.startPrank(owner_);
        greeterStub.setOperatorFor(setMessageSelector, functionOperator, true);

        // Verify operator can call setMessage
        vm.startPrank(functionOperator);
        assertTrue(greeterStub.setMessage("Can access setMessage"));

        // Verify operator cannot call updateMessage
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, functionOperator));
        greeterStub.updateMessage("Should Fail");
    }

    function test_multiple_function_operators() public {
        address setMessageOperator = vm.addr(uint256(keccak256(abi.encode("setMessageOperator"))));
        address updateMessageOperator = vm.addr(uint256(keccak256(abi.encode("updateMessageOperator"))));

        declare("setMessageOperator", address(setMessageOperator));
        declare("updateMessageOperator", address(updateMessageOperator));

        // Set different operators for different functions
        vm.startPrank(owner_);
        greeterStub.setOperatorFor(setMessageSelector, setMessageOperator, true);
        greeterStub.setOperatorFor(updateMessageSelector, updateMessageOperator, true);

        // Test setMessage operator can only call setMessage
        vm.startPrank(setMessageOperator);
        assertTrue(greeterStub.setMessage("SetMessage Operator"));

        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, setMessageOperator));
        greeterStub.updateMessage("Should Fail");

        // Test updateMessage operator can only call updateMessage
        vm.startPrank(updateMessageOperator);
        assertTrue(greeterStub.updateMessage("UpdateMessage Operator"));
    }

    /* ---------------------------------------------------------------------- */
    /*                           Authorization Precedence                      */
    /* ---------------------------------------------------------------------- */

    function test_global_operator_precedence() public {
        // Set both global and function-specific operators
        vm.startPrank(owner_);
        greeterStub.setOperator(globalOperator, true);
        greeterStub.setOperatorFor(setMessageSelector, functionOperator, true);

        // Both should be able to call setMessage
        vm.startPrank(globalOperator);
        assertTrue(greeterStub.setMessage("Global Operator"));

        vm.startPrank(functionOperator);
        assertTrue(greeterStub.setMessage("Function Operator"));

        // Only global operator should be able to call updateMessage
        vm.startPrank(globalOperator);
        assertTrue(greeterStub.updateMessage("Global Operator Update"));

        vm.startPrank(functionOperator);
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, functionOperator));
        greeterStub.updateMessage("Should Fail");
    }

    /* ---------------------------------------------------------------------- */
    /*                              Edge Cases                                */
    /* ---------------------------------------------------------------------- */

    function test_zero_address_operator() public {
        vm.startPrank(owner_);

        // Should be able to set address(0) as operator (though not practical)
        assertTrue(operableStub.setOperator(address(0), true));
        assertTrue(operableStub.isOperator(address(0)));

        assertTrue(operableStub.setOperatorFor(setMessageSelector, address(0), true));
        assertTrue(operableStub.isOperatorFor(setMessageSelector, address(0)));
    }

    function test_bytes4_zero_selector() public {
        vm.startPrank(owner_);

        // Should be able to set operator for bytes4(0) selector
        assertTrue(operableStub.setOperatorFor(bytes4(0), functionOperator, true));
        assertTrue(operableStub.isOperatorFor(bytes4(0), functionOperator));
    }

    function test_operator_status_persistence() public {
        vm.startPrank(owner_);

        // Set multiple operators
        operableStub.setOperator(globalOperator, true);
        operableStub.setOperatorFor(setMessageSelector, functionOperator, true);
        operableStub.setOperatorFor(updateMessageSelector, functionOperator, true);

        // Verify all statuses persist
        assertTrue(operableStub.isOperator(globalOperator));
        assertTrue(operableStub.isOperatorFor(setMessageSelector, functionOperator));
        assertTrue(operableStub.isOperatorFor(updateMessageSelector, functionOperator));

        // Revoke one and verify others persist
        operableStub.setOperatorFor(setMessageSelector, functionOperator, false);

        assertTrue(operableStub.isOperator(globalOperator));
        assertFalse(operableStub.isOperatorFor(setMessageSelector, functionOperator));
        assertTrue(operableStub.isOperatorFor(updateMessageSelector, functionOperator));
    }
}
