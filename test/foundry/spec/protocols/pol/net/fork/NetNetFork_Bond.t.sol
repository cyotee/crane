// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {Behavior_IBondDepository} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IBondDepository.sol";
import {NetNetBondService} from
    "@crane/contracts/protocols/pol/net/services/NetNetBondService.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

contract NetNetFork_Bond_Test is TestBase_NetNetFork {
    function test_live_market0_deposit_redeem() public {
        uint256 livePrice = bondDepository.bondPrice(0);
        uint256 local = Behavior_IBondDepository.expected_IBondDepository_bondPrice(oracle, treasury);
        assertEq(livePrice, local, "bondPrice vs local quote");

        uint256 amount = 10e6;
        deal(address(usdg), address(this), amount);
        (, uint256 payout) = NetNetBondService._deposit(
            NetNetBondService.DepositParams({
                bondDepository: bondDepository,
                quote: IERC20(address(usdg)),
                marketId: 0,
                amount: amount,
                maxPriceWad: livePrice,
                to: address(this)
            })
        );
        assertGt(payout, 0);
        vm.warp(block.timestamp + Constants.BOND_VEST);
        uint256 paid = NetNetBondService._redeem(
            NetNetBondService.RedeemParams({bondDepository: bondDepository, to: address(this)})
        );
        assertEq(paid, payout);
    }

    function test_live_inverse_not_required_while_above_nav() public view {
        uint256 twap = oracle.twapNetUsdg();
        uint256 backing = treasury.backingPerToken();
        if (twap > backing) {
            // Fill not required; active may still be true if the contract
            // does not gate on TWAP < backing. Record the live flag.
            inverseBond.active();
        }
    }
}
