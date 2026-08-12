// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamily
} from "@crane/contracts/protocols/launchpads/ponsFamily/v1/test/bases/TestBase_PonsFamily.sol";
import {PonsLauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLauncherToken.sol";

contract PonsLauncherToken_restrictions_Test is TestBase_PonsFamily {
    function test_sameBlock_nonCreatorBuy_reverts() public {
        address token = _launchWithoutSeed(keccak256("restrict-same-block"));
        address sniper = makeAddr("sniper");

        // Still on launch block — only atomic seed-buy recipient is exempt.
        assertEq(block.number, PonsLauncherToken(token).launchBlock());

        // Pool-path reverts surface as TransferHelper "TF" through the router; assert
        // the token rule directly by pranking the canonical pool (holds LP inventory).
        address pool = PonsLauncherToken(token).liquidityPool();
        assertGt(PonsLauncherToken(token).balanceOf(pool), 0, "pool holds inventory");

        uint256 amount = 1 ether;
        vm.prank(pool);
        vm.expectRevert(
            abi.encodeWithSelector(PonsLauncherToken.LaunchBlockBuyBlocked.selector, sniper)
        );
        PonsLauncherToken(token).transfer(sniper, amount);
    }

    function test_maxWallet_revertsInsideWindow() public {
        address token = _launchWithoutSeed(keccak256("restrict-max-wallet"));
        // Leave launch block but stay inside restriction window.
        vm.roll(block.number + 1);
        assertLe(block.number, PonsLauncherToken(token).restrictionEndBlock());

        address buyer = makeAddr("windowBuyer");
        uint256 maxWallet = PonsLauncherToken(token).maxWalletLimit();
        assertEq(maxWallet, (PONS_SUPPLY * PONS_MAX_WALLET_BPS) / 10_000);

        address pool = PonsLauncherToken(token).liquidityPool();
        // Single pool→wallet transfer just over max wallet.
        uint256 overWallet = maxWallet + 1;
        vm.prank(pool);
        vm.expectRevert(
            abi.encodeWithSelector(
                PonsLauncherToken.MaxWalletExceeded.selector, buyer, overWallet, maxWallet
            )
        );
        PonsLauncherToken(token).transfer(buyer, overWallet);
    }

    /// @dev MaxTx is cumulative pool buys in the window. Wallet transfers out do not reset
    ///      `_restrictedPoolBuys`, so a second under-maxWallet buy can still hit MaxTxExceeded.
    function test_maxTx_revertsInsideWindow_viaCumulativePoolBuys() public {
        address token = _launchWithoutSeed(keccak256("restrict-max-tx"));
        vm.roll(block.number + 1);
        assertLe(block.number, PonsLauncherToken(token).restrictionEndBlock());

        address buyer = makeAddr("cumBuyer");
        address friend = makeAddr("friend");
        uint256 maxWallet = PonsLauncherToken(token).maxWalletLimit();
        uint256 maxTx = PonsLauncherToken(token).maxTxLimit();
        assertEq(maxTx, (PONS_SUPPLY * PONS_MAX_TX_BPS) / 10_000);
        assertGt(maxTx, maxWallet, "maxTx is 110% of maxWallet");

        address pool = PonsLauncherToken(token).liquidityPool();

        // 1) First restricted buy: fill wallet to max (still ≤ maxTx).
        vm.prank(pool);
        assertTrue(PonsLauncherToken(token).transfer(buyer, maxWallet));
        assertEq(PonsLauncherToken(token).balanceOf(buyer), maxWallet);

        // 2) Wallet→wallet out (unrestricted) frees balance; cumulative pool buys stay.
        vm.prank(buyer);
        assertTrue(PonsLauncherToken(token).transfer(friend, maxWallet));
        assertEq(PonsLauncherToken(token).balanceOf(buyer), 0);

        // 3) Second pool buy: amount alone is under maxWallet, but cumulative > maxTx.
        uint256 secondBuy = maxTx - maxWallet + 1;
        assertLe(secondBuy, maxWallet, "second buy alone stays under max wallet");
        uint256 attemptedCumulative = maxWallet + secondBuy;
        assertGt(attemptedCumulative, maxTx, "cumulative exceeds max tx");

        vm.prank(pool);
        vm.expectRevert(
            abi.encodeWithSelector(
                PonsLauncherToken.MaxTxExceeded.selector, buyer, attemptedCumulative, maxTx
            )
        );
        PonsLauncherToken(token).transfer(buyer, secondBuy);
    }

    function test_afterRestrictionsEnd_buySucceeds() public {
        address token = _launchWithoutSeed(keccak256("restrict-after"));
        _warpPastRestrictions(token);

        address buyer = makeAddr("postWindowBuyer");
        uint256 out = _buyTokensWithEth(token, buyer, 0.1 ether);
        assertGt(out, 0, "received tokens after window");
        assertEq(PonsLauncherToken(token).balanceOf(buyer), out);
    }

    function test_walletTransfer_unrestricted_duringWindow() public {
        address token = _launchWithoutSeed(keccak256("xfer-ok-2"));
        // Still inside restriction window (launch block).
        assertLe(block.number, PonsLauncherToken(token).restrictionEndBlock());

        address holder = makeAddr("holder");
        address friend = makeAddr("friend");
        // Wallet-to-wallet transfers are never throttled — deal inventory off-pool path.
        uint256 amount = 1_000 ether;
        deal(token, holder, amount);

        vm.prank(holder);
        assertTrue(PonsLauncherToken(token).transfer(friend, amount / 2));
        assertEq(PonsLauncherToken(token).balanceOf(friend), amount / 2);
        assertEq(PonsLauncherToken(token).balanceOf(holder), amount / 2);
    }
}
