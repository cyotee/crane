// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@crane/contracts/external/openzeppelin-upgradeable-v4/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@crane/contracts/external/openzeppelin-upgradeable-v4/token/ERC20/IERC20Upgradeable.sol";

interface IwstETH is IERC20PermitUpgradeable, IERC20Upgradeable {

    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

}
