// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20TargetStub} from "@crane/contracts/tokens/ERC20TargetStub.sol";

/**
 * @title ERC20Target_EdgeCases
 * @notice Edge case tests for ERC20Target implementation
 */
contract ERC20Target_EdgeCases is Test {

    ERC20TargetStub token;
    address alice;
    address bob;
    uint256 constant INITIAL_SUPPLY = 1_000_000e18;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        token = new ERC20TargetStub(alice, INITIAL_SUPPLY);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Transfer Edge Cases                           */
    /* ---------------------------------------------------------------------- */

    function test_transfer_zeroAmount_succeeds() public {
        vm.prank(alice);
        bool success = token.transfer(bob, 0);
        assertTrue(success, "Zero amount transfer should succeed");
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY, "Alice balance should be unchanged");
        assertEq(token.balanceOf(bob), 0, "Bob balance should be zero");
    }

    function test_transfer_toZeroAddress_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 100e18);
    }

    function test_transfer_insufficientBalance_reverts() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, INITIAL_SUPPLY, amount));
        token.transfer(bob, amount);
    }

    function test_transfer_fullBalance_succeeds() public {
        vm.prank(alice);
        bool success = token.transfer(bob, INITIAL_SUPPLY);
        assertTrue(success, "Full balance transfer should succeed");
        assertEq(token.balanceOf(alice), 0, "Alice should have zero balance");
        assertEq(token.balanceOf(bob), INITIAL_SUPPLY, "Bob should have full balance");
    }

    function test_transfer_toSelf_succeeds() public {
        uint256 amount = 100e18;
        uint256 balanceBefore = token.balanceOf(alice);
        vm.prank(alice);
        bool success = token.transfer(alice, amount);
        assertTrue(success, "Transfer to self should succeed");
        assertEq(token.balanceOf(alice), balanceBefore, "Balance should be unchanged");
    }

    function test_transfer_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(alice, bob, amount);
        token.transfer(bob, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                           Approve Edge Cases                           */
    /* ---------------------------------------------------------------------- */

    function test_approve_zeroAddressSpender_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 100e18);
    }

    function test_approve_zeroAmount_succeeds() public {
        vm.prank(alice);
        bool success = token.approve(bob, 0);
        assertTrue(success, "Zero amount approval should succeed");
        assertEq(token.allowance(alice, bob), 0, "Allowance should be zero");
    }

    function test_approve_overwriteExisting_succeeds() public {
        vm.startPrank(alice);
        token.approve(bob, 100e18);
        assertEq(token.allowance(alice, bob), 100e18, "Initial allowance");

        token.approve(bob, 50e18);
        assertEq(token.allowance(alice, bob), 50e18, "Allowance should be overwritten");
        vm.stopPrank();
    }

    function test_approve_maxUint256_succeeds() public {
        vm.prank(alice);
        bool success = token.approve(bob, type(uint256).max);
        assertTrue(success, "Max uint256 approval should succeed");
        assertEq(token.allowance(alice, bob), type(uint256).max, "Allowance should be max");
    }

    function test_approve_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(alice, bob, amount);
        token.approve(bob, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                        TransferFrom Edge Cases                          */
    /* ---------------------------------------------------------------------- */

    function test_transferFrom_withoutAllowance_reverts() public {
        // Bob tries to transfer from Alice without any approval
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, 100e18));
        token.transferFrom(alice, bob, 100e18);
    }

    function test_transferFrom_exceedsAllowance_reverts() public {
        // Alice approves Bob for 50 tokens
        vm.prank(alice);
        token.approve(bob, 50e18);

        // Bob tries to transfer 100 tokens (more than allowed)
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 50e18, 100e18));
        token.transferFrom(alice, bob, 100e18);
    }

    function test_transferFrom_decreasesAllowance() public {
        // Alice approves Bob for 100 tokens
        vm.prank(alice);
        token.approve(bob, 100e18);
        assertEq(token.allowance(alice, bob), 100e18, "Initial allowance");

        // Bob transfers 60 tokens
        vm.prank(bob);
        token.transferFrom(alice, bob, 60e18);
        assertEq(token.allowance(alice, bob), 40e18, "Allowance should decrease by transfer amount");

        // Bob can still transfer remaining allowance
        vm.prank(bob);
        token.transferFrom(alice, bob, 40e18);
        assertEq(token.allowance(alice, bob), 0, "Allowance should be zero");
    }

    function test_transferFrom_withAllowance_succeeds() public {
        // Setup: Alice approves Bob
        vm.prank(alice);
        token.approve(bob, 100e18);

        // Bob transfers from Alice to himself
        vm.prank(bob);
        bool success = token.transferFrom(alice, bob, 100e18);
        assertTrue(success, "TransferFrom should succeed");
        assertEq(token.balanceOf(bob), 100e18, "Bob should receive tokens");
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - 100e18, "Alice balance should decrease");
        assertEq(token.allowance(alice, bob), 0, "Allowance should be zero after full spend");
    }

    function test_transferFrom_toZeroAddress_reverts() public {
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transferFrom(alice, address(0), 100e18);
    }

    function test_transferFrom_insufficientBalance_reverts() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, INITIAL_SUPPLY, amount));
        token.transferFrom(alice, bob, amount);
    }

    function test_transferFrom_zeroAmount_succeeds() public {
        vm.prank(bob);
        bool success = token.transferFrom(alice, bob, 0);
        assertTrue(success, "Zero amount transferFrom should succeed");
    }

    function test_transferFrom_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(alice, bob, amount);
        token.transferFrom(alice, bob, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                        View Function Edge Cases                         */
    /* ---------------------------------------------------------------------- */

    function test_balanceOf_nonExistentAccount_returnsZero() public {
        address nonExistent = makeAddr("nonExistent");
        assertEq(token.balanceOf(nonExistent), 0, "Non-existent account should have zero balance");
    }

    function test_allowance_notSet_returnsZero() public view {
        assertEq(token.allowance(alice, bob), 0, "Unset allowance should be zero");
    }

    function test_totalSupply_matchesInitial() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Total supply should match initial");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Fuzz Tests                                    */
    /* ---------------------------------------------------------------------- */

    function testFuzz_transfer_anyValidAmount_succeeds(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);

        vm.prank(alice);
        bool success = token.transfer(bob, amount);
        assertTrue(success, "Transfer should succeed");
        assertEq(token.balanceOf(bob), amount, "Bob should receive correct amount");
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount, "Alice should have remaining");
    }

    function testFuzz_approve_anyAmount_succeeds(uint256 amount) public {
        vm.prank(alice);
        bool success = token.approve(bob, amount);
        assertTrue(success, "Approve should succeed");
        assertEq(token.allowance(alice, bob), amount, "Allowance should be set");
    }

    function testFuzz_transfer_preservesTotalSupply(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);

        uint256 totalBefore = token.totalSupply();
        vm.prank(alice);
        token.transfer(bob, amount);
        uint256 totalAfter = token.totalSupply();

        assertEq(totalAfter, totalBefore, "Total supply should be preserved");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Multiple Actor Scenarios                          */
    /* ---------------------------------------------------------------------- */

    function test_multipleTransfers_balancesCorrect() public {
        address charlie = makeAddr("charlie");

        // Alice sends to Bob
        vm.prank(alice);
        token.transfer(bob, 300e18);

        // Alice sends to Charlie
        vm.prank(alice);
        token.transfer(charlie, 200e18);

        // Bob sends to Charlie
        vm.prank(bob);
        token.transfer(charlie, 100e18);

        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - 500e18, "Alice balance incorrect");
        assertEq(token.balanceOf(bob), 200e18, "Bob balance incorrect");
        assertEq(token.balanceOf(charlie), 300e18, "Charlie balance incorrect");
    }

    function test_multipleApprovals_independent() public {
        address charlie = makeAddr("charlie");

        vm.startPrank(alice);
        token.approve(bob, 100e18);
        token.approve(charlie, 200e18);
        vm.stopPrank();

        assertEq(token.allowance(alice, bob), 100e18, "Bob's allowance incorrect");
        assertEq(token.allowance(alice, charlie), 200e18, "Charlie's allowance incorrect");
    }
}
