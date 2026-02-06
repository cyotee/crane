// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC721Repo} from "@crane/contracts/tokens/ERC721/ERC721Repo.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";

/**
 * @title ERC721Target
 * @notice Base target implementation for ERC721 tokens
 * @dev Delegates all operations to ERC721Repo
 */
contract ERC721Target is IERC721 {

    /* -------------------------------------------------------------------------- */
    /*                              IERC721 Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        return ERC721Repo._balanceOf(owner);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public payable virtual {
        ERC721Repo._approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        ERC721Repo._setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return ERC721Repo._isApprovedForAll(owner, operator);
    }
}
