// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IPremiumSeller} from "@crane/contracts/protocols/pol/net/src/interfaces/IPremiumSeller.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_IPremiumSeller[]
/**
 * @title Behavior_IPremiumSeller
 * @notice Premium threshold and clip helpers.
 */
library Behavior_IPremiumSeller {
    function _Behavior_IPremiumSellerName() internal pure returns (string memory) {
        return type(Behavior_IPremiumSeller).name;
    }

    // tag::isValid_IPremiumSeller_threshold[]
    function isValid_IPremiumSeller_threshold(IPremiumSeller subject) internal view returns (bool) {
        return subject.premiumThresholdWad() == Constants.PREMIUM_THRESHOLD_WAD;
    }
    // end::isValid_IPremiumSeller_threshold[]

    // tag::isValid_IPremiumSeller_active[]
    function isValid_IPremiumSeller_active(IPremiumSeller subject, bool expected)
        internal
        view
        returns (bool)
    {
        return subject.active() == expected;
    }
    // end::isValid_IPremiumSeller_active[]
}
// end::Behavior_IPremiumSeller[]
