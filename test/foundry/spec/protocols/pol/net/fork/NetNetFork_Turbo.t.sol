// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {Behavior_ITurboRouter} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_ITurboRouter.sol";
import {LendingConstants} from
    "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";

contract NetNetFork_Turbo_Test is TestBase_NetNetFork {
    function test_live_target_ltv_and_zero_amount() public {
        assertTrue(Behavior_ITurboRouter.isValid_ITurboRouter_targetLtv(LendingConstants.TARGET_LTV_WAD));
        vm.expectRevert(TurboRouter.ZeroAmount.selector);
        turboRouter.turbo(0, 0, 0);
    }

    function test_live_current_ltv_view() public view {
        turboRouter.currentLtvWad(address(this));
        assertEq(turboRouter.lltv(), LendingConstants.LLTV);
    }
}
