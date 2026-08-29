// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_INET} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_INET.sol";
import {Behavior_ITaxCollector} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_ITaxCollector.sol";
import {NetNetSpotService} from "@crane/contracts/protocols/pol/net/services/NetNetSpotService.sol";
import {NetNetStakingService} from
    "@crane/contracts/protocols/pol/net/services/NetNetStakingService.sol";
import {TaxCollector} from "@crane/contracts/protocols/pol/net/src/TaxCollector.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";

contract NetNet_SpotFoT_Test is TestBase_NetNet {
    function test_buy_fot_500_bps() public {
        assertTrue(Behavior_INET.isValid_INET_taxTotalBps(INET(address(net)), net.taxTotalBps()));
        assertTrue(
            Behavior_INET.isValid_INET_isTaxedPair(INET(address(net)), address(pair), true, net.isTaxedPair(address(pair)))
        );

        usdg.mint(address(this), 1_000e6);
        uint256 collectorBefore = net.balanceOf(address(taxCollector));
        uint256 netBefore = net.balanceOf(address(this));
        _buyNet(1_000e6, 0);
        uint256 received = net.balanceOf(address(this)) - netBefore;
        uint256 tax = net.balanceOf(address(taxCollector)) - collectorBefore;
        uint256 sentFromPair = received + tax;
        assertTrue(Behavior_INET.isValid_INET_fotBps(sentFromPair, tax), "buy FoT 500 bps");
        assertGt(received, 0, "bought NET");
    }

    function test_sell_fot_500_bps() public {
        usdg.mint(address(this), 1_000e6);
        _buyNet(1_000e6, 0);
        uint256 sellAmt = net.balanceOf(address(this)) / 2;
        uint256 collectorBefore = net.balanceOf(address(taxCollector));
        _sellNet(sellAmt, 0);
        uint256 tax = net.balanceOf(address(taxCollector)) - collectorBefore;
        assertTrue(Behavior_INET.isValid_INET_fotBps(sellAmt, tax), "sell FoT 500 bps");
    }

    function test_wallet_transfer_untaxed() public {
        usdg.mint(address(this), 500e6);
        _buyNet(500e6, 0);
        address peer = makeAddr("netPeer");
        uint256 amt = net.balanceOf(address(this)) / 4;
        uint256 collectorBefore = net.balanceOf(address(taxCollector));
        net.transfer(peer, amt);
        assertEq(net.balanceOf(peer), amt, "peer received full");
        assertEq(net.balanceOf(address(taxCollector)), collectorBefore, "no tax");
        assertTrue(Behavior_INET.isValid_INET_untaxedTransfer(amt, amt));
    }

    function test_stake_untaxed() public {
        usdg.mint(address(this), 500e6);
        _buyNet(500e6, 0);
        uint256 amt = net.balanceOf(address(this)) / 2;
        uint256 collectorBefore = net.balanceOf(address(taxCollector));
        NetNetStakingService._stake(
            NetNetStakingService.StakeParams({
                staking: staking, net: IERC20(address(net)), to: address(this), amount: amt
            })
        );
        assertEq(net.balanceOf(address(taxCollector)), collectorBefore, "stake untaxed");
    }

    function test_convert_uses_tax_team_start_400() public {
        usdg.mint(address(this), 2_000e6);
        _buyNet(2_000e6, 0);
        uint256 expectedTeam = Behavior_ITaxCollector.expected_ITaxCollector_teamBps(pTeam);
        assertTrue(Behavior_ITaxCollector.isValid_ITaxCollector_teamBps(taxCollector, expectedTeam));
        assertEq(expectedTeam, Constants.TAX_TEAM_START_BPS * (Constants.WAD - pTeam.vestedFraction()) / Constants.WAD);
        assertGt(expectedTeam, 300, "not the stale 300 bps comment");

        uint256 pending = taxCollector.pendingNet();
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 netReserve = pair.token0() == address(net) ? uint256(r0) : uint256(r1);
        uint256 clipMax = netReserve * Constants.TAX_SWAP_MAX_CLIP_BPS / Constants.BPS;
        uint256 convertAmt = pending < clipMax ? pending : clipMax / 2;
        assertGt(convertAmt, 0, "some tax to convert");

        uint256 teamBefore = usdg.balanceOf(teamWallet);
        uint256 treBefore = usdg.balanceOf(address(treasury));
        NetNetSpotService._convert(
            NetNetSpotService.ConvertParams({
                taxCollector: taxCollector, netAmount: convertAmt, minUsdgOutRaw: 0
            })
        );
        uint256 teamShare = usdg.balanceOf(teamWallet) - teamBefore;
        uint256 treasuryShare = usdg.balanceOf(address(treasury)) - treBefore;
        assertTrue(
            Behavior_ITaxCollector.isValid_ITaxCollector_convertSplit(
                teamShare + treasuryShare, expectedTeam, teamShare, treasuryShare
            )
        );
    }

    function test_convert_clip_too_large_reverts() public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 netReserve = pair.token0() == address(net) ? uint256(r0) : uint256(r1);
        uint256 tooBig = netReserve * Constants.TAX_SWAP_MAX_CLIP_BPS / Constants.BPS + 1;
        vm.expectRevert(TaxCollector.ClipTooLarge.selector);
        taxCollector.convert(tooBig, 0);
    }
}
