// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {Behavior_INET} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_INET.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

contract NetNetFork_SpotFoT_Test is TestBase_NetNetFork {
    function test_live_buy_sell_fot() public {
        deal(address(usdg), address(this), 100e6);
        uint256 collectorBefore = net.balanceOf(address(taxCollector));
        uint256 netBefore = net.balanceOf(address(this));
        _buyNet(100e6, 0);
        uint256 received = net.balanceOf(address(this)) - netBefore;
        uint256 tax = net.balanceOf(address(taxCollector)) - collectorBefore;
        uint256 sent = received + tax;
        assertTrue(Behavior_INET.isValid_INET_fotBps(sent, tax), "live buy FoT");
        assertGt(received, 0);

        uint256 sellAmt = received / 2;
        collectorBefore = net.balanceOf(address(taxCollector));
        _sellNet(sellAmt, 0);
        tax = net.balanceOf(address(taxCollector)) - collectorBefore;
        assertTrue(Behavior_INET.isValid_INET_fotBps(sellAmt, tax), "live sell FoT");
    }

    function test_live_convert_or_view() public view {
        uint256 pending = taxCollector.pendingNet();
        uint256 team = taxCollector.teamBps();
        assertLe(team, Constants.TAX_TEAM_START_BPS);
        pending;
    }
}
