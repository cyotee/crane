// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

// NOTE: IERC20Events removed because implementations inherit from ERC20 which has these events.
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    // IERC20 functions are inherited via IERC20.
}
