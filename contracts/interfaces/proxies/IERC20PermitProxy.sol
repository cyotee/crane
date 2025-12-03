// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
// import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {IERC2612} from "contracts/interfaces/IERC2612.sol";
import {BetterIERC20Permit} from "contracts/interfaces/BetterIERC20Permit.sol";

/**
 * @title BetterIERC20Permit
 * @author cyotee doge <doge.cyotee>
 * @dev Composes IERC5267 and ERC2612 as IERC20Permit.
 */
interface IERC20PermitProxy is BetterIERC20Permit {}
