// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {UInt256Set, UInt256SetRepo} from "@crane/contracts/utils/collections/sets/UInt256SetRepo.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";

library ERC721Repo {
    using UInt256SetRepo for UInt256Set;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.erc.721"));

    struct Storage {
        uint256 nextTokenId;
        UInt256Set allTokenIds;
        mapping(uint256 tokenId => address) ownerOfTokenId;
        mapping(address owner => uint256) balanceOfAccount;
        mapping(uint256 tokenId => address) approvedForTokenId;
        mapping(address owner => mapping(address operator => bool)) operatorApprovals;
    }

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _balanceOf(Storage storage layout_, address owner) internal view returns (uint256) {
        return layout_.balanceOfAccount[owner];
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _balanceOf(_layout(), owner);
    }

    function _ownerOf(Storage storage layout_, uint256 tokenId) internal view returns (address) {
        return layout_.ownerOfTokenId[tokenId];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _ownerOf(_layout(), tokenId);
    }

    function _safeTransferFrom(
        Storage storage layout_,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 response) {
                if (response != IERC721Receiver.onERC721Received.selector) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch {
                revert IERC721Errors.ERC721InvalidReceiver(to);
            }
        }
        _transferFrom(layout_, from, to, tokenId);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        _safeTransferFrom(_layout(), from, to, tokenId, data);
    }

    function _safeTransferFrom(Storage storage layout_, address from, address to, uint256 tokenId) internal {
        _safeTransferFrom(layout_, from, to, tokenId, "");
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId) internal {
        _safeTransferFrom(_layout(), from, to, tokenId, "");
    }

    function _transferFrom(Storage storage layout_, address from, address to, uint256 tokenId) internal {
        if (from == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(from);
        }
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to);
        }
        if (!layout_.allTokenIds._contains(tokenId)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
        address owner = layout_.ownerOfTokenId[tokenId];
        if (owner != from) {
            revert IERC721Errors.ERC721IncorrectOwner(from, tokenId, owner);
        }
        if (
            from != address(msg.sender) && layout_.approvedForTokenId[tokenId] != msg.sender
                && !layout_.operatorApprovals[from][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        delete layout_.approvedForTokenId[tokenId];
        layout_.ownerOfTokenId[tokenId] = to;
        layout_.balanceOfAccount[from]--;
        layout_.balanceOfAccount[to]++;
        emit IERC721.Transfer(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        _transferFrom(_layout(), from, to, tokenId);
    }

    function _approve(Storage storage layout_, address operator, uint256 tokenId) internal {
        if (operator == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator);
        }
        address owner = _ownerOf(layout_, tokenId);
        if (owner != msg.sender) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, tokenId, owner);
        }
        layout_.approvedForTokenId[tokenId] = operator;
        emit IERC721.Approval(owner, operator, tokenId);
    }

    function _approve(address operator, uint256 tokenId) internal {
        _approve(_layout(), operator, tokenId);
    }

    function _setApprovalForAll(Storage storage layout_, address operator, bool approved) internal {
        if (operator == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator);
        }
        layout_.operatorApprovals[msg.sender][operator] = approved;
        emit IERC721.ApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        _setApprovalForAll(_layout(), operator, approved);
    }

    function _getApproved(Storage storage layout_, uint256 tokenId) internal view returns (address) {
        return layout_.approvedForTokenId[tokenId];
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        return _getApproved(_layout(), tokenId);
    }

    function _isApprovedForAll(Storage storage layout_, address owner, address operator)
        internal
        view
        returns (bool)
    {
        return layout_.operatorApprovals[owner][operator];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _isApprovedForAll(_layout(), owner, operator);
    }

    function _mint(Storage storage layout_, address to) internal returns (uint256 tokenId) {
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to);
        }
        tokenId = layout_.nextTokenId++;
        layout_.allTokenIds._add(tokenId);
        layout_.ownerOfTokenId[tokenId] = to;
        layout_.balanceOfAccount[to]++;
        emit IERC721.Transfer(address(0), to, tokenId);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        return _mint(_layout(), to);
    }

    function _burn(Storage storage layout_, address owner, uint256 tokenId) internal {
        if (!layout_.allTokenIds._contains(tokenId)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
        // address owner = layout_.ownerOfTokenId[tokenId];
        if (
            owner != address(msg.sender) && layout_.approvedForTokenId[tokenId] != msg.sender
                && !layout_.operatorApprovals[owner][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        delete layout_.ownerOfTokenId[tokenId];
        delete layout_.approvedForTokenId[tokenId];
        layout_.allTokenIds._remove(tokenId);
        layout_.balanceOfAccount[owner]--;
        emit IERC721.Transfer(owner, address(0), tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        _burn(_layout(), owner, tokenId);
    }

    function _burn(Storage storage layout_, uint256 tokenId) internal {
        address owner = layout_.ownerOfTokenId[tokenId];
        _burn(layout_, owner, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(_layout(), tokenId);
    }
}
