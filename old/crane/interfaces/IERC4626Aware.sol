// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "./BetterIERC20.sol";

interface IERC4626Aware {
    function erc4626Wrapper() external view returns (IERC4626);

    function underlying() external view returns (IERC20);
}
