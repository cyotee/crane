// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";

// tag::BetterIERC20[]
/**
 * @title BetterIERC20 - Composed ERC20 Interface
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice ERC20 token standard interface composed with metadata queries (name, symbol, decimals) and standardized custom errors for consistent revert handling across Crane.
 * @dev This interface composes the full ERC20 surface by inheriting IERC20 (transitively via IERC20Metadata), IERC20Metadata, and IERC20Errors. It serves as the canonical ERC20 declaration used by Crane's token facets (e.g. ERC20Facet/Target), DFPkgs, and protocol integrations (DEX quotes, vaults, etc.).
 *      No direct function/event/error declarations exist in this file; all members are inherited.
 *      Follows gold interface style (IPermit2Aware.sol, IReentrancyLock.sol, IMultiStepOwnable.sol, IOperable.sol).
 *      No @custom:interfaceid / @custom:selector / @custom:signature / @custom:topiczero present because CENTRALLY_COMPUTED_NATSPEC_VALUES.md contains no entries for BetterIERC20 or surfaced ERC20 symbols (prose only; values populated centrally in follow-up pass if needed; do not fabricate).
 */
interface BetterIERC20 is IERC20Errors, IERC20Metadata {}
// end::BetterIERC20[]
