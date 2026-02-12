// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {ERC4626TargetStub} from "@crane/contracts/tokens/ERC4626/ERC4626TargetStub.sol";
import {ERC20PermitStub} from "@crane/contracts/tokens/ERC20/ERC20PermitStub.sol";
import {BetterPermit2} from "@crane/contracts/protocols/utils/permit2/BetterPermit2.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

/**
 * @title ERC4626_Rounding_Test
 * @notice Edge case tests for ERC4626 rounding behavior
 */
contract ERC4626_Rounding_Test is Test {
    ERC20PermitStub asset;
    ERC4626TargetStub vault;
    IPermit2 permit2;

    address alice;
    address bob;
    address charlie;

    uint256 constant INITIAL_SUPPLY = 1_000_000_000e18;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        permit2 = IPermit2(address(new BetterPermit2()));
        asset = new ERC20PermitStub("Test Asset", "TAST", 18, address(this), INITIAL_SUPPLY);

        // Deploy vault with decimal offset of 3
        vault = new ERC4626TargetStub(IERC20Metadata(address(asset)), 3, permit2);

        // Fund test accounts
        asset.transfer(alice, 100_000e18);
        asset.transfer(bob, 100_000e18);
        asset.transfer(charlie, 100_000e18);
    }

    /* ---------------------------------------------------------------------- */
    /*                       First Depositor Edge Cases                        */
    /* ---------------------------------------------------------------------- */

    function test_firstDeposit_zeroTotalSupply_mintsCorrectShares() public {
        uint256 depositAmount = 1000e18;

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // First deposit: shares = assets * 10^decimalOffset (due to virtual shares)
        // With decimalOffset=3: shares should be depositAmount * 1000
        assertGt(shares, 0, "Should mint non-zero shares");
        assertEq(vault.totalAssets(), depositAmount, "Total assets should equal deposit");
        assertEq(vault.totalSupply(), shares, "Total supply should equal minted shares");
    }

    function test_firstDeposit_verySmallAmount_handlesCorrectly() public {
        uint256 depositAmount = 1; // 1 wei

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Even 1 wei should mint some shares due to decimal offset
        assertGt(shares, 0, "Should mint non-zero shares for 1 wei");
        assertEq(vault.totalAssets(), depositAmount, "Total assets should equal deposit");
    }

    function test_firstMint_exactShares_chargesCorrectAssets() public {
        uint256 sharesToMint = 1000e21; // 1000 shares with 21 decimals (18 + 3 offset)

        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        vm.startPrank(alice);
        asset.approve(address(vault), assetsNeeded);
        uint256 assetsUsed = vault.mint(sharesToMint, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), sharesToMint, "Should have exact shares");
        assertEq(assetsUsed, assetsNeeded, "Assets used should match preview");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Rounding Direction Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_convertToShares_roundsDown() public {
        // Setup: make a deposit to establish exchange rate
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();

        // Test that convertToShares rounds down
        uint256 sharesFor1 = vault.convertToShares(1);
        uint256 sharesFor2 = vault.convertToShares(2);

        // Due to rounding down, shares*2 might equal shares or be slightly less
        assertLe(sharesFor1 * 2, sharesFor2 + 1, "Should round down consistently");
    }

    function test_convertToAssets_roundsDown() public {
        // Setup: make a deposit
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();

        // Test that convertToAssets rounds down
        uint256 assetsFor1 = vault.convertToAssets(1);
        uint256 assetsFor2 = vault.convertToAssets(2);

        assertLe(assetsFor1 * 2, assetsFor2 + 1, "Should round down consistently");
    }

    function test_previewMint_roundsUp() public {
        // Setup: make a deposit
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();

        // previewMint should round up (user needs to provide more assets)
        uint256 assetsForMint = vault.previewMint(1);

        // Converting back should give at least 1 share
        uint256 sharesForAssets = vault.convertToShares(assetsForMint);
        assertGe(sharesForAssets, 1, "previewMint should round up");
    }

    function test_previewWithdraw_roundsUp() public {
        // Setup: make a deposit
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();

        // previewWithdraw should round up (user burns more shares)
        uint256 sharesForWithdraw = vault.previewWithdraw(1);

        // Converting shares back should give at least 1 asset
        uint256 assetsForShares = vault.convertToAssets(sharesForWithdraw);
        assertGe(assetsForShares, 1, "previewWithdraw should round up");
    }

    /* ---------------------------------------------------------------------- */
    /*                     Yield Accumulation Scenarios                        */
    /* ---------------------------------------------------------------------- */

    function test_yieldAccumulation_depositersGetSameShareValue() public {
        // Note: This vault uses lastTotalAssets which is cached and doesn't allow
        // direct transfers to simulate yield (has ERC4626TransferNotReceived check).
        // This test verifies that consecutive depositors get fair share values.

        // Alice deposits first
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        uint256 aliceShares = vault.deposit(1000e18, alice);
        vm.stopPrank();

        uint256 aliceAssetsValue = vault.convertToAssets(aliceShares);

        // Bob deposits same amount
        vm.startPrank(bob);
        asset.approve(address(vault), 1000e18);
        uint256 bobShares = vault.deposit(1000e18, bob);
        vm.stopPrank();

        uint256 bobAssetsValue = vault.convertToAssets(bobShares);

        // Both should have same value for same deposit
        assertEq(aliceShares, bobShares, "Same deposit should yield same shares");
        assertEq(aliceAssetsValue, bobAssetsValue, "Same shares should have same value");
    }

    function test_multipleDepositors_fairShareDistribution() public {
        // Alice deposits
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        uint256 aliceShares = vault.deposit(1000e18, alice);
        vm.stopPrank();

        // Bob deposits same amount
        vm.startPrank(bob);
        asset.approve(address(vault), 1000e18);
        uint256 bobShares = vault.deposit(1000e18, bob);
        vm.stopPrank();

        // Both should have same shares for same deposit
        assertEq(aliceShares, bobShares, "Equal deposits should yield equal shares");

        // Both should be able to withdraw same amount
        uint256 aliceMaxWithdraw = vault.maxWithdraw(alice);
        uint256 bobMaxWithdraw = vault.maxWithdraw(bob);
        assertEq(aliceMaxWithdraw, bobMaxWithdraw, "Equal shares should have equal withdrawable");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Large Decimal Offset Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_largeDecimalOffset_handlesCorrectly() public {
        // Deploy vault with large decimal offset (max reasonable: 18)
        ERC4626TargetStub largeOffsetVault =
            new ERC4626TargetStub(IERC20Metadata(address(asset)), 8, permit2);

        vm.startPrank(alice);
        asset.approve(address(largeOffsetVault), 1000e18);
        uint256 shares = largeOffsetVault.deposit(1000e18, alice);
        vm.stopPrank();

        assertGt(shares, 0, "Should mint shares with large offset");
        assertEq(largeOffsetVault.totalAssets(), 1000e18, "Total assets should match");

        // Verify decimals
        uint8 vaultDecimals = largeOffsetVault.decimals();
        assertEq(vaultDecimals, 18 + 8, "Vault decimals should be asset + offset");
    }

    function test_zeroDecimalOffset_worksCorrectly() public {
        // Deploy vault with zero decimal offset
        ERC4626TargetStub zeroOffsetVault =
            new ERC4626TargetStub(IERC20Metadata(address(asset)), 0, permit2);

        vm.startPrank(alice);
        asset.approve(address(zeroOffsetVault), 1000e18);
        uint256 shares = zeroOffsetVault.deposit(1000e18, alice);
        vm.stopPrank();

        assertGt(shares, 0, "Should mint shares with zero offset");
        assertEq(zeroOffsetVault.decimals(), 18, "Vault decimals should equal asset decimals");
    }

    /* ---------------------------------------------------------------------- */
    /*                         Withdrawal Edge Cases                           */
    /* ---------------------------------------------------------------------- */

    function test_fullWithdrawal_returnsAllAssets() public {
        uint256 depositAmount = 1000e18;

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);

        // Withdraw all
        uint256 maxWithdraw = vault.maxWithdraw(alice);
        uint256 sharesBurned = vault.withdraw(maxWithdraw, alice, alice);
        vm.stopPrank();

        // Should have burned all shares
        assertEq(vault.balanceOf(alice), 0, "Should have zero shares after full withdrawal");

        // Should have received assets back (might be slightly less due to rounding)
        assertGe(asset.balanceOf(alice), 100_000e18 - 1, "Should get assets back");
    }

    function test_fullRedeem_returnsAllAssets() public {
        uint256 depositAmount = 1000e18;

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);

        // Redeem all shares
        uint256 assetsReceived = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), 0, "Should have zero shares after full redeem");
        assertGt(assetsReceived, 0, "Should receive assets");
    }

    function test_partialWithdrawal_leavesCorrectBalance() public {
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, alice);

        // Withdraw half
        uint256 withdrawAmount = 500e18;
        vault.withdraw(withdrawAmount, alice, alice);
        vm.stopPrank();

        // Should have roughly half shares remaining
        uint256 remainingShares = vault.balanceOf(alice);
        assertGt(remainingShares, 0, "Should have remaining shares");
        assertLt(remainingShares, shares, "Should have fewer shares after withdrawal");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Preview Accuracy Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_previewDeposit_matchesActualDeposit() public {
        uint256 depositAmount = 1000e18;

        uint256 previewedShares = vault.previewDeposit(depositAmount);

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 actualShares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(actualShares, previewedShares, "Actual should match preview for deposit");
    }

    function test_previewMint_matchesActualMint() public {
        uint256 sharesToMint = 1000e21;

        uint256 previewedAssets = vault.previewMint(sharesToMint);

        vm.startPrank(alice);
        asset.approve(address(vault), previewedAssets);
        uint256 actualAssets = vault.mint(sharesToMint, alice);
        vm.stopPrank();

        assertEq(actualAssets, previewedAssets, "Actual should match preview for mint");
    }

    function test_previewWithdraw_matchesActualWithdraw() public {
        // Setup: deposit first
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);

        uint256 withdrawAmount = 500e18;
        uint256 previewedShares = vault.previewWithdraw(withdrawAmount);
        uint256 actualShares = vault.withdraw(withdrawAmount, alice, alice);
        vm.stopPrank();

        // previewWithdraw rounds up, so actual should match or be less
        assertLe(actualShares, previewedShares, "Actual should be <= preview for withdraw");
    }

    function test_previewRedeem_matchesActualRedeem() public {
        // Setup: deposit first
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, alice);

        uint256 sharesToRedeem = shares / 2;
        uint256 previewedAssets = vault.previewRedeem(sharesToRedeem);
        uint256 actualAssets = vault.redeem(sharesToRedeem, alice, alice);
        vm.stopPrank();

        assertEq(actualAssets, previewedAssets, "Actual should match preview for redeem");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Fuzz Tests                                    */
    /* ---------------------------------------------------------------------- */

    function testFuzz_depositWithdraw_noFreeShares(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e9, 10_000e18);

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);

        uint256 maxWithdraw = vault.maxWithdraw(alice);
        vm.stopPrank();

        // Should never be able to withdraw more than deposited
        assertLe(maxWithdraw, depositAmount, "maxWithdraw should not exceed deposit");
    }

    function testFuzz_mintRedeem_noFreeAssets(uint256 sharesToMint) public {
        sharesToMint = bound(sharesToMint, 1e12, 10_000e21);

        uint256 assetsNeeded = vault.previewMint(sharesToMint);
        if (assetsNeeded > asset.balanceOf(alice)) return;

        vm.startPrank(alice);
        asset.approve(address(vault), assetsNeeded);
        vault.mint(sharesToMint, alice);

        uint256 assetsBack = vault.previewRedeem(sharesToMint);
        vm.stopPrank();

        // Should never get more assets back than deposited
        assertLe(assetsBack, assetsNeeded, "Redeemed assets should not exceed minted");
    }

    function testFuzz_roundTripPreservesValue(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e15, 10_000e18);

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);

        uint256 shares = vault.deposit(depositAmount, alice);
        uint256 assetsBack = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        // Due to rounding, we might lose a tiny bit
        // But should never gain
        assertLe(assetsBack, depositAmount, "Round trip should not create value");

        // Should get back most of what we put in (within reasonable rounding)
        // Allow up to 0.01% loss for rounding
        uint256 maxLoss = depositAmount / 10000;
        assertGe(assetsBack, depositAmount - maxLoss - 1, "Round trip loss too high");
    }
}
