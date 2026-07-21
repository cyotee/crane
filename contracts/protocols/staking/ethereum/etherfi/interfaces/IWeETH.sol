// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IWeETH
 * @notice ether.fi wrapped eETH.
 * @dev Mainnet: 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee
 */
interface IWeETH is IERC20 {
    function eETH() external view returns (address);

    function wrap(uint256 eETHAmount) external returns (uint256);

    function unwrap(uint256 weETHAmount) external returns (uint256);

    function getRate() external view returns (uint256);

    function getEETHByWeETH(uint256 weETHAmount) external view returns (uint256);

    function getWeETHByeETH(uint256 eETHAmount) external view returns (uint256);
}
