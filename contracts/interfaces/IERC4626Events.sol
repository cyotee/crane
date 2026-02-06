// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC-4626 event definitions.
 * @notice Use this interface in contracts that need to emit ERC-4626 events but don't inherit
 *         from a base ERC-4626 implementation (like Solady's ERC4626). Contracts that inherit
 *         from crane's ERC4626 or Solady's ERC4626 should NOT use this interface as those
 *         implementations already define these events.
 */
interface IERC4626Events {
    /**
     * @dev Emitted when tokens are deposited into the vault.
     */
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @dev Emitted when tokens are withdrawn from the vault.
     */
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
}
