// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IInverseBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IInverseBond.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_IInverseBond[]
/**
 * @title Behavior_IInverseBond
 * @notice Inverse bid price and active/error helpers.
 */
library Behavior_IInverseBond {
    function _Behavior_IInverseBondName() internal pure returns (string memory) {
        return type(Behavior_IInverseBond).name;
    }

    // tag::expected_IInverseBond_price[]
    function expected_IInverseBond_price(ITreasury treasury) internal view returns (uint256) {
        return treasury.backingPerToken() * (Constants.BPS - Constants.INVERSE_SPREAD_BPS) / Constants.BPS;
    }
    // end::expected_IInverseBond_price[]

    // tag::isValid_IInverseBond_price[]
    function isValid_IInverseBond_price(IInverseBond subject, uint256 expected)
        internal
        view
        returns (bool)
    {
        return subject.price() == expected;
    }
    // end::isValid_IInverseBond_price[]

    // tag::isValid_IInverseBond_active[]
    function isValid_IInverseBond_active(IInverseBond subject, bool expected)
        internal
        view
        returns (bool)
    {
        return subject.active() == expected;
    }
    // end::isValid_IInverseBond_active[]
}
// end::Behavior_IInverseBond[]
