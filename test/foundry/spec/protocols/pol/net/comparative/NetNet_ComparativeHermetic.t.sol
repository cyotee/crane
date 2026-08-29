// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNet} from "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {NetNet_ComparativeScenarios} from
    "@crane/contracts/protocols/pol/net/test/bases/NetNet_ComparativeScenarios.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {BondDepository} from "@crane/contracts/protocols/pol/net/src/BondDepository.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";

contract NetNet_ComparativeHermetic_Test is TestBase_NetNet {
    function test_invariants_fot_stake_bond_turbo() public view {
        NetNet_ComparativeScenarios.assertFot500Bps(INET(address(net)));
        NetNet_ComparativeScenarios.assertTaxedPair(INET(address(net)), address(pair));
        NetNet_ComparativeScenarios.assertSNetBacked(staking, IsNET(address(sNet)));
        NetNet_ComparativeScenarios.assertBondPriceMaxDiscountedTwapOrBacking(
            bondDepository, oracle, treasury
        );
        NetNet_ComparativeScenarios.assertTurboTargetLtv();
        NetNet_ComparativeScenarios.assertPTeamStrike(pTeam);
    }

    function test_selectors_zero_not_holder_above_ltv() public {
        vm.expectRevert(NetNet_ComparativeScenarios.selectorZeroAmountBond());
        bondDepository.deposit(0, 0, type(uint256).max, address(this));

        address rando = makeAddr("cmpNotHolder");
        vm.prank(rando);
        vm.expectRevert(NetNet_ComparativeScenarios.selectorNotHolder());
        pTeam.exercise(1);

        vm.expectRevert(TurboRouter.ZeroAmount.selector);
        turboRouter.turbo(0, 0, 0);

        assertEq(
            uint32(NetNet_ComparativeScenarios.selectorAboveTargetLtv()),
            uint32(TurboRouter.AboveTargetLtv.selector)
        );
        assertEq(uint32(NetNet_ComparativeScenarios.selectorNotHolder()), uint32(PTeam.NotHolder.selector));
        assertEq(
            uint32(NetNet_ComparativeScenarios.selectorZeroAmountBond()),
            uint32(BondDepository.ZeroAmount.selector)
        );
    }
}
