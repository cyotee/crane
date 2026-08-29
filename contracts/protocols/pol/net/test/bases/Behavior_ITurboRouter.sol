// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";
import {LendingConstants} from "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";

// tag::Behavior_ITurboRouter[]
/**
 * @title Behavior_ITurboRouter
 * @notice Target LTV and AboveTargetLtv selector helpers. Named for the dumped Turbo surface.
 */
library Behavior_ITurboRouter {
    function _Behavior_ITurboRouterName() internal pure returns (string memory) {
        return type(Behavior_ITurboRouter).name;
    }

    // tag::isValid_ITurboRouter_targetLtv[]
    function isValid_ITurboRouter_targetLtv(uint256 target) internal pure returns (bool) {
        return target == LendingConstants.TARGET_LTV_WAD;
    }
    // end::isValid_ITurboRouter_targetLtv[]

    // tag::selector_ITurboRouter_AboveTargetLtv[]
    function selector_ITurboRouter_AboveTargetLtv() internal pure returns (bytes4) {
        return TurboRouter.AboveTargetLtv.selector;
    }
    // end::selector_ITurboRouter_AboveTargetLtv[]

    // tag::selector_ITurboRouter_ZeroAmount[]
    function selector_ITurboRouter_ZeroAmount() internal pure returns (bytes4) {
        return TurboRouter.ZeroAmount.selector;
    }
    // end::selector_ITurboRouter_ZeroAmount[]
}
// end::Behavior_ITurboRouter[]
