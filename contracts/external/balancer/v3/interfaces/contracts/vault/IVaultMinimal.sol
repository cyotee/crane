// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/// @notice Minimal IVault surface needed by RouterWethLib.
interface IVaultMinimal {
    function settle(IERC20 token, uint256 amount) external;
    function sendTo(IERC20 token, address to, uint256 amount) external;
}
