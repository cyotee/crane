// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IAuthentication} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";

contract BalancerV3AuthenticationTarget is IAuthentication {
    /// @inheritdoc IAuthentication
    function getActionId(bytes4 selector) public view returns (bytes32) {
        return BalancerV3AuthenticationRepo._getActionId(selector);
    }
}
