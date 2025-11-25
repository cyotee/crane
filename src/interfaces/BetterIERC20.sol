// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// tag::BetterIERC20[]
/**
 * @title ERC20 interface
 * @author who?
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @notice Composes IERC20Errors and IERC20Metadata.
 */
interface BetterIERC20 is IERC20Errors, IERC20Metadata {}
// end::BetterIERC20[]
