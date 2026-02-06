// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "contracts/interfaces/IERC20.sol";
import {BetterPermit2} from "contracts/protocols/utils/permit2/BetterPermit2.sol";
import {IPermit2} from "contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {ERC20PermitStub} from "contracts/tokens/ERC20/ERC20PermitStub.sol";
import {IERC20PermitProxy} from "contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {IERC4626PermitProxy} from "contracts/interfaces/proxies/IERC4626PermitProxy.sol";
import {ERC4626TargetStub} from "contracts/tokens/ERC4626/ERC4626TargetStub.sol";
import {IERC4626} from "contracts/interfaces/IERC4626.sol";
import {IERC4626Events} from "contracts/interfaces/IERC4626Events.sol";

contract ERC4626TargetStubTest is Test {
    IPermit2 permit2;

    IERC20PermitProxy reserveAsset;

    IERC4626PermitProxy vault;

    uint256 expectedReserveSupply;
    uint8 expectedDecimalOffset;

    function setUp() public {
        permit2 = IPermit2(address(new BetterPermit2()));
        expectedDecimalOffset = 3;
        expectedReserveSupply = 1_000_000_000e18;
        reserveAsset = IERC20PermitProxy(
            address(new ERC20PermitStub("Test Token", "TT", 18, address(this), expectedReserveSupply))
        );
        vault = IERC4626PermitProxy(address(new ERC4626TargetStub(reserveAsset, expectedDecimalOffset, permit2)));
        // super.setUp();
    }

    function test_IERC20Metadata_name() public view {
        assertEq(vault.name(), string.concat("ERC4626 Vault of ", reserveAsset.name()));
    }

    function test_IERC20Metadata_symbol() public view {
        assertEq(vault.symbol(), "ERC4626");
    }

    function test_IERC20Metadata_decimals() public view {
        assertEq(vault.decimals(), uint8(reserveAsset.decimals() + expectedDecimalOffset));
    }

    function test_IERC4626_deposit(uint256 depositAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        reserveAsset.approve(address(vault), depositAmt);
        uint256 previewShares = vault.previewDeposit(depositAmt);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), depositAmt, previewShares);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - depositAmt);
        assertEq(reserveAsset.balanceOf(address(vault)), depositAmt);
        assertEq(vault.totalSupply(), sharesMinted);
        assertEq(vault.totalAssets(), depositAmt);
        assertEq(vault.balanceOf(address(this)), sharesMinted);
    }

    function test_IERC4626_deposit_Permit2(uint256 depositAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        reserveAsset.approve(address(permit2), type(uint256).max);
        permit2.approve(address(reserveAsset), address(vault), uint160(depositAmt), type(uint48).max);
        uint256 previewShares = vault.previewDeposit(depositAmt);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), depositAmt, previewShares);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - depositAmt);
        assertEq(reserveAsset.balanceOf(address(vault)), depositAmt);
        assertEq(vault.totalSupply(), sharesMinted);
        assertEq(vault.totalAssets(), depositAmt);
        assertEq(vault.balanceOf(address(this)), sharesMinted);
    }

    function test_IERC4626_deposit_pretransfer(uint256 depositAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        uint256 previewShares = vault.previewDeposit(depositAmt);
        reserveAsset.transfer(address(vault), depositAmt);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), depositAmt, previewShares);
        // Pre-transfer the assets to the vault
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - depositAmt);
        assertEq(reserveAsset.balanceOf(address(vault)), depositAmt);
        assertEq(vault.totalSupply(), sharesMinted);
        assertEq(vault.totalAssets(), depositAmt);
        assertEq(vault.balanceOf(address(this)), sharesMinted);
    }

    function test_IERC4626_mint(uint256 mintAmt) public {
        mintAmt = bound(mintAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        uint256 previewAssets = vault.previewMint(mintAmt);
        reserveAsset.approve(address(vault), previewAssets);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), previewAssets, mintAmt);
        uint256 assetsDeposited = vault.mint(mintAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - previewAssets);
        assertEq(reserveAsset.balanceOf(address(vault)), previewAssets);
        assertEq(vault.totalSupply(), mintAmt);
        assertEq(vault.totalAssets(), previewAssets);
        assertEq(vault.balanceOf(address(this)), mintAmt);
    }

    function test_IERC4626_mint_Permit2(uint256 mintAmt) public {
        mintAmt = bound(mintAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        uint256 previewAssets = vault.previewMint(mintAmt);
        reserveAsset.approve(address(permit2), type(uint256).max);
        permit2.approve(address(reserveAsset), address(vault), uint160(previewAssets), type(uint48).max);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), previewAssets, mintAmt);
        uint256 assetsDeposited = vault.mint(mintAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - previewAssets);
        assertEq(reserveAsset.balanceOf(address(vault)), previewAssets);
        assertEq(vault.totalSupply(), mintAmt);
        assertEq(vault.totalAssets(), previewAssets);
        assertEq(vault.balanceOf(address(this)), mintAmt);
    }

    function test_IERC4626_mint_pretransfer(uint256 mintAmt) public {
        mintAmt = bound(mintAmt, 1e9, expectedReserveSupply);
        uint256 prevReserveBal = reserveAsset.balanceOf(address(this));
        uint256 previewAssets = vault.previewMint(mintAmt);
        reserveAsset.transfer(address(vault), previewAssets);
        vm.expectEmit(true, true, false, true);
        emit IERC4626Events.Deposit(address(this), address(this), previewAssets, mintAmt);
        // Pre-transfer the assets to the vault
        uint256 assetsDeposited = vault.mint(mintAmt, address(this));
        assertEq(reserveAsset.balanceOf(address(this)), prevReserveBal - previewAssets);
        assertEq(reserveAsset.balanceOf(address(vault)), previewAssets);
        assertEq(vault.totalSupply(), mintAmt);
        assertEq(vault.totalAssets(), previewAssets);
        assertEq(vault.balanceOf(address(this)), mintAmt);
    }

    function test_IERC4626_withdraw(uint256 depositAmt, uint256 withdrawAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        withdrawAmt = bound(withdrawAmt, 1e9, depositAmt);
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));

        uint256 previewShares = vault.previewWithdraw(withdrawAmt);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(this), address(this), address(this), withdrawAmt, previewShares);
        uint256 sharesBurned = vault.withdraw(withdrawAmt, address(this), address(this));
        // 80000000000000000000000000
        // 80000000000000000000000
        // assertEq(assetsWithdrawn, withdrawAmt, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + withdrawAmt,
            "Balance mismatch after withdraw"
        );
        assertEq(vault.totalSupply(), sharesMinted - previewShares, "Total supply mismatch after withdraw");
        assertEq(vault.totalAssets(), depositAmt - withdrawAmt, "Total assets mismatch after withdraw");
        assertEq(vault.balanceOf(address(this)), sharesMinted - previewShares, "Balance mismatch after withdraw");
    }

    function test_IERC4626_withdraw_Pretransfer(uint256 depositAmt, uint256 withdrawAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        withdrawAmt = bound(withdrawAmt, 1e9, depositAmt);
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));

        uint256 previewShares = vault.previewWithdraw(withdrawAmt);
        // Pre-transfer the assets to the vault
        vault.transfer(address(vault), previewShares);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(this), address(this), address(vault), withdrawAmt, previewShares);
        uint256 sharesBurned = vault.withdraw(withdrawAmt, address(this), address(vault));
        // assertEq(assetsWithdrawn, withdrawAmt, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + withdrawAmt,
            "Balance mismatch after withdraw"
        );
        assertEq(vault.totalSupply(), sharesMinted - previewShares, "Total supply mismatch after withdraw");
        assertEq(vault.totalAssets(), depositAmt - withdrawAmt, "Total assets mismatch after withdraw");
        assertEq(vault.balanceOf(address(this)), sharesMinted - previewShares, "Balance mismatch after withdraw");
    }

    function test_IERC4626_withdraw_Approved_Spender(address spender, uint256 depositAmt, uint256 withdrawAmt) public {
        vm.assume(spender != address(0));
        vm.assume(spender != address(this));
        vm.assume(spender != address(vault));
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        withdrawAmt = bound(withdrawAmt, 1e9, depositAmt);
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));

        uint256 previewShares = vault.previewWithdraw(withdrawAmt);
        vault.approve(spender, previewShares);
        vm.prank(spender);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(spender), address(this), address(this), withdrawAmt, previewShares);
        uint256 sharesBurned = vault.withdraw(withdrawAmt, address(this), address(this));
        // assertEq(assetsWithdrawn, withdrawAmt, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + withdrawAmt,
            "Balance mismatch after withdraw"
        );
        assertEq(vault.totalSupply(), sharesMinted - previewShares, "Total supply mismatch after withdraw");
        assertEq(vault.totalAssets(), depositAmt - withdrawAmt, "Total assets mismatch after withdraw");
        assertEq(vault.balanceOf(address(this)), sharesMinted - previewShares, "Balance mismatch after withdraw");
    }

    function test_IERC4626_redeem(uint256 depositAmt, uint256 redeemAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        redeemAmt = bound(redeemAmt, vault.previewDeposit(1e9), vault.previewDeposit(depositAmt));
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));

        uint256 previewAssets = vault.previewRedeem(redeemAmt);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(this), address(this), address(this), previewAssets, redeemAmt);
        uint256 assetsWithdrawn = vault.redeem(redeemAmt, address(this), address(this));
        // assertEq(assetsWithdrawn, previewAssets, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + assetsWithdrawn,
            "Balance mismatch after redeem"
        );
        assertEq(vault.totalSupply(), sharesMinted - redeemAmt, "Total supply mismatch after redeem");
        assertEq(vault.totalAssets(), depositAmt - assetsWithdrawn, "Total assets mismatch after redeem");
        assertEq(vault.balanceOf(address(this)), sharesMinted - redeemAmt, "Balance mismatch after redeem");
    }

    function test_IERC4626_redeem_Pretransfer(uint256 depositAmt, uint256 redeemAmt) public {
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        redeemAmt = bound(redeemAmt, vault.previewDeposit(1e9), vault.previewDeposit(depositAmt));
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));

        uint256 previewAssets = vault.previewRedeem(redeemAmt);
        // Pre-transfer the assets to the vault
        vault.transfer(address(vault), redeemAmt);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(this), address(this), address(vault), previewAssets, redeemAmt);
        uint256 assetsWithdrawn = vault.redeem(redeemAmt, address(this), address(vault));
        // assertEq(assetsWithdrawn, previewAssets, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + assetsWithdrawn,
            "Balance mismatch after redeem"
        );
        assertEq(vault.totalSupply(), sharesMinted - redeemAmt, "Total supply mismatch after redeem");
        assertEq(vault.totalAssets(), depositAmt - assetsWithdrawn, "Total assets mismatch after redeem");
        assertEq(vault.balanceOf(address(this)), sharesMinted - redeemAmt, "Balance mismatch after redeem");
    }

    function test_IERC4626_redeem_Approved_Spender(address spender, uint256 depositAmt, uint256 redeemAmt) public {
        vm.assume(spender != address(0));
        vm.assume(spender != address(this));
        vm.assume(spender != address(vault));
        depositAmt = bound(depositAmt, 1e9, expectedReserveSupply);
        redeemAmt = bound(redeemAmt, vault.previewDeposit(1e9), vault.previewDeposit(depositAmt));
        reserveAsset.approve(address(vault), depositAmt);
        uint256 sharesMinted = vault.deposit(depositAmt, address(this));
        uint256 previewAssets = vault.previewRedeem(redeemAmt);
        vault.approve(spender, redeemAmt);
        vm.prank(spender);
        vm.expectEmit(true, true, true, true);
        emit IERC4626Events.Withdraw(address(spender), address(this), address(this), previewAssets, redeemAmt);
        uint256 assetsWithdrawn = vault.redeem(redeemAmt, address(this), address(this));
        // assertEq(assetsWithdrawn, previewAssets, "Withdrawn amount mismatch");
        assertEq(
            reserveAsset.balanceOf(address(this)),
            expectedReserveSupply - depositAmt + assetsWithdrawn,
            "Balance mismatch after redeem"
        );
        assertEq(vault.totalSupply(), sharesMinted - redeemAmt, "Total supply mismatch after redeem");
        assertEq(vault.totalAssets(), depositAmt - assetsWithdrawn, "Total assets mismatch after redeem");
        assertEq(vault.balanceOf(address(this)), sharesMinted - redeemAmt, "Balance mismatch after redeem");
    }
}
