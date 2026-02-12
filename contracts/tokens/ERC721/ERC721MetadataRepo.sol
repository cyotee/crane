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

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout_, string memory name_, string memory symbol_)
        internal
    {
        layout_.name = name_;
        layout_.symbol = symbol_;
    }

    function _initialize(string memory name_, string memory symbol_) internal {
        _initialize(_layout(), name_, symbol_);
    }

    function _initialize(
        Storage storage layout_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal {
        _initialize(layout_, name_, symbol_);
        layout_.baseURI = baseURI_;
    }

    function _name(Storage storage layout_) internal view returns (string storage) {
        return layout_.name;
    }

    function _name() internal view returns (string memory) {
        return _name(_layout());
    }

    function _symbol(Storage storage layout_) internal view returns (string storage) {
        return layout_.symbol;
    }

    function _symbol() internal view returns (string memory) {
        return _symbol(_layout());
    }

    function _baseURI(Storage storage layout_) internal view returns (string storage) {
        return layout_.baseURI;
    }

    function _baseURI() internal view returns (string memory) {
        return _baseURI(_layout());
    }

    function _tokenURI(Storage storage layout_, uint256 tokenId) internal view returns (string storage) {
        return layout_.tokenURIs[tokenId];
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return _tokenURI(_layout(), tokenId);
    }

    function _setTokenURI(Storage storage layout_, uint256 tokenId, string memory tokenURI_) internal {
        layout_.tokenURIs[tokenId] = tokenURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _setTokenURI(_layout(), tokenId, tokenURI_);
    }
}
