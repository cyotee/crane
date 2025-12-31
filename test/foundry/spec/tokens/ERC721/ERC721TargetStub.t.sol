// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721TargetStub} from "@crane/contracts/tokens/ERC721/ERC721TargetStub.sol";
import {Behavior_IERC721} from "@crane/contracts/tokens/ERC721/Behavior_IERC721.sol";

/**
 * @title ERC721TargetStub_Test
 * @notice Functional tests for ERC721TargetStub
 */
contract ERC721TargetStub_Test is Test {
    ERC721TargetStub token;

    address alice;
    address bob;
    address charlie;
    address operator;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        operator = makeAddr("operator");

        token = new ERC721TargetStub();
    }

    /* ---------------------------------------------------------------------- */
    /*                            Mint Tests                                   */
    /* ---------------------------------------------------------------------- */

    function test_mint_toAddress_mintsToken() public {
        uint256 tokenId = token.mint(alice);

        assertEq(token.ownerOf(tokenId), alice, "Alice should own the token");
        assertEq(token.balanceOf(alice), 1, "Alice should have balance of 1");
    }

    function test_mint_multiple_incrementsTokenId() public {
        uint256 tokenId1 = token.mint(alice);
        uint256 tokenId2 = token.mint(alice);
        uint256 tokenId3 = token.mint(bob);

        assertEq(tokenId1, 0, "First token should be 0");
        assertEq(tokenId2, 1, "Second token should be 1");
        assertEq(tokenId3, 2, "Third token should be 2");
        assertEq(token.balanceOf(alice), 2, "Alice should have 2 tokens");
        assertEq(token.balanceOf(bob), 1, "Bob should have 1 token");
    }

    function test_mint_toZeroAddress_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOwner.selector, address(0)));
        token.mint(address(0));
    }

    function test_mint_emitsTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), alice, 0);
        token.mint(alice);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Transfer Tests                                 */
    /* ---------------------------------------------------------------------- */

    function test_transferFrom_ownerTransfers_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.transferFrom(alice, bob, tokenId);

        assertEq(token.ownerOf(tokenId), bob, "Bob should own the token");
        assertEq(token.balanceOf(alice), 0, "Alice should have 0 tokens");
        assertEq(token.balanceOf(bob), 1, "Bob should have 1 token");
    }

    function test_transferFrom_approvedTransfers_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.approve(operator, tokenId);

        vm.prank(operator);
        token.transferFrom(alice, bob, tokenId);

        assertEq(token.ownerOf(tokenId), bob, "Bob should own the token");
    }

    function test_transferFrom_operatorTransfers_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        vm.prank(operator);
        token.transferFrom(alice, bob, tokenId);

        assertEq(token.ownerOf(tokenId), bob, "Bob should own the token");
    }

    function test_transferFrom_clearsApproval() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.approve(operator, tokenId);
        assertEq(token.getApproved(tokenId), operator, "Operator should be approved");

        vm.prank(alice);
        token.transferFrom(alice, bob, tokenId);

        assertEq(token.getApproved(tokenId), address(0), "Approval should be cleared");
    }

    function test_transferFrom_notOwnerOrApproved_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, bob, tokenId));
        token.transferFrom(alice, charlie, tokenId);
    }

    function test_transferFrom_toZeroAddress_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOwner.selector, address(0)));
        token.transferFrom(alice, address(0), tokenId);
    }

    function test_transferFrom_nonexistentToken_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 999));
        token.transferFrom(alice, bob, 999);
    }

    function test_transferFrom_wrongFrom_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, bob, tokenId, alice));
        token.transferFrom(bob, charlie, tokenId);
    }

    function test_transferFrom_emitsEvent() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(alice, bob, tokenId);
        token.transferFrom(alice, bob, tokenId);
    }

    /* ---------------------------------------------------------------------- */
    /*                          Approve Tests                                  */
    /* ---------------------------------------------------------------------- */

    function test_approve_setsApproval() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.approve(operator, tokenId);

        assertEq(token.getApproved(tokenId), operator, "Operator should be approved");
    }

    function test_approve_notOwner_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, bob, tokenId, alice));
        token.approve(operator, tokenId);
    }

    function test_approve_toZeroAddress_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOperator.selector, address(0)));
        token.approve(address(0), tokenId);
    }

    function test_approve_emitsEvent() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Approval(alice, operator, tokenId);
        token.approve(operator, tokenId);
    }

    /* ---------------------------------------------------------------------- */
    /*                     SetApprovalForAll Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_setApprovalForAll_setsApproval() public {
        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        assertTrue(token.isApprovedForAll(alice, operator), "Operator should be approved for all");
    }

    function test_setApprovalForAll_canRevoke() public {
        vm.prank(alice);
        token.setApprovalForAll(operator, true);
        assertTrue(token.isApprovedForAll(alice, operator), "Should be approved");

        vm.prank(alice);
        token.setApprovalForAll(operator, false);
        assertFalse(token.isApprovedForAll(alice, operator), "Should be revoked");
    }

    function test_setApprovalForAll_toZeroAddress_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOperator.selector, address(0)));
        token.setApprovalForAll(address(0), true);
    }

    function test_setApprovalForAll_emitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC721.ApprovalForAll(alice, operator, true);
        token.setApprovalForAll(operator, true);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Burn Tests                                   */
    /* ---------------------------------------------------------------------- */

    function test_burn_ownerBurns_succeeds() public {
        uint256 tokenId = token.mint(alice);
        assertEq(token.balanceOf(alice), 1, "Alice should have 1 token");

        vm.prank(alice);
        token.burn(tokenId);

        assertEq(token.balanceOf(alice), 0, "Alice should have 0 tokens");
    }

    function test_burn_approvedBurns_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.approve(operator, tokenId);

        vm.prank(operator);
        token.burn(tokenId);

        assertEq(token.balanceOf(alice), 0, "Token should be burned");
    }

    function test_burn_operatorBurns_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        vm.prank(operator);
        token.burn(tokenId);

        assertEq(token.balanceOf(alice), 0, "Token should be burned");
    }

    function test_burn_notApproved_reverts() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, bob, tokenId));
        token.burn(tokenId);
    }

    function test_burn_nonexistentToken_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 999));
        token.burn(999);
    }

    function test_burn_emitsEvent() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(alice, address(0), tokenId);
        token.burn(tokenId);
    }

    /* ---------------------------------------------------------------------- */
    /*                       SafeTransferFrom Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_safeTransferFrom_toEOA_succeeds() public {
        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.safeTransferFrom(alice, bob, tokenId);

        assertEq(token.ownerOf(tokenId), bob, "Bob should own the token");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Behavior Tests                                 */
    /* ---------------------------------------------------------------------- */

    function test_behavior_balanceOf() public {
        token.mint(alice);
        token.mint(alice);
        token.mint(bob);

        assertTrue(
            Behavior_IERC721.isValid_balanceOf(IERC721(address(token)), alice, 2),
            "Alice should have 2 tokens"
        );
        assertTrue(
            Behavior_IERC721.isValid_balanceOf(IERC721(address(token)), bob, 1),
            "Bob should have 1 token"
        );
    }

    function test_behavior_ownerOf() public {
        uint256 tokenId = token.mint(alice);

        assertTrue(
            Behavior_IERC721.isValid_ownerOf(IERC721(address(token)), tokenId, alice),
            "Alice should own the token"
        );
    }

    function test_behavior_transfer() public {
        uint256 tokenId = token.mint(alice);
        uint256 aliceBalBefore = token.balanceOf(alice);
        uint256 bobBalBefore = token.balanceOf(bob);

        vm.prank(alice);
        token.transferFrom(alice, bob, tokenId);

        assertTrue(
            Behavior_IERC721.isValid_transfer(
                IERC721(address(token)),
                alice,
                bob,
                tokenId,
                aliceBalBefore,
                bobBalBefore
            ),
            "Transfer should be valid"
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_mint_anyAddress_succeeds(address to) public {
        vm.assume(to != address(0));

        uint256 tokenId = token.mint(to);

        assertEq(token.ownerOf(tokenId), to, "Recipient should own the token");
        assertGe(token.balanceOf(to), 1, "Recipient should have at least 1 token");
    }

    function testFuzz_transfer_anyRecipient_succeeds(address to) public {
        vm.assume(to != address(0));

        uint256 tokenId = token.mint(alice);

        vm.prank(alice);
        token.transferFrom(alice, to, tokenId);

        assertEq(token.ownerOf(tokenId), to, "Recipient should own the token");
    }

    function testFuzz_mintBurnMint_tokenIdsIncrement(uint8 count) public {
        vm.assume(count > 0 && count < 50);

        // Mint several tokens
        for (uint8 i = 0; i < count; i++) {
            token.mint(alice);
        }

        assertEq(token.balanceOf(alice), count, "Should have minted correct count");

        // Burn first token
        vm.prank(alice);
        token.burn(0);

        // Mint new token - should get next ID, not reuse 0
        uint256 newTokenId = token.mint(bob);
        assertEq(newTokenId, count, "New token should get next ID");
    }
}
