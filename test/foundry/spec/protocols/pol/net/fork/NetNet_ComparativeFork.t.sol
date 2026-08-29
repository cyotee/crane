// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNetFork} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNetFork.sol";
import {NetNet_ComparativeScenarios} from
    "@crane/contracts/protocols/pol/net/test/bases/NetNet_ComparativeScenarios.sol";
import {BondDepository} from "@crane/contracts/protocols/pol/net/src/BondDepository.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";

contract NetNet_ComparativeFork_Test is TestBase_NetNetFork {
    function test_live_invariants() public view {
        NetNet_ComparativeScenarios.assertFot500Bps(net);
        NetNet_ComparativeScenarios.assertTaxedPair(net, address(pair));
        NetNet_ComparativeScenarios.assertSNetBacked(staking, sNet);
        NetNet_ComparativeScenarios.assertBondPriceMaxDiscountedTwapOrBacking(
            bondDepository, oracle, treasury
        );
        NetNet_ComparativeScenarios.assertTurboTargetLtv();
        NetNet_ComparativeScenarios.assertPTeamStrike(pTeam);
    }

    function test_live_selectors() public {
        vm.expectRevert(NetNet_ComparativeScenarios.selectorZeroAmountBond());
        bondDepository.deposit(0, 0, type(uint256).max, address(this));

        vm.expectRevert(TurboRouter.ZeroAmount.selector);
        turboRouter.turbo(0, 0, 0);

        assertEq(
            uint32(NetNet_ComparativeScenarios.selectorNotHolder()), uint32(PTeam.NotHolder.selector)
        );
        assertEq(
            uint32(NetNet_ComparativeScenarios.selectorZeroAmountBond()),
            uint32(BondDepository.ZeroAmount.selector)
        );
    }
}
