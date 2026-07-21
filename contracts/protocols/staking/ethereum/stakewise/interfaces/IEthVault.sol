// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IEthVault
 * @notice StakeWise V3 EthVault deposit/redeem surface (ERC-4626-like).
 * @dev Genesis / public vaults on mainnet; pin per README.
 */
interface IEthVault is IERC20 {
    function deposit(address receiver, address referrer) external payable returns (uint256 shares);

    function redeem(uint256 shares, address receiver) external returns (uint256 assets);

    function enterExitQueue(uint256 shares, address receiver) external returns (uint256 positionTicket);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function vaultId() external pure returns (bytes32);

    function version() external pure returns (uint8);

    function capacity() external view returns (uint256);
}
