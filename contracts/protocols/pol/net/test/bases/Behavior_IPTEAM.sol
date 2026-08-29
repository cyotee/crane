// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_IPTEAM[]
/**
 * @title Behavior_IPTEAM
 * @notice Strike, vest, NotHolder / ExceedsVestedCap helpers.
 */
library Behavior_IPTEAM {
    function _Behavior_IPTEAMName() internal pure returns (string memory) {
        return type(Behavior_IPTEAM).name;
    }

    // tag::isValid_IPTEAM_strike[]
    function isValid_IPTEAM_strike(IPTEAM subject) internal view returns (bool) {
        return subject.strikeWad() == Constants.PTEAM_STRIKE_WAD;
    }
    // end::isValid_IPTEAM_strike[]

    // tag::selector_IPTEAM_NotHolder[]
    function selector_IPTEAM_NotHolder() internal pure returns (bytes4) {
        return PTeam.NotHolder.selector;
    }
    // end::selector_IPTEAM_NotHolder[]

    // tag::selector_IPTEAM_ExceedsVestedCap[]
    function selector_IPTEAM_ExceedsVestedCap() internal pure returns (bytes4) {
        return PTeam.ExceedsVestedCap.selector;
    }
    // end::selector_IPTEAM_ExceedsVestedCap[]
}
// end::Behavior_IPTEAM[]
