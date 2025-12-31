// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";

interface IBalancerV3RouterAware {
    function balancerV3Router() external view returns (IRouter router);
}
