// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC-20 event definitions.
 * @notice Use this interface in contracts that need to emit ERC-20 events but don't inherit
 *         from a base ERC-20 implementation (like Solady's ERC20). Contracts that inherit
 *         from crane's ERC20 or Solady's ERC20 should NOT use this interface as those
 *         implementations already define these events.
 */
interface IERC20Events {
    /**
     * @dev Emitted when `amount` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
