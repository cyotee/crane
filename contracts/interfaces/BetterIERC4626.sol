// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    CRANE                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "./BetterIERC20.sol";
import {IERC4626Errors} from "./IERC4626Errors.sol";

// tag::BetterIERC4626[]
interface BetterIERC4626 is IERC4626, IERC20, IERC4626Errors {

}
// end::BetterIERC4626[]