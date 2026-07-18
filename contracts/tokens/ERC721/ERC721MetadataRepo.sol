// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::ERC721MetadataRepo[]
/**
 * @title ERC721MetadataRepo - Storage library for ERC-721 metadata (name, symbol, baseURI, per-token URIs).
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for ERC-721 metadata state.
 * @dev Provides dual (parameterized + default) overloads for _initialize and accessors/mutators.
 * @dev Follows the gold standard from ERC20Repo, ERC4626Repo, OperableRepo, EIP712Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 */
library ERC721MetadataRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.721.metadata"))) - 1).
     *      This follows the canonical pattern used by ERC20Repo (eip.erc.20), ERC4626Repo etc.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.721.metadata"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-721 metadata.
     *      name: Collection name.
     *      symbol: Collection symbol.
     *      baseURI: Base for token URIs.
     *      tokenURIs: Per-token URI overrides.
     */
    struct Storage {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 tokenId => string tokenURI) tokenURIs;
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

    // tag::_initialize(Storage-string-memory-string-memory)[]
    /**
     * @dev Argumented version of _initialize (name+symbol) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param name_ Collection name.
     * @param symbol_ Collection symbol.
     */
    function _initialize(Storage storage layoutStruct, string memory name_, string memory symbol_) internal {
        layoutStruct.name = name_;
        layoutStruct.symbol = symbol_;
    }

    // end::_initialize(Storage-string-memory-string-memory)[]

    // tag::_initialize(string-memory-string-memory)[]
    /**
     * @dev Default version of _initialize (name+symbol) binding to the standard STORAGE_SLOT.
     * @param name_ Collection name.
     * @param symbol_ Collection symbol.
     */
    function _initialize(string memory name_, string memory symbol_) internal {
        _initialize(_layoutStruct(), name_, symbol_);
    }

    // end::_initialize(string-memory-string-memory)[]

    // tag::_initialize(Storage-string-memory-string-memory-string-memory)[]
    /**
     * @dev Argumented version of _initialize (with baseURI) to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param name_ Collection name.
     * @param symbol_ Collection symbol.
     * @param baseURI_ Base URI string.
     */
    function _initialize(
        Storage storage layoutStruct,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal {
        _initialize(layoutStruct, name_, symbol_);
        layoutStruct.baseURI = baseURI_;
    }

    // end::_initialize(Storage-string-memory-string-memory-string-memory)[]

    // tag::_name(Storage)[]
    /**
     * @dev Argumented version of _name to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The collection name (storage ref).
     */
    function _name(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.name;
    }

    // end::_name(Storage)[]

    // tag::_name()[]
    /**
     * @dev Default version of _name binding to the standard STORAGE_SLOT.
     * @return The collection name.
     */
    function _name() internal view returns (string memory) {
        return _name(_layoutStruct());
    }

    // end::_name()[]

    // tag::_symbol(Storage)[]
    /**
     * @dev Argumented version of _symbol to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The collection symbol (storage ref).
     */
    function _symbol(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.symbol;
    }

    // end::_symbol(Storage)[]

    // tag::_symbol()[]
    /**
     * @dev Default version of _symbol binding to the standard STORAGE_SLOT.
     * @return The collection symbol.
     */
    function _symbol() internal view returns (string memory) {
        return _symbol(_layoutStruct());
    }

    // end::_symbol()[]

    // tag::_baseURI(Storage)[]
    /**
     * @dev Argumented version of _baseURI to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The baseURI (storage ref).
     */
    function _baseURI(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.baseURI;
    }

    // end::_baseURI(Storage)[]

    // tag::_baseURI()[]
    /**
     * @dev Default version of _baseURI binding to the standard STORAGE_SLOT.
     * @return The baseURI.
     */
    function _baseURI() internal view returns (string memory) {
        return _baseURI(_layoutStruct());
    }

    // end::_baseURI()[]

    // tag::_tokenURI(Storage-uint256)[]
    /**
     * @dev Argumented version of _tokenURI to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenId_ The token id.
     * @return The tokenURI (storage ref).
     */
    function _tokenURI(Storage storage layoutStruct, uint256 tokenId_) internal view returns (string storage) {
        return layoutStruct.tokenURIs[tokenId_];
    }

    // end::_tokenURI(Storage-uint256)[]

    // tag::_tokenURI(uint256)[]
    /**
     * @dev Default version of _tokenURI binding to the standard STORAGE_SLOT.
     * @param tokenId_ The token id.
     * @return The tokenURI.
     */
    function _tokenURI(uint256 tokenId_) internal view returns (string memory) {
        return _tokenURI(_layoutStruct(), tokenId_);
    }

    // end::_tokenURI(uint256)[]

    // tag::_setTokenURI(Storage-uint256-string-memory)[]
    /**
     * @dev Argumented version of _setTokenURI to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param tokenId_ The token id.
     * @param tokenURI_ The URI to set.
     */
    function _setTokenURI(Storage storage layoutStruct, uint256 tokenId_, string memory tokenURI_) internal {
        layoutStruct.tokenURIs[tokenId_] = tokenURI_;
    }

    // end::_setTokenURI(Storage-uint256-string-memory)[]

    // tag::_setTokenURI(uint256-string-memory)[]
    /**
     * @dev Default version of _setTokenURI binding to the standard STORAGE_SLOT.
     * @param tokenId_ The token id.
     * @param tokenURI_ The URI to set.
     */
    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal {
        _setTokenURI(_layoutStruct(), tokenId_, tokenURI_);
    }
    // end::_setTokenURI(uint256-string-memory)[]

    // end::ERC721MetadataRepo[]
}
