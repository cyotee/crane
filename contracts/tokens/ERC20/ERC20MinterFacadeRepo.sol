// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::ERC20MinterFacadeRepo[]
/**
 * @title ERC20MinterFacadeRepo - Storage library for ERC-20 minter facade controls (max amount, min interval, last timestamps).
 * @author cyotee doge <cyotee@syscoin.org>
 * @dev Storage library (Repo) for minter rate-limit state used by minter facades.
 * @dev Provides dual (parameterized + default) overloads for _initialize and all accessors/mutators.
 * @dev Follows the gold standard from ERC4626Repo, OperableRepo, EIP712Repo, ERC2535Repo, DeployedAddressesRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used alongside ERC20Repo for controlled minting logic in Diamond ERC20 implementations.
 */
library ERC20MinterFacadeRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.20.minter.facade"))) - 1).
     *      This follows the canonical pattern used by ERC2535Repo (eip.erc.2535), ERC4626Repo (eip.erc.4626), OperableRepo,
     *      MultiStepOwnableRepo, DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.20.minter.facade"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-20 minter facade.
     *      maxMintAmount: Maximum mintable in one tx (or per interval).
     *      minMintInterval: Minimum seconds between mints per account.
     *      lastMintTimestamps: Last mint time per account for interval enforcement.
     */
    struct Storage {
        uint256 maxMintAmount;
        uint256 minMintInterval;
        mapping(address account => uint256 lastMintTimestamp) lastMintTimestamps;
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

    // tag::_initialize(Storage-uint256-uint256)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param maxMintAmount_ Max amount per mint action.
     * @param minMintInterval_ Min seconds between mints.
     */
    function _initialize(Storage storage layoutStruct, uint256 maxMintAmount_, uint256 minMintInterval_) internal {
        _setMaxMintAmount(layoutStruct, maxMintAmount_);
        _setMinMintInterval(layoutStruct, minMintInterval_);
    }
    // end::_initialize(Storage-uint256-uint256)[]

    // tag::_initialize(uint256-uint256)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param maxMintAmount_ Max amount per mint action.
     * @param minMintInterval_ Min seconds between mints.
     */
    function _initialize(uint256 maxMintAmount_, uint256 minMintInterval_) internal {
        _initialize(_layoutStruct(), maxMintAmount_, minMintInterval_);
    }
    // end::_initialize(uint256-uint256)[]

    // tag::_setMaxMintAmount(Storage-uint256)[]
    /**
     * @dev Argumented version of _setMaxMintAmount to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param maxMintAmount_ The max mint amount.
     */
    function _setMaxMintAmount(Storage storage layoutStruct, uint256 maxMintAmount_) internal {
        layoutStruct.maxMintAmount = maxMintAmount_;
    }
    // end::_setMaxMintAmount(Storage-uint256)[]

    // tag::_setMaxMintAmount(uint256)[]
    /**
     * @dev Default version of _setMaxMintAmount binding to the standard STORAGE_SLOT.
     * @param maxMintAmount_ The max mint amount.
     */
    function _setMaxMintAmount(uint256 maxMintAmount_) internal {
        _setMaxMintAmount(_layoutStruct(), maxMintAmount_);
    }
    // end::_setMaxMintAmount(uint256)[]

    // tag::_maxMintAmount(Storage)[]
    /**
     * @dev Argumented version of _maxMintAmount to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The max mint amount.
     */
    function _maxMintAmount(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.maxMintAmount;
    }
    // end::_maxMintAmount(Storage)[]

    // tag::_maxMintAmount()[]
    /**
     * @dev Default version of _maxMintAmount binding to the standard STORAGE_SLOT.
     * @return The max mint amount.
     */
    function _maxMintAmount() internal view returns (uint256) {
        return _maxMintAmount(_layoutStruct());
    }
    // end::_maxMintAmount()[]

    // tag::_setMinMintInterval(Storage-uint256)[]
    /**
     * @dev Argumented version of _setMinMintInterval to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param minMintInterval_ The min mint interval seconds.
     */
    function _setMinMintInterval(Storage storage layoutStruct, uint256 minMintInterval_) internal {
        layoutStruct.minMintInterval = minMintInterval_;
    }
    // end::_setMinMintInterval(Storage-uint256)[]

    // tag::_setMinMintInterval(uint256)[]
    /**
     * @dev Default version of _setMinMintInterval binding to the standard STORAGE_SLOT.
     * @param minMintInterval_ The min mint interval seconds.
     */
    function _setMinMintInterval(uint256 minMintInterval_) internal {
        _setMinMintInterval(_layoutStruct(), minMintInterval_);
    }
    // end::_setMinMintInterval(uint256)[]

    // tag::_minMintInterval(Storage)[]
    /**
     * @dev Argumented version of _minMintInterval to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The min mint interval.
     */
    function _minMintInterval(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.minMintInterval;
    }
    // end::_minMintInterval(Storage)[]

    // tag::_minMintInterval()[]
    /**
     * @dev Default version of _minMintInterval binding to the standard STORAGE_SLOT.
     * @return The min mint interval.
     */
    function _minMintInterval() internal view returns (uint256) {
        return _minMintInterval(_layoutStruct());
    }
    // end::_minMintInterval()[]

    // tag::_lastMintTimestamp(Storage-address)[]
    /**
     * @dev Argumented version of _lastMintTimestamp to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account to query last mint for.
     * @return The last mint timestamp.
     */
    function _lastMintTimestamp(Storage storage layoutStruct, address account) internal view returns (uint256) {
        return layoutStruct.lastMintTimestamps[account];
    }
    // end::_lastMintTimestamp(Storage-address)[]

    // tag::_lastMintTimestamp(address)[]
    /**
     * @dev Default version of _lastMintTimestamp binding to the standard STORAGE_SLOT.
     * @param account The account to query last mint for.
     * @return The last mint timestamp.
     */
    function _lastMintTimestamp(address account) internal view returns (uint256) {
        return _lastMintTimestamp(_layoutStruct(), account);
    }
    // end::_lastMintTimestamp(address)[]

    // tag::_setLastMintTimestamp(Storage-address-uint256)[]
    /**
     * @dev Argumented version of _setLastMintTimestamp to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param account The account.
     * @param timestamp The timestamp to record.
     */
    function _setLastMintTimestamp(Storage storage layoutStruct, address account, uint256 timestamp) internal {
        layoutStruct.lastMintTimestamps[account] = timestamp;
    }
    // end::_setLastMintTimestamp(Storage-address-uint256)[]

    // tag::_setLastMintTimestamp(address-uint256)[]
    /**
     * @dev Default version of _setLastMintTimestamp binding to the standard STORAGE_SLOT.
     * @param account The account.
     * @param timestamp The timestamp to record.
     */
    function _setLastMintTimestamp(address account, uint256 timestamp) internal {
        _setLastMintTimestamp(_layoutStruct(), account, timestamp);
    }
    // end::_setLastMintTimestamp(address-uint256)[]
}
// end::ERC20MinterFacadeRepo[]
