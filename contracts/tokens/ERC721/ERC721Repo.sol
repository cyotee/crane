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

// tag::ERC721Repo[]
/**
 * @title ERC721Repo - Storage library for standard ERC-721 token state (owners, balances, approvals, operators, all ids).
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for ERC-721 core state per IERC721/IERC721Events/IERC721Errors.
 * @dev Provides dual (parameterized + default) overloads for all storage accessors/mutators.
 * @dev Follows the gold standard from ERC20Repo, ERC4626Repo, OperableRepo, EIP712Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by ERC721Target/ERC721Facet and related for Diamond storage binding of ERC721 fields.
 */
library ERC721Repo {
    using UInt256SetRepo for UInt256Set;

    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.721"))) - 1).
     *      This follows the canonical pattern used by ERC20Repo (eip.erc.20), ERC4626Repo (eip.erc.4626), ERC2535Repo (eip.erc.2535), OperableRepo,
     *      MultiStepOwnableRepo, DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.721"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-721 token.
     *      nextTokenId: Next token id for auto-mint (consumer may ignore).
     *      allTokenIds: Set of all extant token ids.
     *      ownerOfTokenId: Owner address by tokenId.
     *      balanceOfAccount: Balance (count) by owner address.
     *      approvedForTokenId: Approved operator by tokenId.
     *      operatorApprovals: Operator approvals owner => operator => bool.
     */
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        uint256 nextTokenId;
        UInt256Set allTokenIds;
        mapping(uint256 tokenId => address) ownerOfTokenId;
        mapping(address owner => uint256) balanceOfAccount;
        mapping(uint256 tokenId => address) approvedForTokenId;
        mapping(address owner => mapping(address operator => bool)) operatorApprovals;
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

    // tag::_balanceOf(Storage-address)[]
    /**
     * @dev Argumented version of _balanceOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner_ The owner address.
     * @return The balance.
     */
    function _balanceOf(Storage storage layoutStruct, address owner_) internal view returns (uint256) {
        return layoutStruct.balanceOfAccount[owner_];
    }
    // end::_balanceOf(Storage-address)[]

    // tag::_balanceOf(address)[]
    /**
     * @dev Default version of _balanceOf binding to the standard STORAGE_SLOT.
     * @param owner_ The owner address.
     * @return The balance.
     */
    function _balanceOf(address owner_) internal view returns (uint256) {
        return _balanceOf(_layoutStruct(), owner_);
    }
    // end::_balanceOf(address)[]

    // tag::_ownerOf(Storage-uint256)[]
    /**
     * @dev Argumented version of _ownerOf to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenId_ The token id.
     * @return The owner address.
     */
    function _ownerOf(Storage storage layoutStruct, uint256 tokenId_) internal view returns (address) {
        return layoutStruct.ownerOfTokenId[tokenId_];
    }
    // end::_ownerOf(Storage-uint256)[]

    // tag::_ownerOf(uint256)[]
    /**
     * @dev Default version of _ownerOf binding to the standard STORAGE_SLOT.
     * @param tokenId_ The token id.
     * @return The owner address.
     */
    function _ownerOf(uint256 tokenId_) internal view returns (address) {
        return _ownerOf(_layoutStruct(), tokenId_);
    }
    // end::_ownerOf(uint256)[]

    // tag::_safeTransferFrom(Storage-address-address-uint256-bytes-memory)[]
    /**
     * @dev Argumented version of _safeTransferFrom (with data) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @param data_ Additional data with no specified format, sent in call to `to_`.
     * @custom:emits IERC721Events.Transfer (via _transferFrom)
     */
    function _safeTransferFrom(
        Storage storage layoutStruct,
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal {
        if (to_.code.length > 0) {
            try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 response) {
                if (response != IERC721Receiver.onERC721Received.selector) {
                    revert IERC721Errors.ERC721InvalidReceiver(to_);
                }
            } catch {
                revert IERC721Errors.ERC721InvalidReceiver(to_);
            }
        }
        _transferFrom(layoutStruct, from_, to_, tokenId_);
    }
    // end::_safeTransferFrom(Storage-address-address-uint256-bytes-memory)[]

    // tag::_safeTransferFrom(address-address-uint256-bytes-memory)[]
    /**
     * @dev Default version of _safeTransferFrom (with data) binding to the standard STORAGE_SLOT.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @param data_ Additional data with no specified format, sent in call to `to_`.
     * @custom:emits IERC721Events.Transfer (via _transferFrom)
     */
    function _safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) internal {
        _safeTransferFrom(_layoutStruct(), from_, to_, tokenId_, data_);
    }
    // end::_safeTransferFrom(address-address-uint256-bytes-memory)[]

    // tag::_safeTransferFrom(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _safeTransferFrom to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (via _transferFrom)
     */
    function _safeTransferFrom(Storage storage layoutStruct, address from_, address to_, uint256 tokenId_) internal {
        _safeTransferFrom(layoutStruct, from_, to_, tokenId_, "");
    }
    // end::_safeTransferFrom(Storage-address-address-uint256)[]

    // tag::_safeTransferFrom(address-address-uint256)[]
    /**
     * @dev Default version of _safeTransferFrom binding to the standard STORAGE_SLOT.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (via _transferFrom)
     */
    function _safeTransferFrom(address from_, address to_, uint256 tokenId_) internal {
        _safeTransferFrom(_layoutStruct(), from_, to_, tokenId_, "");
    }
    // end::_safeTransferFrom(address-address-uint256)[]

    // tag::_transferFrom(Storage-address-address-uint256)[]
    /**
     * @dev Argumented version of _transferFrom to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer
     */
    function _transferFrom(Storage storage layoutStruct, address from_, address to_, uint256 tokenId_) internal {
        if (from_ == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(from_);
        }
        if (to_ == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to_);
        }
        if (!layoutStruct.allTokenIds._contains(tokenId_)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId_);
        }
        address owner_ = layoutStruct.ownerOfTokenId[tokenId_];
        if (owner_ != from_) {
            revert IERC721Errors.ERC721IncorrectOwner(from_, tokenId_, owner_);
        }
        if (
            from_ != address(msg.sender) && layoutStruct.approvedForTokenId[tokenId_] != msg.sender
                && !layoutStruct.operatorApprovals[from_][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId_);
        }
        delete layoutStruct.approvedForTokenId[tokenId_];
        layoutStruct.ownerOfTokenId[tokenId_] = to_;
        layoutStruct.balanceOfAccount[from_]--;
        layoutStruct.balanceOfAccount[to_]++;
        emit IERC721Events.Transfer(from_, to_, tokenId_);
    }
    // end::_transferFrom(Storage-address-address-uint256)[]

    // tag::_transferFrom(address-address-uint256)[]
    /**
     * @dev Default version of _transferFrom binding to the standard STORAGE_SLOT.
     * @param from_ The current owner.
     * @param to_ The recipient.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer
     */
    function _transferFrom(address from_, address to_, uint256 tokenId_) internal {
        _transferFrom(_layoutStruct(), from_, to_, tokenId_);
    }
    // end::_transferFrom(address-address-uint256)[]

    // tag::_approve(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _approve to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param operator_ The operator to approve.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Approval
     */
    function _approve(Storage storage layoutStruct, address operator_, uint256 tokenId_) internal {
        if (operator_ == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator_);
        }
        address owner_ = _ownerOf(layoutStruct, tokenId_);
        if (owner_ != msg.sender) {
            revert IERC721Errors.ERC721IncorrectOwner(msg.sender, tokenId_, owner_);
        }
        layoutStruct.approvedForTokenId[tokenId_] = operator_;
        emit IERC721Events.Approval(owner_, operator_, tokenId_);
    }
    // end::_approve(Storage-address-uint256)[]

    // tag::_approve(address-uint256)[]
    /**
     * @dev Default version of _approve binding to the standard STORAGE_SLOT.
     * @param operator_ The operator to approve.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Approval
     */
    function _approve(address operator_, uint256 tokenId_) internal {
        _approve(_layoutStruct(), operator_, tokenId_);
    }
    // end::_approve(address-uint256)[]

    // tag::_setApprovalForAll(Storage-address-bool)[]
    /**
     * @dev Argumented version of _setApprovalForAll to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param operator_ The operator.
     * @param approved_ The approval status.
     * @custom:emits IERC721Events.ApprovalForAll
     */
    function _setApprovalForAll(Storage storage layoutStruct, address operator_, bool approved_) internal {
        if (operator_ == address(0)) {
            revert IERC721Errors.ERC721InvalidOperator(operator_);
        }
        layoutStruct.operatorApprovals[msg.sender][operator_] = approved_;
        emit IERC721Events.ApprovalForAll(msg.sender, operator_, approved_);
    }
    // end::_setApprovalForAll(Storage-address-bool)[]

    // tag::_setApprovalForAll(address-bool)[]
    /**
     * @dev Default version of _setApprovalForAll binding to the standard STORAGE_SLOT.
     * @param operator_ The operator.
     * @param approved_ The approval status.
     * @custom:emits IERC721Events.ApprovalForAll
     */
    function _setApprovalForAll(address operator_, bool approved_) internal {
        _setApprovalForAll(_layoutStruct(), operator_, approved_);
    }
    // end::_setApprovalForAll(address-bool)[]

    // tag::_getApproved(Storage-uint256)[]
    /**
     * @dev Argumented version of _getApproved to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenId_ The token id.
     * @return The approved address.
     */
    function _getApproved(Storage storage layoutStruct, uint256 tokenId_) internal view returns (address) {
        return layoutStruct.approvedForTokenId[tokenId_];
    }
    // end::_getApproved(Storage-uint256)[]

    // tag::_getApproved(uint256)[]
    /**
     * @dev Default version of _getApproved binding to the standard STORAGE_SLOT.
     * @param tokenId_ The token id.
     * @return The approved address.
     */
    function _getApproved(uint256 tokenId_) internal view returns (address) {
        return _getApproved(_layoutStruct(), tokenId_);
    }
    // end::_getApproved(uint256)[]

    // tag::_isApprovedForAll(Storage-address-address)[]
    /**
     * @dev Argumented version of _isApprovedForAll to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner_ The token owner.
     * @param operator_ The operator.
     * @return True if operator is approved for all of owner's tokens.
     */
    function _isApprovedForAll(Storage storage layoutStruct, address owner_, address operator_)
        internal
        view
        returns (bool)
    {
        return layoutStruct.operatorApprovals[owner_][operator_];
    }
    // end::_isApprovedForAll(Storage-address-address)[]

    // tag::_isApprovedForAll(address-address)[]
    /**
     * @dev Default version of _isApprovedForAll binding to the standard STORAGE_SLOT.
     * @param owner_ The token owner.
     * @param operator_ The operator.
     * @return True if operator is approved for all of owner's tokens.
     */
    function _isApprovedForAll(address owner_, address operator_) internal view returns (bool) {
        return _isApprovedForAll(_layoutStruct(), owner_, operator_);
    }
    // end::_isApprovedForAll(address-address)[]

    // tag::_mint(Storage-address)[]
    /**
     * @dev Argumented version of _mint to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param to_ The recipient of the minted token.
     * @return tokenId The newly minted token id.
     * @custom:emits IERC721Events.Transfer (from zero)
     */
    function _mint(Storage storage layoutStruct, address to_) internal returns (uint256 tokenId) {
        if (to_ == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(to_);
        }
        tokenId = layoutStruct.nextTokenId++;
        layoutStruct.allTokenIds._add(tokenId);
        layoutStruct.ownerOfTokenId[tokenId] = to_;
        layoutStruct.balanceOfAccount[to_]++;
        emit IERC721Events.Transfer(address(0), to_, tokenId);
    }
    // end::_mint(Storage-address)[]

    // tag::_mint(address)[]
    /**
     * @dev Default version of _mint binding to the standard STORAGE_SLOT.
     * @param to_ The recipient of the minted token.
     * @return tokenId The newly minted token id.
     * @custom:emits IERC721Events.Transfer (from zero)
     */
    function _mint(address to_) internal returns (uint256 tokenId) {
        return _mint(_layoutStruct(), to_);
    }
    // end::_mint(address)[]

    // tag::_burn(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _burn (owner explicit) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param owner_ The owner of the token.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (to zero)
     */
    function _burn(Storage storage layoutStruct, address owner_, uint256 tokenId_) internal {
        if (!layoutStruct.allTokenIds._contains(tokenId_)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId_);
        }
        if (
            owner_ != address(msg.sender) && layoutStruct.approvedForTokenId[tokenId_] != msg.sender
                && !layoutStruct.operatorApprovals[owner_][msg.sender]
        ) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId_);
        }
        delete layoutStruct.ownerOfTokenId[tokenId_];
        delete layoutStruct.approvedForTokenId[tokenId_];
        layoutStruct.allTokenIds._remove(tokenId_);
        layoutStruct.balanceOfAccount[owner_]--;
        emit IERC721Events.Transfer(owner_, address(0), tokenId_);
    }
    // end::_burn(Storage-address-uint256)[]

    // tag::_burn(address-uint256)[]
    /**
     * @dev Default version of _burn (owner explicit) binding to the standard STORAGE_SLOT.
     * @param owner_ The owner of the token.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (to zero)
     */
    function _burn(address owner_, uint256 tokenId_) internal {
        _burn(_layoutStruct(), owner_, tokenId_);
    }
    // end::_burn(address-uint256)[]

    // tag::_burn(Storage-uint256)[]
    /**
     * @dev Argumented version of _burn (lookup owner) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (to zero)
     */
    function _burn(Storage storage layoutStruct, uint256 tokenId_) internal {
        address owner_ = layoutStruct.ownerOfTokenId[tokenId_];
        _burn(layoutStruct, owner_, tokenId_);
    }
    // end::_burn(Storage-uint256)[]

    // tag::_burn(uint256)[]
    /**
     * @dev Default version of _burn (lookup owner) binding to the standard STORAGE_SLOT.
     * @param tokenId_ The token id.
     * @custom:emits IERC721Events.Transfer (to zero)
     */
    function _burn(uint256 tokenId_) internal {
        _burn(_layoutStruct(), tokenId_);
    }
    // end::_burn(uint256)[]

// end::ERC721Repo[]
}
