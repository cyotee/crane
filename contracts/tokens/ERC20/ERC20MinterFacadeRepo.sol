// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library ERC20MinterFacadeRepo {
    bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("eip.erc.20.minter.facade"));

    struct Storage {
        uint256 maxMintAmount;
        uint256 minMintInterval;
        mapping(address account => uint256 lastMintTimestamp) lastMintTimestamps;
    }

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(DEFAULT_SLOT);
    }

    function _initialize(Storage storage layoutStruct, uint256 maxMintAmount_, uint256 minMintInterval_) internal {
        _setMaxMintAmount(layoutStruct, maxMintAmount_);
        _setMinMintInterval(layoutStruct, minMintInterval_);
    }

    function _initialize(uint256 maxMintAmount_, uint256 minMintInterval_) internal {
        _initialize(_layoutStruct(), maxMintAmount_, minMintInterval_);
    }

    function _setMaxMintAmount(Storage storage layoutStruct, uint256 maxMintAmount_) internal {
        layoutStruct.maxMintAmount = maxMintAmount_;
    }

    function _setMaxMintAmount(uint256 maxMintAmount_) internal {
        _setMaxMintAmount(_layoutStruct(), maxMintAmount_);
    }

    function _maxMintAmount(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maxMintAmount;
    }

    function _maxMintAmount() internal view returns (uint256) {
        return _maxMintAmount(_layoutStruct());
    }

    function _setMinMintInterval(Storage storage layoutStruct, uint256 minMintInterval_) internal {
        layoutStruct.minMintInterval = minMintInterval_;
    }

    function _setMinMintInterval(uint256 minMintInterval_) internal {
        _setMinMintInterval(_layoutStruct(), minMintInterval_);
    }

    function _minMintInterval(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minMintInterval;
    }

    function _minMintInterval() internal view returns (uint256) {
        return _minMintInterval(_layoutStruct());
    }

    function _lastMintTimestamp(Storage storage layoutStruct, address account) internal view returns (uint256) {
        return layoutStruct.lastMintTimestamps[account];
    }

    function _lastMintTimestamp(address account) internal view returns (uint256) {
        return _lastMintTimestamp(_layoutStruct(), account);
    }

    function _setLastMintTimestamp(Storage storage layoutStruct, address account, uint256 timestamp) internal {
        layoutStruct.lastMintTimestamps[account] = timestamp;
    }

    function _setLastMintTimestamp(address account, uint256 timestamp) internal {
        _setLastMintTimestamp(_layoutStruct(), account, timestamp);
    }
}
