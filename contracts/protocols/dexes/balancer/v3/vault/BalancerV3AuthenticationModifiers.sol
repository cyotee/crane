// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {BalancerV3AuthenticationService} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationService.sol";

abstract contract BalancerV3AuthenticationModifiers {
    /// @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
    modifier authenticate(address where) {
        BalancerV3AuthenticationService.authenticateCaller(where);
        _;
    }
}
