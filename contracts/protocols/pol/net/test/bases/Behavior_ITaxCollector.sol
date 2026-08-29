// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {ITaxCollector} from "@crane/contracts/protocols/pol/net/src/interfaces/ITaxCollector.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_ITaxCollector[]
/**
 * @title Behavior_ITaxCollector
 * @notice Convert split vs TAX_TEAM_START_BPS (400) decaying with pTEAM vest.
 */
library Behavior_ITaxCollector {
    function _Behavior_ITaxCollectorName() internal pure returns (string memory) {
        return type(Behavior_ITaxCollector).name;
    }

    // tag::expected_ITaxCollector_teamBps[]
    function expected_ITaxCollector_teamBps(IPTEAM pteam) internal view returns (uint256) {
        uint256 v = pteam.vestedFraction();
        return Constants.TAX_TEAM_START_BPS * (Constants.WAD - v) / Constants.WAD;
    }
    // end::expected_ITaxCollector_teamBps[]

    // tag::isValid_ITaxCollector_teamBps[]
    function isValid_ITaxCollector_teamBps(ITaxCollector subject, uint256 expected)
        internal
        view
        returns (bool)
    {
        return subject.teamBps() == expected;
    }
    // end::isValid_ITaxCollector_teamBps[]

    // tag::isValid_ITaxCollector_convertSplit[]
    function isValid_ITaxCollector_convertSplit(
        uint256 usdgOut,
        uint256 teamBps,
        uint256 teamShare,
        uint256 treasuryShare
    ) internal pure returns (bool) {
        uint256 expectTeam = usdgOut * teamBps / Constants.TAX_TOTAL_BPS;
        return teamShare == expectTeam && treasuryShare == usdgOut - expectTeam;
    }
    // end::isValid_ITaxCollector_convertSplit[]
}
// end::Behavior_ITaxCollector[]
