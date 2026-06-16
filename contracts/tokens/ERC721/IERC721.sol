// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721Events} from "@crane/contracts/interfaces/IERC721Events.sol";

/**
 * @dev Required interface of an ERC-721 compliant contract.
 * @notice Native Crane implementation - no external dependencies.
 * @dev Events live in IERC721Events (rich NatSpec + tags added for LR-1). This interface inherits them
 *      to avoid duplicate event definition errors with base impls (Solady etc.).
 */
// tag::IERC721[]
/**
 * @title IERC721 - Required interface of an ERC-721 compliant contract.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Native Crane implementation - no external dependencies.
 * @dev Events are inherited from IERC721Events (with rich NatSpec/tags for LR-1). Functions have
 *      full NatSpec plus selector/signature custom tags (see examples below). Original commented stubs preserved for reference.
 * @custom:interfaceid 0x80ac58cd
 */
interface IERC721 is IERC721Events {
    // Events are inherited from IERC721Events (rich NatSpec + tags live there to prevent duplicates).
    // Original commented stubs preserved for reference below (from pre-LR-1 source).

    // /**
    //  * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    //  */
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    //  */
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    //  */
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* -------------------------------------------------------------------------- */
    /*                                 Functions                                  */
    /* -------------------------------------------------------------------------- */

    // tag::balanceOf(address)[]
    /**
     * @notice Returns the number of tokens in `owner`'s account.
     * @dev Returns the number of tokens in ``owner``'s account.
     * @param owner address of the account to query
     * @return balance The number of tokens owned by the account.
     * @custom:selector 0x70a08231
     * @custom:signature balanceOf(address)
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    // end::balanceOf(address)[]

    // tag::ownerOf(uint256)[]
    /**
     * @notice Returns the owner of the `tokenId` token.
     * @dev Returns the owner of the `tokenId` token.eee
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * @param tokenId identifier of the token to query
     * @return owner address of the owner of the token.
     * @custom:selector 0x6352211e
     * @custom:signature ownerOf(uint256)
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // end::ownerOf(uint256)[]

    // tag::safeTransferFrom(address-address-uint256-bytes)[]
    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     * @param data additional data with no specified format, sent in call to `to`
     * @custom:selector 0xb88d4fde
     * @custom:signature safeTransferFrom(address,address,uint256,bytes)
     * @custom:emits Transfer(address,address,uint256)
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    // end::safeTransferFrom(address-address-uint256-bytes)[]

    // tag::safeTransferFrom(address-address-uint256)[]
    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     * @custom:selector 0x42842e0e
     * @custom:signature safeTransferFrom(address,address,uint256)
     * @custom:emits Transfer(address,address,uint256)
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    // end::safeTransferFrom(address-address-uint256)[]

    // tag::transferFrom(address-address-uint256)[]
    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     * @custom:selector 0x23b872dd
     * @custom:signature transferFrom(address,address,uint256)
     * @custom:emits Transfer(address,address,uint256)
     */
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    // end::transferFrom(address-address-uint256)[]

    // tag::approve(address-uint256)[]
    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     * @param to address to be approved for the given token ID
     * @param tokenId identifier of the token to be approved
     * @custom:selector 0x095ea7b3
     * @custom:signature approve(address,uint256)
     * @custom:emits Approval(address,address,uint256)
     */
    function approve(address to, uint256 tokenId) external payable;
    // end::approve(address-uint256)[]

    // tag::setApprovalForAll(address-bool)[]
    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     * @param operator address to add to the set of authorized operators
     * @param approved true if the operator is approved, false to revoke approval
     * @custom:selector 0xa22cb465
     * @custom:signature setApprovalForAll(address,bool)
     * @custom:emits ApprovalForAll(address,address,bool)
     */
    function setApprovalForAll(address operator, bool approved) external;
    // end::setApprovalForAll(address-bool)[]

    // tag::getApproved(uint256)[]
    /**
     * @notice Returns the account approved for `tokenId` token.
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * @param tokenId identifier of the token to query the approval of
     * @return operator address currently approved for the token
     * @custom:selector 0x081812fc
     * @custom:signature getApproved(uint256)
     */
    function getApproved(uint256 tokenId) external view returns (address operator);
    // end::getApproved(uint256)[]

    // tag::isApprovedForAll(address-address)[]
    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     * @param owner address of the owner of the assets
     * @param operator address of the approved operator
     * @return true if the operator is approved, false otherwise
     * @custom:selector 0xe985e9c5
     * @custom:signature isApprovedForAll(address,address)
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    // end::isApprovedForAll(address-address)[]
}
// end::IERC721[]
