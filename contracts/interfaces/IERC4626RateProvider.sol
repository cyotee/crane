// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { BetterIERC20 as IERC20 } from "@crane/contracts/interfaces/BetterIERC20.sol";

interface IERC4626RateProvider is IRateProvider {

    function erc4626Vault() external view returns (IERC4626);

}