// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library ERC721MetadataRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.erc.721.metadata"));

    struct Storage {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 tokenId => string tokenURI) tokenURIs;
    }

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, string memory name_, string memory symbol_) internal {
        layoutStruct.name = name_;
        layoutStruct.symbol = symbol_;
    }

    function _initialize(string memory name_, string memory symbol_) internal {
        _initialize(_layoutStruct(), name_, symbol_);
    }

    function _initialize(Storage storage layoutStruct, string memory name_, string memory symbol_, string memory baseURI_)
        internal
    {
        _initialize(layoutStruct, name_, symbol_);
        layoutStruct.baseURI = baseURI_;
    }

    function _name(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.name;
    }

    function _name() internal view returns (string memory) {
        return _name(_layoutStruct());
    }

    function _symbol(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.symbol;
    }

    function _symbol() internal view returns (string memory) {
        return _symbol(_layoutStruct());
    }

    function _baseURI(Storage storage layoutStruct) internal view returns (string storage) {
        return layoutStruct.baseURI;
    }

    function _baseURI() internal view returns (string memory) {
        return _baseURI(_layoutStruct());
    }

    function _tokenURI(Storage storage layoutStruct, uint256 tokenId) internal view returns (string storage) {
        return layoutStruct.tokenURIs[tokenId];
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return _tokenURI(_layoutStruct(), tokenId);
    }

    function _setTokenURI(Storage storage layoutStruct, uint256 tokenId, string memory tokenURI_) internal {
        layoutStruct.tokenURIs[tokenId] = tokenURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _setTokenURI(_layoutStruct(), tokenId, tokenURI_);
    }
}
