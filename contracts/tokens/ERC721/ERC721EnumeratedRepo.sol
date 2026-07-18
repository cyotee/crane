// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC721Repo} from "@crane/contracts/tokens/ERC721/ERC721Repo.sol";
// import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {UInt256Set, UInt256SetRepo} from "@crane/contracts/utils/collections/sets/UInt256SetRepo.sol";

// tag::ERC721EnumeratedRepo[]
/**
 * @title ERC721EnumeratedRepo - Storage library augmenting ERC721 with enumeration (owned ids, all ids, global operators).
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for ERC-721 enumeration helpers. Composes with ERC721Repo.Storage.
 * @dev Provides dual (parameterized + default) overloads; delegates core state to ERC721Repo.
 * @dev Follows the gold standard from ERC20Repo, ERC4626Repo, OperableRepo, EIP712Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 */
library ERC721EnumeratedRepo {
    // using AddressSetRepo for AddressSet;
    using UInt256SetRepo for UInt256Set;
    // using ERC721EnumeratedRepo for Storage;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.721.enummerated"))) - 1).
     *      This follows the canonical pattern ... (hierarchical equivalent for ERC721 enumeration).
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.721.enummerated"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-721 enumeration augmentation.
     *      allTokenIds: duplicate view of ids (augments ERC721).
     *      ownedIds: per-owner enumerable ids.
     *      globalOperatorOfAccount: per-account global operator (for ERC721 operator).
     */
    struct Storage {
        UInt256Set allTokenIds;
        mapping(address owner => UInt256Set ownedIds) ownedIds;
        mapping(address owner => address globalOperator) globalOperatorOfAccount;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_tokenIds(Storage)[]
    /**
     * @dev Argumented version of _tokenIds to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The array storage of all token ids.
     */
    function _tokenIds(Storage storage layoutStruct) internal view returns (uint256[] storage) {
        return layoutStruct.allTokenIds._values();
    }

    // end::_tokenIds(Storage)[]

    // tag::_tokenIds()[]
    /**
     * @dev Default version of _tokenIds binding to the standard STORAGE_SLOT.
     * @return The array storage of all token ids.
     */
    function _tokenIds() internal view returns (uint256[] storage) {
        return _tokenIds(_layoutStruct());
    }

    // end::_tokenIds()[]

    // tag::_ownedIds(Storage-address)[]
    /**
     * @dev Argumented version of _ownedIds to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner_ The owner address.
     * @return The array storage of owned token ids.
     */
    function _ownedIds(Storage storage layoutStruct, address owner_) internal view returns (uint256[] storage) {
        return layoutStruct.ownedIds[owner_]._values();
    }

    // end::_ownedIds(Storage-address)[]

    // tag::_ownedIds(address)[]
    /**
     * @dev Default version of _ownedIds binding to the standard STORAGE_SLOT.
     * @param owner_ The owner address.
     * @return The array storage of owned token ids.
     */
    function _ownedIds(address owner_) internal view returns (uint256[] storage) {
        return _ownedIds(_layoutStruct(), owner_);
    }

    // end::_ownedIds(address)[]

    // tag::_globalOperatorOf(Storage-address)[]
    /**
     * @dev Argumented version of _globalOperatorOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner_ The owner address.
     * @return The global operator address for the owner.
     */
    function _globalOperatorOf(Storage storage layoutStruct, address owner_) internal view returns (address) {
        return layoutStruct.globalOperatorOfAccount[owner_];
    }

    // end::_globalOperatorOf(Storage-address)[]

    // tag::_globalOperatorOf(address)[]
    /**
     * @dev Default version of _globalOperatorOf binding to the standard STORAGE_SLOT.
     * @param owner_ The owner address.
     * @return The global operator address for the owner.
     */
    function _globalOperatorOf(address owner_) internal view returns (address) {
        return _globalOperatorOf(_layoutStruct(), owner_);
    }

    // end::_globalOperatorOf(address)[]

    // tag::_safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256-bytes-memory)[]
    /**
     * @dev Argumented version (dual storage) of _safeTransferFrom with data.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @param data_ Data for receiver.
     */
    function _safeTransferFrom(
        Storage storage enumLayout,
        ERC721Repo.Storage storage layoutStruct,
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal {
        ERC721Repo._safeTransferFrom(layoutStruct, from_, to_, tokenId_, data_);
        enumLayout.ownedIds[from_]._remove(tokenId_);
        enumLayout.ownedIds[to_]._add(tokenId_);
    }

    // end::_safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256-bytes-memory)[]

    // tag::_safeTransferFrom(address-address-uint256-bytes-memory)[]
    /**
     * @dev Default version of _safeTransferFrom (with data) binding to the standard STORAGE_SLOT (plus ERC721 default).
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @param data_ Data for receiver.
     */
    function _safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct = ERC721Repo._layoutStruct();
        _safeTransferFrom(enumLayout, layoutStruct, from_, to_, tokenId_, data_);
    }

    // end::_safeTransferFrom(address-address-uint256-bytes-memory)[]

    // tag::_safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[]
    /**
     * @dev Argumented version (dual storage) of _safeTransferFrom.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     */
    function _safeTransferFrom(
        Storage storage enumLayout,
        ERC721Repo.Storage storage layoutStruct,
        address from_,
        address to_,
        uint256 tokenId_
    ) internal {
        _safeTransferFrom(enumLayout, layoutStruct, from_, to_, tokenId_, "");
    }

    // end::_safeTransferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[]

    // tag::_safeTransferFrom(address-address-uint256)[]
    /**
     * @dev Default version of _safeTransferFrom binding to the standard STORAGE_SLOT (plus ERC721 default).
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     */
    function _safeTransferFrom(address from_, address to_, uint256 tokenId_) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct = ERC721Repo._layoutStruct();
        _safeTransferFrom(enumLayout, layoutStruct, from_, to_, tokenId_, "");
    }

    // end::_safeTransferFrom(address-address-uint256)[]

    // tag::_transferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[]
    /**
     * @dev Argumented version (dual storage) of _transferFrom.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     */
    function _transferFrom(
        Storage storage enumLayout,
        ERC721Repo.Storage storage layoutStruct,
        address from_,
        address to_,
        uint256 tokenId_
    ) internal {
        ERC721Repo._transferFrom(layoutStruct, from_, to_, tokenId_);
        enumLayout.ownedIds[from_]._remove(tokenId_);
        enumLayout.ownedIds[to_]._add(tokenId_);
    }

    // end::_transferFrom(Storage-ERC721Repo.Storage-address-address-uint256)[]

    // tag::_transferFrom(address-address-uint256)[]
    /**
     * @dev Default version of _transferFrom binding to the standard STORAGE_SLOT (plus ERC721 default).
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     */
    function _transferFrom(address from_, address to_, uint256 tokenId_) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct = ERC721Repo._layoutStruct();
        _transferFrom(enumLayout, layoutStruct, from_, to_, tokenId_);
    }

    // end::_transferFrom(address-address-uint256)[]

    // tag::_setApprovalForAll(Storage-ERC721Repo.Storage-address-bool)[]
    /**
     * @dev Argumented version (dual storage) of _setApprovalForAll.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param operator_ The operator.
     * @param approved_ The approval status.
     */
    function _setApprovalForAll(
        Storage storage enumLayout,
        ERC721Repo.Storage storage layoutStruct,
        address operator_,
        bool approved_
    ) internal {
        ERC721Repo._setApprovalForAll(layoutStruct, operator_, approved_);
        if (approved_) {
            enumLayout.globalOperatorOfAccount[msg.sender] = operator_;
        } else {
            delete enumLayout.globalOperatorOfAccount[msg.sender];
        }
    }

    // end::_setApprovalForAll(Storage-ERC721Repo.Storage-address-bool)[]

    // tag::_mint(Storage-ERC721Repo.Storage-address)[]
    /**
     * @dev Argumented version (dual storage) of _mint.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param to_ The recipient.
     * @return tokenId The minted id.
     */
    function _mint(Storage storage enumLayout, ERC721Repo.Storage storage layoutStruct, address to_)
        internal
        returns (uint256 tokenId)
    {
        tokenId = ERC721Repo._mint(layoutStruct, to_);
        enumLayout.ownedIds[to_]._add(tokenId);
    }

    // end::_mint(Storage-ERC721Repo.Storage-address)[]

    // tag::_mint(address)[]
    /**
     * @dev Default version of _mint binding to the standard STORAGE_SLOT (plus ERC721 default).
     * @param to_ The recipient.
     * @return tokenId The minted id.
     */
    function _mint(address to_) internal returns (uint256 tokenId) {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct = ERC721Repo._layoutStruct();
        tokenId = _mint(enumLayout, layoutStruct, to_);
    }

    // end::_mint(address)[]

    // tag::_burn(Storage-ERC721Repo.Storage-uint256)[]
    /**
     * @dev Argumented version (dual storage) of _burn.
     * @dev The (enum) Storage struct to operate on.
     * @param enumLayout The enumerated Storage struct to operate on.
     * @param layoutStruct The ERC721Repo Storage struct to operate on.
     * @param tokenId_ The token id.
     */
    function _burn(Storage storage enumLayout, ERC721Repo.Storage storage layoutStruct, uint256 tokenId_) internal {
        address owner_ = layoutStruct.ownerOfTokenId[tokenId_];
        ERC721Repo._burn(layoutStruct, owner_, tokenId_);
        enumLayout.ownedIds[owner_]._remove(tokenId_);
    }

    // end::_burn(Storage-ERC721Repo.Storage-uint256)[]

    // tag::_burn(uint256)[]
    /**
     * @dev Default version of _burn binding to the standard STORAGE_SLOT (plus ERC721 default).
     * @param tokenId_ The token id.
     */
    function _burn(uint256 tokenId_) internal {
        Storage storage enumLayout = _layoutStruct();
        ERC721Repo.Storage storage layoutStruct = ERC721Repo._layoutStruct();
        _burn(enumLayout, layoutStruct, tokenId_);
    }
    // end::_burn(uint256)[]

    // end::ERC721EnumeratedRepo[]
}
