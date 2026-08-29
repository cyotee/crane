// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";

// tag::Behavior_INET[]
/**
 * @title Behavior_INET
 * @notice FoT bps, taxed-pair, and TaxCollected validation for NET.
 */
library Behavior_INET {
    function _Behavior_INETName() internal pure returns (string memory) {
        return type(Behavior_INET).name;
    }

    // tag::isValid_INET_taxTotalBps[]
    function isValid_INET_taxTotalBps(INET subject, uint256 actual)
        internal
        pure
        returns (bool valid)
    {
        valid = actual == Constants.TAX_TOTAL_BPS;
        if (!valid) subject;
    }
    // end::isValid_INET_taxTotalBps[]

    // tag::isValid_INET_isTaxedPair[]
    function isValid_INET_isTaxedPair(INET subject, address pair, bool expected, bool actual)
        internal
        pure
        returns (bool valid)
    {
        valid = expected == actual;
        if (!valid) {
            subject;
            pair;
        }
    }
    // end::isValid_INET_isTaxedPair[]

    // tag::isValid_INET_fotBps[]
    /// @notice Tax withheld equals `amountSent * TAX_TOTAL_BPS / BPS`.
    function isValid_INET_fotBps(uint256 amountSent, uint256 taxWithheld)
        internal
        pure
        returns (bool valid)
    {
        valid = taxWithheld == amountSent * Constants.TAX_TOTAL_BPS / Constants.BPS;
    }
    // end::isValid_INET_fotBps[]

    // tag::isValid_INET_untaxedTransfer[]
    function isValid_INET_untaxedTransfer(uint256 amountSent, uint256 amountReceived)
        internal
        pure
        returns (bool valid)
    {
        valid = amountSent == amountReceived;
    }
    // end::isValid_INET_untaxedTransfer[]
}
// end::Behavior_INET[]
