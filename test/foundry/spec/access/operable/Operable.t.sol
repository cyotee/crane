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
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {OperableTargetStub} from "@crane/contracts/access/operable/OperableTargetStub.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

/**
 * @title OperableTest
 * @notice Tests for Operable access control system (functional via stub + LR-7 declaration tests).
 * @dev Follows LR-7: full init (real owner state, no 0), exact asserts, Behavior usage for facets, NatSpec per LR-1.
 *      Uses ONLY central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md for IOperable (0xa7f11160, 0x6d70f7ae etc) and IFacet refs.
 */
// tag::OperableTest[]
contract OperableTest is Test {
    OperableTargetStub public operable;

    address public owner;
    address public operator;
    address public functionOperator;
    address public nonOperator;

    function setUp() public {
        // LR-7 full initialization: real subject with owner (no address(0), self-contained MultiStepOwnable init via stub)
        // Proper init before any assertions; follows CraneTest/TestBase order principles (no factories needed for this access logic).
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
        // exact expected value (LR-7)
        assertEq(operable.isOperator(operator), false, "Initial status must be exact false");

        vm.expectEmit(true, true, true, true);
        emit IOperable.NewGlobalOperatorStatus(operator, true);

        vm.prank(owner);
        operable.setOperator(operator, true);

        assertEq(operable.isOperator(operator), true, "Status must be exact true after setOperator(true)");
    }

    function test_setOperator_revokesOperatorRole() public {
        // First grant operator status
        vm.prank(owner);
        operable.setOperator(operator, true);
        assertEq(operable.isOperator(operator), true, "Exact true after granting");

        // Now revoke
        vm.expectEmit(true, true, true, true);
        emit IOperable.NewGlobalOperatorStatus(operator, false);

        vm.prank(owner);
        operable.setOperator(operator, false);

        assertEq(operable.isOperator(operator), false, "Exact false after revoking");
    }

    function test_setOperator_revertsWhenNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, nonOperator));
        vm.prank(nonOperator);
        operable.setOperator(operator, true);
    }

    function test_isOperator_returnsCorrectStatus() public {
        assertEq(operable.isOperator(operator), false, "Initial status must be exact false");

        vm.prank(owner);
        operable.setOperator(operator, true);
        assertEq(operable.isOperator(operator), true, "Exact true after granting");

        vm.prank(owner);
        operable.setOperator(operator, false);
        assertEq(operable.isOperator(operator), false, "Exact false after revoking");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Function Operator Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_setOperatorFor_grantsFunctionSpecificAccess() public {
        bytes4 funcSelector = operable.restrictedByOnlyOperatorSelector();
        assertEq(operable.isOperatorFor(funcSelector, functionOperator), false, "Exact false initially for function op");

        vm.expectEmit(true, true, true, true);
        emit IOperable.NewFunctionOperatorStatus(functionOperator, funcSelector, true);

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);

        assertEq(operable.isOperatorFor(funcSelector, functionOperator), true, "Exact true after setOperatorFor(true)");
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

        assertEq(operable.isOperatorFor(funcSelector, functionOperator), false, "Initial must be exact false");

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, true);
        assertEq(operable.isOperatorFor(funcSelector, functionOperator), true, "Exact true after granting");

        vm.prank(owner);
        operable.setOperatorFor(funcSelector, functionOperator, false);
        assertEq(operable.isOperatorFor(funcSelector, functionOperator), false, "Exact false after revoking");
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

        assertEq(operable.isOperator(operator), true, "First operator exact set");
        assertEq(operable.isOperator(operator2), true, "Second operator exact set");

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

        assertEq(operable.isOperatorFor(funcSelector, functionOperator), true, "First function operator exact");
        assertEq(operable.isOperatorFor(funcSelector, funcOp2), true, "Second function operator exact");
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

        assertEq(operable.isOperator(anyOperator), true, "Exact: any address can become operator");
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

    /* -------------------------------------------------------------------------- */
    /*                 LR-7: Facet Declaration Tests via Behavior                 */
    /* -------------------------------------------------------------------------- */

    // tag::test_LR7_OperableFacet_declaration_viaBehavior()[]
    /**
     * @notice LR-7: OperableFacet must declare correct metadata using Behavior_IFacet (mandatory).
     *         Full init of facet (new, real), exact via Behavior + central values only.
     *         References IOperable interfaceId 0xa7f11160 and selectors from CENTRALLY_COMPUTED_NATSPEC_VALUES.md ONLY.
     * @custom:signature test_LR7_OperableFacet_declaration_viaBehavior()
     */
    function test_LR7_OperableFacet_declaration_viaBehavior() public {
        // LR-7 full init of real facet (no 0)
        IFacet operableF = IFacet(address(new OperableFacet()));
        vm.label(address(operableF), type(OperableFacet).name);

        // Expected from IOperable (central: interface 0xa7f11160; funcs 0x6d70f7ae,0xea562a25,0x558a7297,0x755dbe7c)
        // + IFacet overlap (central: 0x5b6f4d01 etc). Use .interfaceId/.selector for runtime correctness.
        bytes4[] memory expectedIfaces = new bytes4[](1);
        expectedIfaces[0] = type(IOperable).interfaceId; // == 0xa7f11160 per central

        bytes4[] memory expectedFuncs = new bytes4[](4);
        expectedFuncs[0] = IOperable.isOperator.selector; // 0x6d70f7ae
        expectedFuncs[1] = IOperable.isOperatorFor.selector; // 0xea562a25
        expectedFuncs[2] = IOperable.setOperator.selector; // 0x558a7297
        expectedFuncs[3] = IOperable.setOperatorFor.selector; // 0x755dbe7c

        // Use Behavior libs per LR-7 + AGENTS crane-testing (expect then hasValid)
        Behavior_IFacet.expect_IFacet_facetName(operableF, type(OperableFacet).name);
        Behavior_IFacet.expect_IFacet_facetInterfaces(operableF, expectedIfaces);
        Behavior_IFacet.expect_IFacet_facetFuncs(operableF, expectedFuncs);

        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(operableF), "facetName exact via Behavior");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(operableF), "facetInterfaces exact via Behavior");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetFuncs(operableF), "facetFuncs exact via Behavior");
        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(operableF), "facetMetadata consistency exact"
        );
    }
    // end::test_LR7_OperableFacet_declaration_viaBehavior()[]
}
// end::OperableTest[]
