// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3AuthenticationStorage} from "./BalancerV3AuthenticationStorage.sol";

contract BalancerV3AuthenticationModifiers is BalancerV3AuthenticationStorage {

    /// @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
    modifier authenticate(address where) {
        _authenticateCaller(where);
        _;
    }

}