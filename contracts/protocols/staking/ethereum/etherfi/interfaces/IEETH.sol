// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IEETH
 * @notice ether.fi eETH (rebasing share token).
 * @dev Mainnet: 0x35fA164735182de50811E8e2E824cFb9B6118ac2
 */
interface IEETH is IERC20 {
    function shares(address user) external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function sharesToBalance(uint256 sharesAmount) external view returns (uint256);

    function balanceToShares(uint256 balance) external view returns (uint256);
}
