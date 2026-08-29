// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {BondDepository} from "@crane/contracts/protocols/pol/net/src/BondDepository.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";
import {Staking} from "@crane/contracts/protocols/pol/net/src/Staking.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {LendingConstants} from "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {Behavior_INET} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_INET.sol";
import {Behavior_IStaking} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_IStaking.sol";
import {Behavior_IBondDepository} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_IBondDepository.sol";
import {Behavior_IPTEAM} from "@crane/contracts/protocols/pol/net/test/bases/Behavior_IPTEAM.sol";
import {Behavior_ITurboRouter} from
    "@crane/contracts/protocols/pol/net/test/bases/Behavior_ITurboRouter.sol";

/**
 * @title NetNet_ComparativeScenarios
 * @notice Shared invariant + revert-selector helpers for hermetic and fork comparative specs.
 * @dev No `assertEq(portOut, forkOut)` for market-dependent amounts.
 */
library NetNet_ComparativeScenarios {
    function assertFot500Bps(INET netToken) internal view {
        require(Behavior_INET.isValid_INET_taxTotalBps(netToken, netToken.taxTotalBps()), "FoT 500");
    }

    function assertTaxedPair(INET netToken, address pair) internal view {
        require(
            Behavior_INET.isValid_INET_isTaxedPair(netToken, pair, true, netToken.isTaxedPair(pair)),
            "canonical pair taxed"
        );
    }

    function assertStakeUnstakeOneToOne(uint256 netIn, uint256 sOut, uint256 sIn, uint256 netOut)
        internal
        pure
    {
        require(Behavior_IStaking.isValid_IStaking_stakeOneToOne(netIn, sOut), "stake 1:1");
        require(Behavior_IStaking.isValid_IStaking_unstakeOneToOne(sIn, netOut), "unstake 1:1");
    }

    function assertSNetBacked(IStaking staking, IsNET sNet) internal view {
        require(Behavior_IStaking.isValid_IStaking_totalStakedBacksSNet(staking, sNet), "sNET 1:1 backing");
    }

    function assertBondPriceMaxDiscountedTwapOrBacking(
        IBondDepository bonds,
        IPairOracle oracle,
        ITreasury treasury
    ) internal view {
        uint256 expected = Behavior_IBondDepository.expected_IBondDepository_bondPrice(oracle, treasury);
        require(Behavior_IBondDepository.isValid_IBondDepository_bondPrice(bonds, 0, expected), "bond price");
    }

    function assertTurboTargetLtv() internal pure {
        require(
            Behavior_ITurboRouter.isValid_ITurboRouter_targetLtv(LendingConstants.TARGET_LTV_WAD),
            "target LTV"
        );
    }

    function selectorZeroAmountBond() internal pure returns (bytes4) {
        return BondDepository.ZeroAmount.selector;
    }

    function selectorNotEnabledStaking() internal pure returns (bytes4) {
        return Staking.NotEnabled.selector;
    }

    function selectorNotHolder() internal pure returns (bytes4) {
        return Behavior_IPTEAM.selector_IPTEAM_NotHolder();
    }

    function selectorAboveTargetLtv() internal pure returns (bytes4) {
        return Behavior_ITurboRouter.selector_ITurboRouter_AboveTargetLtv();
    }

    function assertPTeamStrike(IPTEAM pteam) internal view {
        require(Behavior_IPTEAM.isValid_IPTEAM_strike(pteam), "pTEAM strike");
    }
}
