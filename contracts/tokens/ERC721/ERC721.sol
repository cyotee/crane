// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721 as SoladyERC721} from "@crane/contracts/solady/tokens/ERC721.sol";

/**
 * @title ERC721
 * @author Crane
 * @dev Implementation of ERC721 Non-Fungible Token Standard using Solady's gas-optimized implementation
 *      with OpenZeppelin-compatible API.
 * @notice This contract wraps Solady's ERC721 to provide a familiar OZ-like API while benefiting
 *         from Solady's gas optimizations. Events (Transfer, Approval, ApprovalForAll) are inherited
 *         from Solady's ERC721.
 */
abstract contract ERC721 is SoladyERC721 {
    string private _name;
    string private _symbol;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /* -------------------------------------------------------------------------- */
    /*                              IERC721Metadata                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /* -------------------------------------------------------------------------- */
    /*                        OZ-Compatible _approve                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Approve `to` to operate on `tokenId` (OZ-compatible 3-arg version).
     *
     * Note: This provides OpenZeppelin-compatible semantics where:
     * - `to` is the address being approved
     * - `tokenId` is the token to approve
     * - `auth` is the authorizer (zero address for unchecked approval)
     *
     * This differs from Solady's native `_approve(by, account, id)` where `by` is first.
     * We hide Solady's version and provide OZ semantics instead.
     */
    function _approve(address to, uint256 tokenId, address auth) internal virtual {
        // Solady signature: _approve(address by, address account, uint256 id)
        // OZ signature: _approve(address to, uint256 tokenId, address auth)
        // We call Solady with: by=auth, account=to, id=tokenId
        SoladyERC721._approve(auth, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId` (OZ-compatible 4-arg version with emit flag).
     *
     * This variant allows specifying whether to emit an Approval event.
     * Used by contracts that manage approvals in custom storage (like NonfungiblePositionManager).
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        if (emitEvent) {
            address owner = _ownerOf(tokenId);
            emit Approval(owner, to, tokenId);
        }
        // Note: This version doesn't actually store the approval in Solady's storage
        // as it's meant for custom storage implementations
    }

    /**
     * @dev Approve `to` to operate on `tokenId` (OZ-compatible 2-arg version).
     * Uses msg.sender as the authorizer.
     */
    function _approve(address to, uint256 tokenId) internal virtual override {
        SoladyERC721._approve(msg.sender, to, tokenId);
    }

    /**
     * @dev OZ-compatible internal update function for transfers, mints, and burns.
     *
     * In OpenZeppelin, _update handles:
     * - Mints (from = address(0))
     * - Transfers (from != address(0) && to != address(0))
     * - Burns (to = address(0))
     *
     * @param to The address receiving the token (address(0) for burns)
     * @param tokenId The token being transferred/minted/burned
     * @param auth The address performing the action (for authorization checks)
     * @return The previous owner of the token
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Handle authorization check if auth is not zero address
        if (auth != address(0)) {
            if (from != address(0) && from != auth && !isApprovedForAll(from, auth)) {
                address approvedAddr = _getApproved(tokenId);
                if (approvedAddr != auth) {
                    revert NotOwnerNorApproved();
                }
            }
        }

        // Call the hook
        _beforeTokenTransfer(from, to, tokenId);

        // Perform the actual transfer/mint/burn using Solady
        if (from == address(0)) {
            // Mint
            _mint(to, tokenId);
        } else if (to == address(0)) {
            // Burn
            _burn(tokenId);
        } else {
            // Transfer
            SoladyERC721._transfer(from, from, to, tokenId);
        }

        return from;
    }

    /**
     * @dev OZ-compatible function to increase an account's balance.
     * This is typically used during minting.
     *
     * Note: In Solady, balance is managed internally during _mint/_burn/_transfer.
     * This function is provided for compatibility but should be overridden if custom
     * balance tracking is needed.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        // In Solady, balance is automatically managed. This is a no-op placeholder
        // for contracts that need to override it for custom tracking.
        // Suppress unused variable warning
        (account, value);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        // Override in child contracts - calls Solady's hook
        SoladyERC721._beforeTokenTransfer(from, to, tokenId);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, override to set.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (hasn't been minted or has been burned).
     * Returns the owner.
     */
    function _requireOwned(uint256 tokenId) internal view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert TokenDoesNotExist();
        }
        return owner;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     *
     * This provides OpenZeppelin-compatible semantics for authorization checking.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // Max length of uint256 as decimal string is 78 digits
            str := add(mload(0x40), 0x80)
            mstore(0x40, str)
            let end := str
            // Iterate until value is 0
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }
}
