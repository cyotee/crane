// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {Behavior_IPTEAM} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_IPTEAM.sol";

contract NetNetFork_PTeam_Test is TestBase_NetNetFork {
    function test_live_exercisable_view() public view {
        uint256 nowCap = pTeam.exercisableNow();
        assertTrue(Behavior_IPTEAM.isValid_IPTEAM_strike(pTeam));
        nowCap;
    }
}
