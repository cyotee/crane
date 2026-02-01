// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMsgSender
/// @notice Interface for contracts that expose the original caller
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
interface IMsgSender {
    /// @notice Returns the address of the original caller (msg.sender)
    /// @dev Uniswap v4 periphery contracts implement a callback pattern which lose
    /// the original msg.sender caller context. This view function provides a way for
    /// integrating contracts (e.g. hooks) to access the original caller address.
    /// @return The address of the original caller
    function msgSender() external view returns (address);
}
