// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC721Receiver} from "@crane/contracts/interfaces/IERC721Receiver.sol";
import {IERC721Errors} from "@crane/contracts/tokens/ERC721/IERC721Errors.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {UInt256Set, UInt256SetRepo} from "@crane/contracts/utils/collections/sets/UInt256SetRepo.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {IERC721Events} from "@crane/contracts/interfaces/IERC721Events.sol";

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

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _balanceOf(Storage storage layoutStruct_, address owner) internal view returns (uint256) {
        return layoutStruct_.balanceOfAccount[owner];
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _balanceOf(_layoutStruct(), owner);
    }

    function _ownerOf(Storage storage layoutStruct_, uint256 tokenId) internal view returns (address) {
        return layoutStruct_.ownerOfTokenId[tokenId];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _ownerOf(_layoutStruct(), tokenId);
    }

    function _safeTransferFrom(Storage storage layoutStruct_, address from, address to, uint256 tokenId, bytes memory data)
        internal
    {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 response) {
                if (response != IERC721Receiver.onERC721Received.selector) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch {
                revert IERC721Errors.ERC721InvalidReceiver(to);
            }
        }
        _transferFrom(layoutStruct_, from, to, tokenId);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        _safeTransferFrom(_layoutStruct(), from, to, tokenId, data);
    }

    function _safeTransferFrom(Storage storage layoutStruct_, address from, address to, uint256 tokenId) internal {
        _safeTransferFrom(layoutStruct_, from, to, tokenId, "");
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId) internal {
        _safeTransferFrom(_layoutStruct(), from, to, tokenId, "");
    }

    function _transferFrom(Storage storage layoutStruct_, address from, address to, uint256 tokenId) internal {
        if (from == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(from);
        }
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to);
        }
        if (!layoutStruct_.allTokenIds._contains(tokenId)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
        address owner = layoutStruct_.ownerOfTokenId[tokenId];
        if (owner != from) {
            revert IERC721Errors.ERC721IncorrectOwner(from, tokenId, owner);
        }
        if (
            from != address(msg.sender) && layoutStruct_.approvedForTokenId[tokenId] != msg.sender
                && !layoutStruct_.operatorApprovals[from][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        delete layoutStruct_.approvedForTokenId[tokenId];
        layoutStruct_.ownerOfTokenId[tokenId] = to;
        layoutStruct_.balanceOfAccount[from]--;
        layoutStruct_.balanceOfAccount[to]++;
        emit IERC721Events.Transfer(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        _transferFrom(_layoutStruct(), from, to, tokenId);
    }

    function _approve(Storage storage layoutStruct_, address operator, uint256 tokenId) internal {
        if (operator == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator);
        }
        address owner = _ownerOf(layoutStruct_, tokenId);
        if (owner != msg.sender) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, tokenId, owner);
        }
        layoutStruct_.approvedForTokenId[tokenId] = operator;
        emit IERC721Events.Approval(owner, operator, tokenId);
    }

    function _approve(address operator, uint256 tokenId) internal {
        _approve(_layoutStruct(), operator, tokenId);
    }

    function _setApprovalForAll(Storage storage layoutStruct_, address operator, bool approved) internal {
        if (operator == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator);
        }
        layoutStruct_.operatorApprovals[msg.sender][operator] = approved;
        emit IERC721Events.ApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        _setApprovalForAll(_layoutStruct(), operator, approved);
    }

    function _getApproved(Storage storage layoutStruct_, uint256 tokenId) internal view returns (address) {
        return layoutStruct_.approvedForTokenId[tokenId];
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        return _getApproved(_layoutStruct(), tokenId);
    }

    function _isApprovedForAll(Storage storage layoutStruct_, address owner, address operator) internal view returns (bool) {
        return layoutStruct_.operatorApprovals[owner][operator];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _isApprovedForAll(_layoutStruct(), owner, operator);
    }

    function _mint(Storage storage layoutStruct_, address to) internal returns (uint256 tokenId) {
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to);
        }
        tokenId = layoutStruct_.nextTokenId++;
        layoutStruct_.allTokenIds._add(tokenId);
        layoutStruct_.ownerOfTokenId[tokenId] = to;
        layoutStruct_.balanceOfAccount[to]++;
        emit IERC721Events.Transfer(address(0), to, tokenId);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        return _mint(_layoutStruct(), to);
    }

    function _burn(Storage storage layoutStruct_, address owner, uint256 tokenId) internal {
        if (!layoutStruct_.allTokenIds._contains(tokenId)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
        // address owner = layoutStruct_.ownerOfTokenId[tokenId];
        if (
            owner != address(msg.sender) && layoutStruct_.approvedForTokenId[tokenId] != msg.sender
                && !layoutStruct_.operatorApprovals[owner][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        delete layoutStruct_.ownerOfTokenId[tokenId];
        delete layoutStruct_.approvedForTokenId[tokenId];
        layoutStruct_.allTokenIds._remove(tokenId);
        layoutStruct_.balanceOfAccount[owner]--;
        emit IERC721Events.Transfer(owner, address(0), tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        _burn(_layoutStruct(), owner, tokenId);
    }

    function _burn(Storage storage layoutStruct_, uint256 tokenId) internal {
        address owner = layoutStruct_.ownerOfTokenId[tokenId];
        _burn(layoutStruct_, owner, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(_layoutStruct(), tokenId);
    }
}
