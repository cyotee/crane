// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {Id} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {Behavior_ITurboRouter} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_ITurboRouter.sol";
import {NetNetStakingService} from
    "@crane/contracts/protocols/pol/net/services/NetNetStakingService.sol";
import {NetNetTurboService} from
    "@crane/contracts/protocols/pol/net/services/NetNetTurboService.sol";
import {LendingConstants} from
    "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

contract NetNet_Turbo_Test is TestBase_NetNet {
    function _acquireWs(uint256 usdgBuy) internal returns (uint256 wsBal) {
        usdg.mint(address(this), usdgBuy);
        _buyNet(usdgBuy, 0);
        uint256 netAmt = net.balanceOf(address(this));
        NetNetStakingService._stake(
            NetNetStakingService.StakeParams({
                staking: staking, net: IERC20(address(net)), to: address(this), amount: netAmt
            })
        );
        uint256 sAmt = sNet.balanceOf(address(this));
        sNet.approve(address(wsNet), sAmt);
        wsBal = wsNet.wrap(sAmt);
    }

    function test_turbo_increases_collateral_then_unwind() public {
        assertTrue(Behavior_ITurboRouter.isValid_ITurboRouter_targetLtv(LendingConstants.TARGET_LTV_WAD));
        uint256 wsBal = _acquireWs(5_000e6);
        NetNetTurboService._setMorphoAuthorization(
            NetNetTurboService.AuthParams({
                morpho: morpho, router: address(turboRouter), authorized: true
            })
        );

        uint128 collBefore = morpho.position(Id.wrap(loopbackMarketId), address(this)).collateral;

        uint256 borrowAssets = 10e6;
        NetNetTurboService._turbo(
            NetNetTurboService.TurboParams({
                turboRouter: turboRouter,
                wsNet: IERC20(address(wsNet)),
                wsIn: wsBal,
                borrowAssets: borrowAssets,
                minWsFromLoop: 1
            })
        );

        uint128 collAfter = morpho.position(Id.wrap(loopbackMarketId), address(this)).collateral;
        uint128 borrowShares = morpho.position(Id.wrap(loopbackMarketId), address(this)).borrowShares;
        assertGt(collAfter, collBefore, "collateral increased");
        assertGt(borrowShares, 0, "has debt");

        NetNetTurboService._unwind(
            NetNetTurboService.UnwindParams({
                turboRouter: turboRouter,
                repayShares: borrowShares,
                wsCollateralOut: collAfter,
                minUsdgFromSale: 0
            })
        );
        uint128 borrowAfter = morpho.position(Id.wrap(loopbackMarketId), address(this)).borrowShares;
        assertEq(borrowAfter, 0, "unwound");
    }

    function test_above_target_ltv_reverts() public {
        uint256 wsBal = _acquireWs(5_000e6);
        NetNetTurboService._setMorphoAuthorization(
            NetNetTurboService.AuthParams({
                morpho: morpho, router: address(turboRouter), authorized: true
            })
        );
        wsNet.approve(address(turboRouter), wsBal);
        uint256 px = loopbackOracle.price();
        uint256 collLoan = wsBal * px / 1e36;
        // Between Turbo target (53.125%) and Morpho LLTV (62.5%).
        uint256 borrow = collLoan * 56 / 100;
        vm.expectRevert(Behavior_ITurboRouter.selector_ITurboRouter_AboveTargetLtv());
        turboRouter.turbo(wsBal, borrow, 1);
    }

    function test_zero_amount_reverts() public {
        vm.expectRevert(TurboRouter.ZeroAmount.selector);
        turboRouter.turbo(0, 0, 0);
    }
}
