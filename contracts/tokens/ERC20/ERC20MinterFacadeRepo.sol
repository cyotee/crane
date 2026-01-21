// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library ERC20MinterFacadeRepo {
    bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("eip.erc.20.minter.facade"));

    struct Storage {
        uint256 maxMintAmount;
        uint256 minMintInterval;
        mapping(address account => uint256 lastMintTimestamp) lastMintTimestamps;
    }

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(DEFAULT_SLOT);
    }

    function _initialize(Storage storage layout, uint256 maxMintAmount_, uint256 minMintInterval_)
        internal
    {
        _setMaxMintAmount(layout, maxMintAmount_);
        _setMinMintInterval(layout, minMintInterval_);
    }

    function _initialize(uint256 maxMintAmount_, uint256 minMintInterval_) internal {
        _initialize(_layout(), maxMintAmount_, minMintInterval_);
    }

    function _setMaxMintAmount(Storage storage layout, uint256 maxMintAmount_) internal {
        layout.maxMintAmount = maxMintAmount_;
    }

    function _setMaxMintAmount(uint256 maxMintAmount_) internal {
        _setMaxMintAmount(_layout(), maxMintAmount_);
    }

    function _maxMintAmount(Storage storage layout) internal view returns (uint256) {
        return layout.maxMintAmount;
    }

    function _maxMintAmount() internal view returns (uint256) {
        return _maxMintAmount(_layout());
    }

    function _setMinMintInterval(Storage storage layout, uint256 minMintInterval_) internal {
        layout.minMintInterval = minMintInterval_;
    }

    function _setMinMintInterval(uint256 minMintInterval_) internal {
        _setMinMintInterval(_layout(), minMintInterval_);
    }

    function _minMintInterval(Storage storage layout) internal view returns (uint256) {
        return layout.minMintInterval;
    }

    function _minMintInterval() internal view returns (uint256) {
        return _minMintInterval(_layout());
    }

    function _lastMintTimestamp(Storage storage layout, address account) internal view returns (uint256) {
        return layout.lastMintTimestamps[account];
    }

    function _lastMintTimestamp(address account) internal view returns (uint256) {
        return _lastMintTimestamp(_layout(), account);
    }

    function _setLastMintTimestamp(Storage storage layout, address account, uint256 timestamp) internal {
        layout.lastMintTimestamps[account] = timestamp;
    }

    function _setLastMintTimestamp(address account, uint256 timestamp) internal {
        _setLastMintTimestamp(_layout(), account, timestamp);
    }
}