// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_IBondDepository[]
/**
 * @title Behavior_IBondDepository
 * @notice Bond price = max(discounted TWAP, backing) and vest helpers.
 */
library Behavior_IBondDepository {
    function _Behavior_IBondDepositoryName() internal pure returns (string memory) {
        return type(Behavior_IBondDepository).name;
    }

    // tag::expected_IBondDepository_bondPrice[]
    function expected_IBondDepository_bondPrice(IPairOracle oracle, ITreasury treasury)
        internal
        view
        returns (uint256)
    {
        uint256 discounted =
            oracle.twapNetUsdg() * (Constants.BPS - Constants.BOND_DISCOUNT_BPS) / Constants.BPS;
        uint256 backing = treasury.backingPerToken();
        return discounted > backing ? discounted : backing;
    }
    // end::expected_IBondDepository_bondPrice[]

    // tag::isValid_IBondDepository_bondPrice[]
    function isValid_IBondDepository_bondPrice(IBondDepository subject, uint256 marketId, uint256 expected)
        internal
        view
        returns (bool)
    {
        return subject.bondPrice(marketId) == expected;
    }
    // end::isValid_IBondDepository_bondPrice[]

    // tag::isValid_IBondDepository_vestLinear[]
    function isValid_IBondDepository_vestLinear(uint256 payout, uint256 elapsed, uint256 vested)
        internal
        pure
        returns (bool)
    {
        uint256 expect =
            elapsed >= Constants.BOND_VEST ? payout : payout * elapsed / Constants.BOND_VEST;
        return vested == expect;
    }
    // end::isValid_IBondDepository_vestLinear[]
}
// end::Behavior_IBondDepository[]
