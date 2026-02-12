// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC721Repo} from "@crane/contracts/tokens/ERC721/ERC721Repo.sol";
// import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {UInt256Set, UInt256SetRepo} from "@crane/contracts/utils/collections/sets/UInt256SetRepo.sol";

library ERC721EnumeratedRepo {
    // using AddressSetRepo for AddressSet;
    using UInt256SetRepo for UInt256Set;
    // using ERC721EnumeratedRepo for Storage;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.erc.721.enummerated"));

    struct Storage {
        UInt256Set allTokenIds;
        mapping(address owner => UInt256Set ownedIds) ownedIds;
        mapping(address owner => address globalOperator) globalOperatorOfAccount;
    }

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _tokenIds(Storage storage layout_) internal view returns (uint256[] storage) {
        return layout_.allTokenIds._values();
    }

    function _tokenIds() internal view returns (uint256[] storage) {
        return _tokenIds(_layout());
    }

    function _ownedIds(Storage storage layout_, address owner) internal view returns (uint256[] storage) {
        return layout_.ownedIds[owner]._values();
    }

    function _ownedIds(address owner) internal view returns (uint256[] storage) {
        return _ownedIds(_layout(), owner);
    }

    function _globalOperatorOf(Storage storage layout_, address owner) internal view returns (address) {
        return layout_.globalOperatorOfAccount[owner];
    }

    function _globalOperatorOf(address owner) internal view returns (address) {
        return _globalOperatorOf(_layout(), owner);
    }

    function _safeTransferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layout_,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        ERC721Repo._safeTransferFrom(
            layout_, 
            from, 
            to, 
            tokenId, 
            data
        );
        enumLayout_.ownedIds[from]._remove(tokenId);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        Storage storage enumLayout = _layout();
        ERC721Repo.Storage storage layout_ = ERC721Repo._layout();
        _safeTransferFrom(enumLayout, layout_, from, to, tokenId, data);
    }

    function _safeTransferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layout_,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _safeTransferFrom(enumLayout_, layout_, from, to, tokenId, "");
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId) internal {
        Storage storage enumLayout = _layout();
        ERC721Repo.Storage storage layout_ = ERC721Repo._layout();
        _safeTransferFrom(enumLayout, layout_, from, to, tokenId, "");
    }

    function _transferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layout_,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ERC721Repo._transferFrom(layout_, from, to, tokenId);
        enumLayout_.ownedIds[from]._remove(tokenId);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        Storage storage enumLayout = _layout();
        ERC721Repo.Storage storage layout_ = ERC721Repo._layout();
        _transferFrom(enumLayout, layout_, from, to, tokenId);
    }

    function _setApprovalForAll(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layout_,
        address operator,
        bool approved
    ) internal {
        ERC721Repo._setApprovalForAll(layout_, operator, approved);
        if (approved) {
            enumLayout_.globalOperatorOfAccount[msg.sender] = operator;
        } else {
            delete enumLayout_.globalOperatorOfAccount[msg.sender];
        }
    }

    function _mint(Storage storage enumLayout_, ERC721Repo.Storage storage layout_, address to)
        internal
        returns (uint256 tokenId)
    {
        tokenId = ERC721Repo._mint(layout_, to);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        Storage storage enumLayout = _layout();
        ERC721Repo.Storage storage layout_ = ERC721Repo._layout();
        tokenId = _mint(enumLayout, layout_, to);
    }

    function _burn(Storage storage enumLayout_, ERC721Repo.Storage storage layout_, uint256 tokenId) internal {
        address owner = layout_.ownerOfTokenId[tokenId];
        ERC721Repo._burn(layout_, owner, tokenId);
        enumLayout_.ownedIds[owner]._remove(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        Storage storage enumLayout = _layout();
        ERC721Repo.Storage storage layout_ = ERC721Repo._layout();
        _burn(enumLayout, layout_, tokenId);
    }
}
