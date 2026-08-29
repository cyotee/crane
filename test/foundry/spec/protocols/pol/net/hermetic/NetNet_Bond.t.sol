// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_IBondDepository} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IBondDepository.sol";
import {NetNetBondService} from
    "@crane/contracts/protocols/pol/net/services/NetNetBondService.sol";
import {BondDepository} from "@crane/contracts/protocols/pol/net/src/BondDepository.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

contract NetNet_Bond_Test is TestBase_NetNet {
    function test_market0_deposit_warp_vest_redeem() public {
        uint256 expectedPrice = Behavior_IBondDepository.expected_IBondDepository_bondPrice(oracle, treasury);
        assertTrue(Behavior_IBondDepository.isValid_IBondDepository_bondPrice(bondDepository, 0, expectedPrice));

        uint256 amount = 10e6;
        usdg.mint(address(this), amount);
        uint256 maxPrice = expectedPrice;
        (uint256 noteId, uint256 payout) = NetNetBondService._deposit(
            NetNetBondService.DepositParams({
                bondDepository: bondDepository,
                quote: IERC20(address(usdg)),
                marketId: 0,
                amount: amount,
                maxPriceWad: maxPrice,
                to: address(this)
            })
        );
        assertEq(noteId, 0);
        assertGt(payout, 0);

        (uint256 pending,) = bondDepository.pendingFor(address(this));
        assertEq(pending, payout);

        vm.warp(block.timestamp + Constants.BOND_VEST);
        uint256 netBefore = net.balanceOf(address(this));
        uint256 paid = NetNetBondService._redeem(
            NetNetBondService.RedeemParams({bondDepository: bondDepository, to: address(this)})
        );
        assertEq(paid, payout);
        assertEq(net.balanceOf(address(this)) - netBefore, payout);
        assertTrue(Behavior_IBondDepository.isValid_IBondDepository_vestLinear(payout, Constants.BOND_VEST, paid));
    }

    function test_zero_amount_reverts() public {
        vm.expectRevert(BondDepository.ZeroAmount.selector);
        bondDepository.deposit(0, 0, type(uint256).max, address(this));
    }

    function test_price_above_max_reverts() public {
        uint256 price = bondDepository.bondPrice(0);
        usdg.mint(address(this), 1e6);
        usdg.approve(address(bondDepository), 1e6);
        vm.expectRevert(BondDepository.PriceAboveMax.selector);
        bondDepository.deposit(0, 1e6, price - 1, address(this));
    }
}
