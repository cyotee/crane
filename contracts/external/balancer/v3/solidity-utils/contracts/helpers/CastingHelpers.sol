// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/// @notice Library of helper functions related to typecasting arrays.
/// @dev Vendored from Balancer V3 Solidity Utils.
library CastingHelpers {
    /// @dev Returns a native array of addresses as an IERC20[] array.
    function asIERC20(address[] memory addresses) internal pure returns (IERC20[] memory tokens) {
        assembly ("memory-safe") {
            tokens := addresses
        }
    }

    /// @dev Returns an IERC20[] array as an address[] array.
    function asAddress(IERC20[] memory tokens) internal pure returns (address[] memory addresses) {
        assembly ("memory-safe") {
            addresses := tokens
        }
    }
}
