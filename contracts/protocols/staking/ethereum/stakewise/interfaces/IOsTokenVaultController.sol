// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IOsTokenVaultController
 * @notice StakeWise OsTokenVaultController — rate / convert helpers for osETH.
 * @dev Mainnet: 0x2A261e60FB14586B474C208b1B7AC6D0f5000306
 */
interface IOsTokenVaultController {
    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function avgRewardPerSecond() external view returns (uint256);

    function cumulativeFeePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalShares() external view returns (uint256);
}
