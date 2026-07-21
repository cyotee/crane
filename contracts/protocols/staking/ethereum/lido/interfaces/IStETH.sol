// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IStETH
 * @notice Canonical Lido stETH interface for mint (submit) and share math.
 * @dev Mainnet: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
 */
interface IStETH is IERC20 {
    function submit(address referral) external payable returns (uint256);

    function getPooledEthByShares(uint256 sharesAmount) external view returns (uint256);

    function getSharesByPooledEth(uint256 ethAmount) external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function getTotalShares() external view returns (uint256);
}
