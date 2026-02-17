// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../ERC20.sol";
import {IERC20} from "../IERC20.sol";
import {SafeERC20} from "../../../utils/SafeERC20.sol";

abstract contract ERC20Wrapper is ERC20 {
    IERC20 public underlying;
    uint256 private underlyingBalance;

    function deposit(uint256 amount) external virtual returns (uint256);
    function withdraw(uint256 shares) external virtual returns (uint256);
    function _deposit(address from, uint256 amount) internal virtual;
    function _withdraw(address to, uint256 shares) internal virtual;
}
