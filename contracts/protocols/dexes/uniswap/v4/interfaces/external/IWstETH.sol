// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// https://github.com/lidofinance/core/blob/master/contracts/0.6.12/WstETH.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IWstETH - Wrapped Staked Ether interface
/// @notice Interface for the wstETH contract
/// @dev Ported from Uniswap V4 periphery for local compatibility
interface IWstETH {
    /// @notice Wraps stETH to wstETH
    /// @param _stETHAmount Amount of stETH to wrap
    /// @return Amount of wstETH received
    function wrap(uint256 _stETHAmount) external returns (uint256);

    /// @notice Unwraps wstETH to stETH
    /// @param _wstETHAmount Amount of wstETH to unwrap
    /// @return Amount of stETH received
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    /// @notice Get amount of stETH for a given amount of wstETH
    /// @param _wstETHAmount Amount of wstETH
    /// @return Amount of stETH
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);

    /// @notice Get amount of wstETH for a given amount of stETH
    /// @param _stETHAmount Amount of stETH
    /// @return Amount of wstETH
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);

    /// @notice Get the amount of tokens per stETH
    /// @return The current tokens per stETH ratio
    function tokensPerStEth() external view returns (uint256);

    /// @notice Get the amount of stETH per token
    /// @return The current stETH per token ratio
    function stEthPerToken() external view returns (uint256);

    /// @notice Get the address of the underlying stETH contract
    /// @return The stETH contract address
    function stETH() external view returns (address);
}

/// @title IStETH - Staked Ether interface
/// @notice Interface for the stETH contract
interface IStETH {
    /// @notice Get shares for a given amount of stETH
    /// @param stEthAmount Amount of stETH
    /// @return Number of shares
    function getSharesByPooledEth(uint256 stEthAmount) external view returns (uint256);

    /// @notice Get stETH for a given number of shares
    /// @param _sharesAmount Number of shares
    /// @return Amount of stETH
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    /// @notice Get shares held by an account
    /// @param _account The account address
    /// @return Number of shares
    function sharesOf(address _account) external view returns (uint256);

    /// @notice Transfer shares to a recipient
    /// @param recipient The recipient address
    /// @param shares Number of shares to transfer
    function transferShares(address recipient, uint256 shares) external;

    /// @notice Get balance of an account
    /// @param _account The account address
    /// @return Balance in stETH
    function balanceOf(address _account) external view returns (uint256);
}
