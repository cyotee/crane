// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {OperableTargetStub} from "@crane/contracts/access/operable/OperableTargetStub.sol";

/**
 * @title OperableTest
 * @notice Tests for Operable access control system.
 */
contract OperableTest is Test {
    OperableTargetStub public operable;

    address public owner;
    address public operator;
    address public functionOperator;
    address public nonOperator;

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        functionOperator = makeAddr("functionOperator");
        nonOperator = makeAddr("nonOperator");

        operable = new OperableTargetStub(owner);

        vm.label(address(operable), "Operable");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Global Operator Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_setOperator_grantsOperatorRole() public {
        assertFalse(operable.isOperator(operator), "Should not be operator initially");

        vm.expectEmit(true, true, true, true);
        emit IOperable.NewGlobalOperatorStatus(operator, true);

        vm.prank(owner);
        operable.setOperator(operator, true);

        assertTrue(operable.isOperator(operator), "Should be operator after setting");
    }

    function test_setOperator_revokesOperatorRole() public {
        // First grant operator status
        vm.prank(owner);
        operable.setOperator(operator, true);
        assertTrue(operable.isOperator(operator), "Should be operator after granting");

        // Now revoke
        vm.expectEmit(true, true, true, true);
        emit IOperable.NewGlobalOperatorStatus(operator, false);

        vm.prank(owner);
        operable.setOperator(operator, false);

        assertFalse(operable.isOperator(operator), "Should not be operator after revoking");
    }

    function test_setOperator_revertsWhenNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, nonOperator));
        vm.prank(nonOperator);
        operable.setOperator(operator, true);
    }

    function test_isOperator_returnsCorrectStatus() public {
        assertFalse(operable.isOperator(operator), "Initial status should be false");

        vm.prank(owner);
        operable.setOperator(operator, true);
        assertTrue(operable.isOperator(operator), "Status should be true after granting");

        vm.prank(owner);
        operable.setOperator(operator, false);
        assertFalse(operable.isOperator(operator), "Status should be false after revoking");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Function Operator Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_setOperatorFor_grantsFunctionSpecificAccess() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();
        assertFalse(
            operable.isOperatorFor(funcSelector, functionOperator), "Should not be function operator initially"
        );

        vm.expectEmit(true, true, true, true);
        emit IOperable.NewFunctionOperatorStatus(functionOperator, funcSelector, true);

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        assertTrue(operable.isOperatorFor(funcSelector, functionOperator), "Should be function operator after setting");
    }

    function test_setOperatorFor_revokesFunctionSpecificAccess() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();

        // First grant
        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        // Now revoke
        vm.expectEmit(true, true, true, true);
        emit IOperable.NewFunctionOperatorStatus(functionOperator, funcSelector, false);

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, false);

        assertFalse(
            operable.isOperatorFor(funcSelector, functionOperator), "Should not be function operator after revoking"
        );
    }

    function test_setOperatorFor_revertsWhenNotOwner() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();

        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, nonOperator));
        vm.prank(nonOperator);
        operable.setOperatorFor(funcSelector, functionOperator, true);
    }

    function test_isOperatorFor_returnsCorrectStatus() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();

        assertFalse(operable.isOperatorFor(funcSelector, functionOperator), "Initial status should be false");

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);
        assertTrue(operable.isOperatorFor(funcSelector, functionOperator), "Status should be true after granting");

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, false);
        assertFalse(operable.isOperatorFor(funcSelector, functionOperator), "Status should be false after revoking");
    }

    /* -------------------------------------------------------------------------- */
    /*                       onlyOperator Modifier Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_onlyOperator_allowsGlobalOperator() public {
        vm.prank(owner);
        operable.setOperator(operator, true);

        vm.prank(operator);
        uint256 result = operable.restrictedByOnlyOperator(42);

        assertEq(result, 42, "Global operator should be able to call");
        assertEq(operable.lastCalledValue(), 42, "Value should be stored");
    }

    function test_onlyOperator_allowsFunctionOperator() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        vm.prank(functionOperator);
        uint256 result = operable.restrictedByOnlyOperator(42);

        assertEq(result, 42, "Function operator should be able to call");
    }

    function test_onlyOperator_blocksNonOperator() public {
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, nonOperator));
        vm.prank(nonOperator);
        operable.restrictedByOnlyOperator(42);
    }

    function test_onlyOperator_functionOperatorLimitedToFunction() public {
        // Grant function operator for restrictedByOnlyOperator
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();
        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        // Can call the function they're authorized for
        vm.prank(functionOperator);
        operable.restrictedByOnlyOperator(42);

        // But cannot call a different restricted function (restrictedByOnlyOwnerOrOperator has a different selector)
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, functionOperator));
        vm.prank(functionOperator);
        operable.restrictedByOnlyOwnerOrOperator(42);
    }

    /* -------------------------------------------------------------------------- */
    /*                   onlyOwnerOrOperator Modifier Tests                       */
    /* -------------------------------------------------------------------------- */

    function test_onlyOwnerOrOperator_allowsOwner() public {
        vm.prank(owner);
        uint256 result = operable.restrictedByOnlyOwnerOrOperator(99);

        assertEq(result, 99, "Owner should be able to call");
    }

    function test_onlyOwnerOrOperator_allowsGlobalOperator() public {
        vm.prank(owner);
        operable.setOperator(operator, true);

        vm.prank(operator);
        uint256 result = operable.restrictedByOnlyOwnerOrOperator(99);

        assertEq(result, 99, "Global operator should be able to call");
    }

    function test_onlyOwnerOrOperator_allowsFunctionOperator() public {
        bytes4 funcSelector = OperableTargetStub.restrictedByOnlyOwnerOrOperator.selector;

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        vm.prank(functionOperator);
        uint256 result = operable.restrictedByOnlyOwnerOrOperator(99);

        assertEq(result, 99, "Function operator should be able to call");
    }

    function test_onlyOwnerOrOperator_blocksNonOperator() public {
        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, nonOperator));
        vm.prank(nonOperator);
        operable.restrictedByOnlyOwnerOrOperator(99);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Multiple Operators Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_multipleGlobalOperators() public {
        address operator2 = makeAddr("operator2");

        vm.startPrank(owner);
        operable.setOperator(operator, true);
        operable.setOperator(operator2, true);
        vm.stopPrank();

        assertTrue(operable.isOperator(operator), "First operator should be set");
        assertTrue(operable.isOperator(operator2), "Second operator should be set");

        vm.prank(operator);
        operable.restrictedByOnlyOperator(1);

        vm.prank(operator2);
        operable.restrictedByOnlyOperator(2);

        assertEq(operable.lastCalledValue(), 2, "Both operators should be able to call");
    }

    function test_multipleFunctionOperators() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();
        address funcOp2 = makeAddr("funcOp2");

        vm.startPrank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);
        operable.setOperatorFor(funcSelector, funcOp2, true);
        vm.stopPrank();

        assertTrue(operable.isOperatorFor(funcSelector, functionOperator), "First function operator should be set");
        assertTrue(operable.isOperatorFor(funcSelector, funcOp2), "Second function operator should be set");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    function test_ownerIsNotAutomaticallyOperator() public {
        assertFalse(operable.isOperator(owner), "Owner should not be global operator by default");
    }

    function test_revokedOperatorCannotCall() public {
        // Grant and then revoke
        vm.startPrank(owner);
        operable.setOperator(operator, true);
        operable.setOperator(operator, false);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, operator));
        vm.prank(operator);
        operable.restrictedByOnlyOperator(42);
    }

    function test_publicFunctionAllowsAnyone() public {
        vm.prank(nonOperator);
        uint256 result = operable.publicFunction(42);
        assertEq(result, 42, "Public function should allow anyone");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Fuzz Tests                                    */
    /* -------------------------------------------------------------------------- */

    function testFuzz_setOperator_anyAddress(address anyOperator) public {
        vm.assume(anyOperator != address(0));

        vm.prank(owner);
        operable.setOperator(anyOperator, true);

        assertTrue(operable.isOperator(anyOperator), "Any address can become operator");
    }

    function testFuzz_nonOwnerCannotSetOperator(address attacker) public {
        vm.assume(attacker != owner);
        vm.assume(attacker != address(0));

        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, attacker));
        vm.prank(attacker);
        operable.setOperator(operator, true);
    }

    function testFuzz_nonOperatorCannotCallRestricted(address caller) public {
        vm.assume(caller != owner);
        vm.assume(!operable.isOperator(caller));

        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();
        vm.assume(!operable.isOperatorFor(funcSelector, caller));

        vm.expectRevert(abi.encodeWithSelector(IOperable.NotOperator.selector, caller));
        vm.prank(caller);
        operable.restrictedByOnlyOperator(42);
    }
}
