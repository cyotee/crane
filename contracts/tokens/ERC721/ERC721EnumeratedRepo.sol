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

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _tokenIds(Storage storage layoutStruct_) internal view returns (uint256[] storage) {
        return layoutStruct_.allTokenIds._values();
    }

    function _tokenIds() internal view returns (uint256[] storage) {
        return _tokenIds(_layoutStruct());
    }

    function _ownedIds(Storage storage layoutStruct_, address owner) internal view returns (uint256[] storage) {
        return layoutStruct_.ownedIds[owner]._values();
    }

    function _ownedIds(address owner) internal view returns (uint256[] storage) {
        return _ownedIds(_layoutStruct(), owner);
    }

    function _globalOperatorOf(Storage storage layoutStruct_, address owner) internal view returns (address) {
        return layoutStruct_.globalOperatorOfAccount[owner];
    }

    function _globalOperatorOf(address owner) internal view returns (address) {
        return _globalOperatorOf(_layoutStruct(), owner);
    }

    function _safeTransferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layoutStruct_,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        ERC721Repo._safeTransferFrom(layoutStruct_, from, to, tokenId, data);
        enumLayout_.ownedIds[from]._remove(tokenId);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct_ = ERC721Repo._layoutStruct();
        _safeTransferFrom(enumLayout, layoutStruct_, from, to, tokenId, data);
    }

    function _safeTransferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layoutStruct_,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _safeTransferFrom(enumLayout_, layoutStruct_, from, to, tokenId, "");
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct_ = ERC721Repo._layoutStruct();
        _safeTransferFrom(enumLayout, layoutStruct_, from, to, tokenId, "");
    }

    function _transferFrom(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layoutStruct_,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ERC721Repo._transferFrom(layoutStruct_, from, to, tokenId);
        enumLayout_.ownedIds[from]._remove(tokenId);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct_ = ERC721Repo._layoutStruct();
        _transferFrom(enumLayout, layoutStruct_, from, to, tokenId);
    }

    function _setApprovalForAll(
        Storage storage enumLayout_,
        ERC721Repo.Storage storage layoutStruct_,
        address operator,
        bool approved
    ) internal {
        ERC721Repo._setApprovalForAll(layoutStruct_, operator, approved);
        if (approved) {
            enumLayout_.globalOperatorOfAccount[msg.sender] = operator;
        } else {
            delete enumLayout_.globalOperatorOfAccount[msg.sender];
        }
    }

    function _mint(Storage storage enumLayout_, ERC721Repo.Storage storage layoutStruct_, address to)
        internal
        returns (uint256 tokenId)
    {
        tokenId = ERC721Repo._mint(layoutStruct_, to);
        enumLayout_.ownedIds[to]._add(tokenId);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct_ = ERC721Repo._layoutStruct();
        tokenId = _mint(enumLayout, layoutStruct_, to);
    }

    function _burn(Storage storage enumLayout_, ERC721Repo.Storage storage layoutStruct_, uint256 tokenId) internal {
        address owner = layoutStruct_.ownerOfTokenId[tokenId];
        ERC721Repo._burn(layoutStruct_, owner, tokenId);
        enumLayout_.ownedIds[owner]._remove(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct_ = ERC721Repo._layoutStruct();
        _burn(enumLayout, layoutStruct_, tokenId);
    }
}
