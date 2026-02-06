// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC-721 event definitions.
 * @notice Use this interface in contracts that need to emit ERC-721 events but don't inherit
 *         from a base ERC-721 implementation (like Solady's ERC721). Contracts that inherit
 *         from crane's ERC721 or Solady's ERC721 should NOT use this interface as those
 *         implementations already define these events.
 */
interface IERC721Events {
    /**
     * @dev Emitted when token `id` is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /**
     * @dev Emitted when `owner` enables `account` to manage the `id` token.
     */
    event Approval(address indexed owner, address indexed account, uint256 indexed id);

    /**
     * @dev Emitted when `owner` enables or disables (`isApproved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);
}
