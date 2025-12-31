// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";

/**
 * @title Behavior_IERC721
 * @notice Behavior comparators for IERC721 interface testing
 * @dev Provides assertion helpers for verifying ERC721 behavior
 */
library Behavior_IERC721 {

    /**
     * @notice Verify balanceOf returns expected value
     */
    function isValid_balanceOf(
        IERC721 token,
        address owner,
        uint256 expectedBalance
    ) internal view returns (bool) {
        return token.balanceOf(owner) == expectedBalance;
    }

    /**
     * @notice Verify ownerOf returns expected value
     */
    function isValid_ownerOf(
        IERC721 token,
        uint256 tokenId,
        address expectedOwner
    ) internal view returns (bool) {
        return token.ownerOf(tokenId) == expectedOwner;
    }

    /**
     * @notice Verify getApproved returns expected value
     */
    function isValid_getApproved(
        IERC721 token,
        uint256 tokenId,
        address expectedApproved
    ) internal view returns (bool) {
        return token.getApproved(tokenId) == expectedApproved;
    }

    /**
     * @notice Verify isApprovedForAll returns expected value
     */
    function isValid_isApprovedForAll(
        IERC721 token,
        address owner,
        address operator,
        bool expectedApproval
    ) internal view returns (bool) {
        return token.isApprovedForAll(owner, operator) == expectedApproval;
    }

    /**
     * @notice Verify a transfer updated balances correctly
     */
    function isValid_transfer(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 fromBalanceBefore,
        uint256 toBalanceBefore
    ) internal view returns (bool) {
        // Owner should have changed
        if (token.ownerOf(tokenId) != to) return false;

        // Balance of from should have decreased by 1
        if (token.balanceOf(from) != fromBalanceBefore - 1) return false;

        // Balance of to should have increased by 1 (unless from == to)
        if (from != to) {
            if (token.balanceOf(to) != toBalanceBefore + 1) return false;
        }

        // Approval should have been cleared
        if (token.getApproved(tokenId) != address(0)) return false;

        return true;
    }

    /**
     * @notice Verify approval was set correctly
     */
    function isValid_approve(
        IERC721 token,
        uint256 tokenId,
        address expectedApproved
    ) internal view returns (bool) {
        return token.getApproved(tokenId) == expectedApproved;
    }

    /**
     * @notice Verify setApprovalForAll was set correctly
     */
    function isValid_setApprovalForAll(
        IERC721 token,
        address owner,
        address operator,
        bool expectedApproval
    ) internal view returns (bool) {
        return token.isApprovedForAll(owner, operator) == expectedApproval;
    }
}
