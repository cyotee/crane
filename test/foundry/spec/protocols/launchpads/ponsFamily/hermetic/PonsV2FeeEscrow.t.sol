// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/ERC20.sol";

import {PonsV2FeeEscrow} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2FeeEscrow.sol";

contract MintableERC20 is ERC20 {
    constructor() ERC20("Quote", "QTE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @notice Hermetic ledger tests for reconstructed PonsV2FeeEscrow.
contract PonsV2FeeEscrow_Test is Test {
    PonsV2FeeEscrow internal escrow;
    MintableERC20 internal token;

    address internal alice;
    address internal bob;
    address internal crediter;

    event Credited(address indexed recipient, uint256 amount);
    event Claimed(address indexed recipient, uint256 amount);
    event CreditedToken(address indexed recipient, address indexed token, uint256 amount);
    event ClaimedToken(address indexed recipient, address indexed token, uint256 amount);

    function setUp() public {
        escrow = new PonsV2FeeEscrow();
        token = new MintableERC20();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        crediter = makeAddr("crediter");
        vm.deal(crediter, 100 ether);
        token.mint(crediter, 1_000_000 ether);
    }

    function test_credit_native_and_claimAll() public {
        vm.prank(crediter);
        vm.expectEmit(true, false, false, true, address(escrow));
        emit Credited(alice, 1 ether);
        escrow.credit{value: 1 ether}(alice);

        assertEq(escrow.balanceOf(alice), 1 ether);
        assertEq(address(escrow).balance, 1 ether);

        uint256 before = alice.balance;
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(escrow));
        emit Claimed(alice, 1 ether);
        uint256 claimed = escrow.claim();

        assertEq(claimed, 1 ether);
        assertEq(escrow.balanceOf(alice), 0);
        assertEq(alice.balance, before + 1 ether);
    }

    function test_credit_native_partialClaim() public {
        vm.prank(crediter);
        escrow.credit{value: 3 ether}(alice);

        vm.prank(alice);
        uint256 claimed = escrow.claim(1 ether);
        assertEq(claimed, 1 ether);
        assertEq(escrow.balanceOf(alice), 2 ether);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(PonsV2FeeEscrow.InsufficientBalance.selector, 5 ether, 2 ether)
        );
        escrow.claim(5 ether);
    }

    function test_creditToken_and_claimAll() public {
        vm.startPrank(crediter);
        token.approve(address(escrow), 50 ether);
        vm.expectEmit(true, true, false, true, address(escrow));
        emit CreditedToken(bob, address(token), 50 ether);
        escrow.creditToken(bob, address(token), 50 ether);
        vm.stopPrank();

        assertEq(escrow.balanceOfToken(bob, address(token)), 50 ether);
        assertEq(token.balanceOf(address(escrow)), 50 ether);

        vm.prank(bob);
        vm.expectEmit(true, true, false, true, address(escrow));
        emit ClaimedToken(bob, address(token), 50 ether);
        uint256 claimed = escrow.claimToken(address(token));

        assertEq(claimed, 50 ether);
        assertEq(token.balanceOf(bob), 50 ether);
        assertEq(escrow.balanceOfToken(bob, address(token)), 0);
    }

    function test_creditToken_partialClaim() public {
        vm.startPrank(crediter);
        token.approve(address(escrow), 100 ether);
        escrow.creditToken(alice, address(token), 100 ether);
        vm.stopPrank();

        vm.prank(alice);
        uint256 claimed = escrow.claimToken(address(token), 40 ether);
        assertEq(claimed, 40 ether);
        assertEq(escrow.balanceOfToken(alice, address(token)), 60 ether);
        assertEq(token.balanceOf(alice), 40 ether);
    }

    function test_credit_zeroValue_isNoOp() public {
        vm.prank(crediter);
        escrow.credit{value: 0}(alice);
        assertEq(escrow.balanceOf(alice), 0);
    }

    function test_credit_revertsZeroRecipient() public {
        vm.prank(crediter);
        vm.expectRevert(PonsV2FeeEscrow.ZeroAddress.selector);
        escrow.credit{value: 1 ether}(address(0));
    }

    function test_receive_rejectsUnsolicitedEth() public {
        vm.prank(crediter);
        vm.expectRevert(PonsV2FeeEscrow.NativeTokenNotAllowed.selector);
        (bool ok,) = address(escrow).call{value: 1 ether}("");
        ok; // silence
    }

    function test_independentRecipientsAndAssets() public {
        vm.startPrank(crediter);
        escrow.credit{value: 1 ether}(alice);
        escrow.credit{value: 2 ether}(bob);
        token.approve(address(escrow), 30 ether);
        escrow.creditToken(alice, address(token), 10 ether);
        escrow.creditToken(bob, address(token), 20 ether);
        vm.stopPrank();

        assertEq(escrow.balanceOf(alice), 1 ether);
        assertEq(escrow.balanceOf(bob), 2 ether);
        assertEq(escrow.balanceOfToken(alice, address(token)), 10 ether);
        assertEq(escrow.balanceOfToken(bob, address(token)), 20 ether);

        vm.prank(alice);
        escrow.claim();
        assertEq(escrow.balanceOf(alice), 0);
        assertEq(escrow.balanceOf(bob), 2 ether);
        assertEq(escrow.balanceOfToken(alice, address(token)), 10 ether);
    }
}
