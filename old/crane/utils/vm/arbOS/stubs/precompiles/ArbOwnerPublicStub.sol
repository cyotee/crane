// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IArbOwnerPublic} from "contracts/crane/interfaces/networks/IArbOwnerPublic.sol";

import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";

contract ArbOwnerPublicStub is IArbOwnerPublic {
    using AddressSetRepo for AddressSet;

    address internal _chainOwner;

    function setChainOwner(address newOwner) public returns (bool) {
        _chainOwner = newOwner;
        return true;
    }

    /// @notice See if the user is a chain owner
    function isChainOwner(address addr) external view returns (bool) {
        return addr == _chainOwner;
    }

    /**
     * @notice Rectify the list of chain owners
     * If successful, emits ChainOwnerRectified event
     * Available in ArbOS version 11
     */
    function rectifyChainOwner(address ownerToRectify) external {
        emit ChainOwnerRectified(ownerToRectify);
    }

    AddressSet internal _allChainOwners;

    function setAllChainOwners(address[] memory newAllOwners) public returns (bool) {
        _allChainOwners._add(newAllOwners);
        return true;
    }

    /// @notice Retrieves the list of chain owners
    function getAllChainOwners() external view returns (address[] memory) {
        return _allChainOwners._values();
    }

    address internal _networkFeeAccount;

    function setNetworkFeeAccount(address newAccount) public returns (bool) {
        _networkFeeAccount = newAccount;
        return true;
    }

    /// @notice Gets the network fee collector
    function getNetworkFeeAccount() external view returns (address) {
        return _networkFeeAccount;
    }

    address internal _infraFeeAccount;

    function setInfraFreeAAccount(address newAccount) public returns (bool) {
        _infraFeeAccount = newAccount;
        return true;
    }

    /// @notice Get the infrastructure fee collector
    function getInfraFeeAccount() external view returns (address) {
        return _infraFeeAccount;
    }

    uint64 internal _compressionLvl;

    function setCompressionLvl(uint64 lvl) public returns (bool) {
        _compressionLvl = lvl;
        return true;
    }

    /// @notice Get the Brotli compression level used for fast compression
    function getBrotliCompressionLevel() external view returns (uint64) {
        return _compressionLvl;
    }

    uint64 internal _arbosVersion;
    uint64 internal _scheduledForTimestamp;

    function setVersionAndTime(uint64 arbosVersion, uint64 scheduledForTimestamp) public returns (bool) {
        _arbosVersion = arbosVersion;
        _scheduledForTimestamp = scheduledForTimestamp;
        return true;
    }

    /// @notice Get the next scheduled ArbOS version upgrade and its activation timestamp.
    /// Returns (0, 0) if no ArbOS upgrade is scheduled.
    /// Available in ArbOS version 20.
    function getScheduledUpgrade() external view returns (uint64 arbosVersion, uint64 scheduledForTimestamp) {
        return (_arbosVersion, _scheduledForTimestamp);
    }

    uint64 internal _sharePrice;

    function setSharePrice(uint64 newSharePrice) public returns (bool) {
        _sharePrice = newSharePrice;
        return true;
    }

    function getSharePrice() external view returns (uint64) {
        return _sharePrice;
    }

    uint256 internal _shareCount;

    function setShareCount(uint256 newCount) public returns (bool) {
        _shareCount = newCount;
        return true;
    }

    function getShareCount() external view returns (uint256) {
        return _shareCount;
    }

    uint64 internal _apy;

    function setApy(uint64 newApy) public returns (bool) {
        _apy = newApy;
        return true;
    }

    function getApy() external view returns (uint64) {
        return _apy;
    }
}
