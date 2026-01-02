// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {BetterSafeERC20Harness} from "@crane/contracts/test/stubs/BetterSafeERC20Harness.sol";
import {
    MockERC20Standard,
    MockERC20NonReturning,
    MockERC20Reverting,
    MockERC20FalseReturning,
    MockERC20NoMetadata,
    MockERC20USDTApproval
} from "@crane/contracts/test/stubs/MockERC20Variants.sol";

/**
 * @title BetterSafeERC20_Test
 * @notice Tests for BetterSafeERC20 library with various ERC20 token behaviors.
 */
contract BetterSafeERC20_Test is Test {
    BetterSafeERC20Harness internal harness;

    MockERC20Standard internal standardToken;
    MockERC20NonReturning internal nonReturningToken;
    MockERC20Reverting internal revertingToken;
    MockERC20FalseReturning internal falseReturningToken;
    MockERC20NoMetadata internal noMetadataToken;
    MockERC20USDTApproval internal usdtApprovalToken;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal spender = makeAddr("spender");

    uint256 internal constant MINT_AMOUNT = 1000 ether;
    uint256 internal constant TRANSFER_AMOUNT = 100 ether;

    function setUp() public {
        harness = new BetterSafeERC20Harness();

        standardToken = new MockERC20Standard();
        nonReturningToken = new MockERC20NonReturning();
        revertingToken = new MockERC20Reverting();
        falseReturningToken = new MockERC20FalseReturning();
        noMetadataToken = new MockERC20NoMetadata();
        usdtApprovalToken = new MockERC20USDTApproval();

        // Mint tokens to harness for transfer tests
        standardToken.mint(address(harness), MINT_AMOUNT);
        nonReturningToken.mint(address(harness), MINT_AMOUNT);
        revertingToken.mint(address(harness), MINT_AMOUNT);
        falseReturningToken.mint(address(harness), MINT_AMOUNT);
        noMetadataToken.mint(address(harness), MINT_AMOUNT);
        usdtApprovalToken.mint(address(harness), MINT_AMOUNT);

        // Mint tokens to alice for transferFrom tests
        standardToken.mint(alice, MINT_AMOUNT);
        nonReturningToken.mint(alice, MINT_AMOUNT);
        revertingToken.mint(alice, MINT_AMOUNT);
        falseReturningToken.mint(alice, MINT_AMOUNT);
        noMetadataToken.mint(alice, MINT_AMOUNT);
        usdtApprovalToken.mint(alice, MINT_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                            safeTransfer Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_safeTransfer_standardToken_transfersAndReturnsTrue() public {
        bool result = harness.safeTransfer(IERC20(address(standardToken)), bob, TRANSFER_AMOUNT);
        assertTrue(result, "safeTransfer should return true");
        assertEq(standardToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
        assertEq(standardToken.balanceOf(address(harness)), MINT_AMOUNT - TRANSFER_AMOUNT, "Harness balance should decrease");
    }

    function test_safeTransfer_nonReturningToken_transfersSuccessfully() public {
        bool result = harness.safeTransfer(IERC20(address(nonReturningToken)), bob, TRANSFER_AMOUNT);
        assertTrue(result, "safeTransfer should return true for non-returning token");
        assertEq(nonReturningToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
    }

    function test_safeTransfer_revertingToken_reverts() public {
        vm.expectRevert("Transfer not allowed");
        harness.safeTransfer(IERC20(address(revertingToken)), bob, TRANSFER_AMOUNT);
    }

    function test_safeTransfer_falseReturningToken_whenFalse_reverts() public {
        falseReturningToken.setShouldReturnFalse(true);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(falseReturningToken)));
        harness.safeTransfer(IERC20(address(falseReturningToken)), bob, TRANSFER_AMOUNT);
    }

    function test_safeTransfer_insufficientBalance_reverts() public {
        vm.expectRevert("Insufficient balance");
        harness.safeTransfer(IERC20(address(standardToken)), bob, MINT_AMOUNT + 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                          safeTransferFrom Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_safeTransferFrom_standardToken_transfersWithAllowance() public {
        // Alice approves harness
        vm.prank(alice);
        standardToken.approve(address(harness), TRANSFER_AMOUNT);

        bool result = harness.safeTransferFrom(IERC20(address(standardToken)), alice, bob, TRANSFER_AMOUNT);
        assertTrue(result, "safeTransferFrom should return true");
        assertEq(standardToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
        assertEq(standardToken.balanceOf(alice), MINT_AMOUNT - TRANSFER_AMOUNT, "Alice balance should decrease");
    }

    function test_safeTransferFrom_nonReturningToken_transfersSuccessfully() public {
        vm.prank(alice);
        nonReturningToken.approve(address(harness), TRANSFER_AMOUNT);

        bool result = harness.safeTransferFrom(IERC20(address(nonReturningToken)), alice, bob, TRANSFER_AMOUNT);
        assertTrue(result, "safeTransferFrom should return true for non-returning token");
        assertEq(nonReturningToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
    }

    function test_safeTransferFrom_insufficientAllowance_reverts() public {
        vm.prank(alice);
        standardToken.approve(address(harness), TRANSFER_AMOUNT - 1);

        vm.expectRevert("Insufficient allowance");
        harness.safeTransferFrom(IERC20(address(standardToken)), alice, bob, TRANSFER_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                           trySafeTransfer Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_trySafeTransfer_standardToken_returnsTrue() public {
        bool result = harness.trySafeTransfer(IERC20(address(standardToken)), bob, TRANSFER_AMOUNT);
        assertTrue(result, "trySafeTransfer should return true");
        assertEq(standardToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
    }

    function test_trySafeTransfer_falseReturningToken_whenFalse_returnsFalse() public {
        falseReturningToken.setShouldReturnFalse(true);
        bool result = harness.trySafeTransfer(IERC20(address(falseReturningToken)), bob, TRANSFER_AMOUNT);
        assertFalse(result, "trySafeTransfer should return false");
        assertEq(falseReturningToken.balanceOf(bob), 0, "Bob should not receive tokens");
    }

    function test_trySafeTransfer_revertingToken_returnsFalse() public {
        bool result = harness.trySafeTransfer(IERC20(address(revertingToken)), bob, TRANSFER_AMOUNT);
        assertFalse(result, "trySafeTransfer should return false for reverting token");
    }

    /* -------------------------------------------------------------------------- */
    /*                         trySafeTransferFrom Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_trySafeTransferFrom_standardToken_returnsTrue() public {
        vm.prank(alice);
        standardToken.approve(address(harness), TRANSFER_AMOUNT);

        bool result = harness.trySafeTransferFrom(IERC20(address(standardToken)), alice, bob, TRANSFER_AMOUNT);
        assertTrue(result, "trySafeTransferFrom should return true");
        assertEq(standardToken.balanceOf(bob), TRANSFER_AMOUNT, "Bob should receive tokens");
    }

    function test_trySafeTransferFrom_insufficientAllowance_returnsFalse() public {
        // No approval given
        bool result = harness.trySafeTransferFrom(IERC20(address(standardToken)), alice, bob, TRANSFER_AMOUNT);
        assertFalse(result, "trySafeTransferFrom should return false for insufficient allowance");
    }

    /* -------------------------------------------------------------------------- */
    /*                       safeIncreaseAllowance Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_safeIncreaseAllowance_standardToken_increasesAllowance() public {
        harness.safeIncreaseAllowance(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT);
        assertEq(standardToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");

        harness.safeIncreaseAllowance(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT);
        assertEq(standardToken.allowance(address(harness), spender), TRANSFER_AMOUNT * 2, "Allowance should increase");
    }

    function test_safeIncreaseAllowance_nonReturningToken_increasesAllowance() public {
        harness.safeIncreaseAllowance(IERC20(address(nonReturningToken)), spender, TRANSFER_AMOUNT);
        assertEq(nonReturningToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");
    }

    /* -------------------------------------------------------------------------- */
    /*                       safeDecreaseAllowance Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_safeDecreaseAllowance_standardToken_decreasesAllowance() public {
        harness.safeIncreaseAllowance(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT * 2);
        harness.safeDecreaseAllowance(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT);
        assertEq(standardToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should decrease");
    }

    function test_safeDecreaseAllowance_nonReturningToken_decreasesAllowance() public {
        harness.safeIncreaseAllowance(IERC20(address(nonReturningToken)), spender, TRANSFER_AMOUNT * 2);
        harness.safeDecreaseAllowance(IERC20(address(nonReturningToken)), spender, TRANSFER_AMOUNT);
        assertEq(nonReturningToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should decrease");
    }

    /* -------------------------------------------------------------------------- */
    /*                            forceApprove Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_forceApprove_standardToken_setsAllowance() public {
        harness.forceApprove(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT);
        assertEq(standardToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");
    }

    function test_forceApprove_nonReturningToken_setsAllowance() public {
        harness.forceApprove(IERC20(address(nonReturningToken)), spender, TRANSFER_AMOUNT);
        assertEq(nonReturningToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");
    }

    function test_forceApprove_usdtApprovalToken_overwritesExistingAllowance() public {
        // USDT requires setting to 0 first before changing, but forceApprove handles this
        harness.forceApprove(IERC20(address(usdtApprovalToken)), spender, TRANSFER_AMOUNT);
        assertEq(usdtApprovalToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Initial allowance set");

        // forceApprove should handle USDT-like tokens by setting to 0 first
        harness.forceApprove(IERC20(address(usdtApprovalToken)), spender, TRANSFER_AMOUNT * 2);
        assertEq(usdtApprovalToken.allowance(address(harness), spender), TRANSFER_AMOUNT * 2, "Allowance should be updated");
    }

    /* -------------------------------------------------------------------------- */
    /*                            safeApprove Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_safeApprove_standardToken_setsAllowance() public {
        harness.safeApprove(IERC20(address(standardToken)), spender, TRANSFER_AMOUNT);
        assertEq(standardToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");
    }

    function test_safeApprove_nonReturningToken_setsAllowance() public {
        harness.safeApprove(IERC20(address(nonReturningToken)), spender, TRANSFER_AMOUNT);
        assertEq(nonReturningToken.allowance(address(harness), spender), TRANSFER_AMOUNT, "Allowance should be set");
    }

    function test_safeApprove_falseReturningToken_whenFalse_reverts() public {
        falseReturningToken.setShouldReturnFalse(true);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(falseReturningToken)));
        harness.safeApprove(IERC20(address(falseReturningToken)), spender, TRANSFER_AMOUNT);
    }

    /* -------------------------------------------------------------------------- */
    /*                             safeName Tests                                 */
    /* -------------------------------------------------------------------------- */

    function test_safeName_standardToken_returnsName() public view {
        string memory name = harness.safeName(IERC20Metadata(address(standardToken)));
        assertEq(name, "Standard Token", "Should return token name");
    }

    function test_safeName_noMetadataToken_returnsFallback() public view {
        string memory name = harness.safeName(IERC20Metadata(address(noMetadataToken)));
        assertEq(name, "ERC20 Token", "Should return fallback name");
    }

    function test_safeName_nonContract_returnsFallback() public view {
        string memory name = harness.safeName(IERC20Metadata(alice));
        assertEq(name, "ERC20 Token", "Should return fallback for non-contract");
    }

    /* -------------------------------------------------------------------------- */
    /*                            safeSymbol Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_safeSymbol_standardToken_returnsSymbol() public view {
        string memory symbol = harness.safeSymbol(IERC20Metadata(address(standardToken)));
        assertEq(symbol, "STD", "Should return token symbol");
    }

    function test_safeSymbol_noMetadataToken_returnsFallback() public view {
        string memory symbol = harness.safeSymbol(IERC20Metadata(address(noMetadataToken)));
        assertEq(symbol, "ERC20", "Should return fallback symbol");
    }

    function test_safeSymbol_nonContract_returnsFallback() public view {
        string memory symbol = harness.safeSymbol(IERC20Metadata(alice));
        assertEq(symbol, "ERC20", "Should return fallback for non-contract");
    }

    /* -------------------------------------------------------------------------- */
    /*                           safeDecimals Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_safeDecimals_standardToken_returnsDecimals() public view {
        uint8 decimals = harness.safeDecimals(IERC20Metadata(address(standardToken)));
        assertEq(decimals, 18, "Should return 18 decimals");
    }

    function test_safeDecimals_nonReturningToken_returnsSixDecimals() public view {
        // Non-returning token has 6 decimals (like USDT)
        uint8 decimals = harness.safeDecimals(IERC20Metadata(address(nonReturningToken)));
        assertEq(decimals, 6, "Should return 6 decimals");
    }

    function test_safeDecimals_noMetadataToken_returnsFallback() public view {
        uint8 decimals = harness.safeDecimals(IERC20Metadata(address(noMetadataToken)));
        assertEq(decimals, 18, "Should return fallback 18 decimals");
    }

    function test_safeDecimals_nonContract_returnsFallback() public view {
        uint8 decimals = harness.safeDecimals(IERC20Metadata(alice));
        assertEq(decimals, 18, "Should return fallback for non-contract");
    }

    /* -------------------------------------------------------------------------- */
    /*                               cast Tests                                   */
    /* -------------------------------------------------------------------------- */

    function test_cast_convertsIERC20ArrayToBetterIERC20Array() public view {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = IERC20(address(standardToken));
        tokens[1] = IERC20(address(nonReturningToken));
        tokens[2] = IERC20(address(noMetadataToken));

        BetterIERC20[] memory betterTokens = harness.cast(tokens);

        assertEq(betterTokens.length, 3, "Array length should match");
        assertEq(address(betterTokens[0]), address(standardToken), "First token address should match");
        assertEq(address(betterTokens[1]), address(nonReturningToken), "Second token address should match");
        assertEq(address(betterTokens[2]), address(noMetadataToken), "Third token address should match");
    }

    function test_cast_emptyArray_returnsEmptyArray() public view {
        IERC20[] memory tokens = new IERC20[](0);
        BetterIERC20[] memory betterTokens = harness.cast(tokens);
        assertEq(betterTokens.length, 0, "Empty array should return empty array");
    }

    /* -------------------------------------------------------------------------- */
    /*                             Fuzz Tests                                     */
    /* -------------------------------------------------------------------------- */

    function testFuzz_safeTransfer_anyAmount_transfersOrReverts(uint256 amount) public {
        amount = bound(amount, 0, MINT_AMOUNT);

        uint256 bobBalanceBefore = standardToken.balanceOf(bob);
        bool result = harness.safeTransfer(IERC20(address(standardToken)), bob, amount);

        assertTrue(result, "safeTransfer should return true");
        assertEq(standardToken.balanceOf(bob), bobBalanceBefore + amount, "Bob balance should increase");
    }

    function testFuzz_safeIncreaseAllowance_anyAmount_increases(uint256 amount) public {
        amount = bound(amount, 0, type(uint128).max); // Avoid overflow

        harness.safeIncreaseAllowance(IERC20(address(standardToken)), spender, amount);
        assertEq(standardToken.allowance(address(harness), spender), amount, "Allowance should match");
    }
}
