// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IWstETH
 * @notice Canonical Lido wrapped stETH interface.
 * @dev Mainnet: 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
 *      Does not replace Pendle/Liquity fragments yet (follow-on cleanup).
 */
interface IWstETH is IERC20 {
    function stETH() external view returns (address);

    function wrap(uint256 stETHAmount) external returns (uint256);

    function unwrap(uint256 wstETHAmount) external returns (uint256);

    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);

    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);

    function tokensPerStEth() external view returns (uint256);
}
