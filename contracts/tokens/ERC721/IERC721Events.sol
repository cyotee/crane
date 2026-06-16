// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC-721 event definitions.
 * @notice Use this interface in contracts that need to emit ERC-721 events but don't inherit
 *         from a base ERC-721 implementation (like Solady's ERC721). Contracts that inherit
 *         from crane's ERC721 or Solady's ERC721 should NOT use this interface as those
 *         implementations already define these events.
 */
// tag::IERC721Events[]
/**
 * @title IERC721Events
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Companion interface holding ERC-721 events with rich NatSpec for LR-1.
 * @dev Events are defined here (not in IERC721) to avoid duplicate definition conflicts
 *      with base implementations (Solady etc.) that declare the same events.
 *      @custom:interfaceid is on IERC721 (0x80ac58cd).
 */
interface IERC721Events {
    // tag::Transfer(address-address-uint256)[]
    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from The address the token is transferred from.
     * @param to The address the token is transferred to.
     * @param tokenId The identifier of the token being transferred.
     * @custom:topic-signature Transfer(address,address,uint256)
     * @custom:topiczero 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // end::Transfer(address-address-uint256)[]

    // tag::Approval(address-address-uint256)[]
    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     * @param owner The address of the token owner.
     * @param approved The address approved to manage the token.
     * @param tokenId The identifier of the token.
     * @custom:topic-signature Approval(address,address,uint256)
     * @custom:topiczero 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // end::Approval(address-address-uint256)[]

    // tag::ApprovalForAll(address-address-bool)[]
    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     * @param owner The address of the token owner.
     * @param operator The address of the approved operator.
     * @param approved Whether or not the operator is approved.
     * @custom:topic-signature ApprovalForAll(address,address,bool)
     * @custom:topiczero 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    // end::ApprovalForAll(address-address-bool)[]
}
// end::IERC721Events[]
