// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

// tag::BountyRepo[]
/**
 * @title BountyRepo - Storage library for bounty records, contributions, disbursements and access control.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for common bounty data structures and operations.
 * @dev Provides dual (parameterized + default) functions for all accessors/mutators per gold standard.
 * @dev Used by bounty Targets, Facets and related contracts.
 */
library BountyRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for bounty common data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.bounties.common"))) - 1);

    // end::STORAGE_SLOT[]

    enum BountyType { Single, Milestone, Contest, Continuous }
    enum BountyStatus { Open, Closed, Canceled }
    enum BountyAccess { Open, Closed }

    struct Bounty {
        uint256 id;
        BountyType bType;
        BountyAccess access;
        address issuer;
        address funder;
        BountyStatus status;
        string specUri;
        string encryptionPubKeyUri;
        uint256 createdAt;
        uint256 deadline;
    }

    struct DisputeInfo {
        uint256 bountyId;
        uint256 subIndex; // e.g. milestone index or tier
        address raisedBy;
    }

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for BountyRepo.
     */
    struct Storage {
        uint256 nextBountyId;
        mapping(uint256 => Bounty) bounties;
        // per bounty per token total contributed (main + additional)
        mapping(uint256 => mapping(address => uint256)) totalContributed; // bounty => token => amount
        // per contributor contributions (used for refund attribution)
        mapping(uint256 => mapping(address => mapping(address => uint256))) contributions; // bounty => contributor => token => amount
        // per bounty per token total disbursed (payouts to workers + withdraws/refunds)
        mapping(uint256 => mapping(address => uint256)) disbursed;
        // for closed bounties
        mapping(uint256 => mapping(address => bool)) allowedSubmitters;
        // dispute info
        mapping(uint256 => DisputeInfo) disputes; // disputeId => info
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_nextBountyId(Storage)[]
    /**
     * @dev Argumented version of _nextBountyId to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return The next bounty ID.
     */
    function _nextBountyId(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.nextBountyId;
    }

    // end::_nextBountyId(Storage)[]

    // tag::_nextBountyId()[]
    /**
     * @dev Default version of _nextBountyId binding to the standard STORAGE_SLOT.
     * @return The next bounty ID.
     */
    function _nextBountyId() internal view returns (uint256) {
        return _nextBountyId(_layoutStruct());
    }

    // end::_nextBountyId()[]

    // tag::_incrementBountyId(Storage)[]
    /**
     * @dev Argumented version of _incrementBountyId to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @return id The incremented ID (pre-increment value).
     */
    function _incrementBountyId(Storage storage layoutStruct) internal returns (uint256 id) {
        id = layoutStruct.nextBountyId++;
    }

    // end::_incrementBountyId(Storage)[]

    // tag::_incrementBountyId()[]
    /**
     * @dev Default version of _incrementBountyId binding to the standard STORAGE_SLOT.
     * @return id The incremented ID.
     */
    function _incrementBountyId() internal returns (uint256 id) {
        return _incrementBountyId(_layoutStruct());
    }

    // end::_incrementBountyId()[]

    // tag::_bounty(Storage-uint256)[]
    /**
     * @dev Argumented version of _bounty to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @return b The bounty storage reference.
     */
    function _bounty(Storage storage layoutStruct, uint256 id) internal view returns (Bounty storage b) {
        return layoutStruct.bounties[id];
    }

    // end::_bounty(Storage-uint256)[]

    // tag::_bounty(uint256)[]
    /**
     * @dev Default version of _bounty binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @return b The bounty storage reference.
     */
    function _bounty(uint256 id) internal view returns (Bounty storage b) {
        return _bounty(_layoutStruct(), id);
    }

    // end::_bounty(uint256)[]

    // tag::_setIssuer(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _setIssuer to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param issuer The issuer address.
     */
    function _setIssuer(Storage storage layoutStruct, uint256 id, address issuer) internal {
        layoutStruct.bounties[id].issuer = issuer;
    }

    // end::_setIssuer(Storage-uint256-address)[]

    // tag::_setIssuer(uint256-address)[]
    /**
     * @dev Default version of _setIssuer binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param issuer The issuer address.
     */
    function _setIssuer(uint256 id, address issuer) internal {
        _setIssuer(_layoutStruct(), id, issuer);
    }

    // end::_setIssuer(uint256-address)[]

    // tag::_setFunder(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _setFunder to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param funder The funder address.
     */
    function _setFunder(Storage storage layoutStruct, uint256 id, address funder) internal {
        layoutStruct.bounties[id].funder = funder;
    }

    // end::_setFunder(Storage-uint256-address)[]

    // tag::_setFunder(uint256-address)[]
    /**
     * @dev Default version of _setFunder binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param funder The funder address.
     */
    function _setFunder(uint256 id, address funder) internal {
        _setFunder(_layoutStruct(), id, funder);
    }

    // end::_setFunder(uint256-address)[]

    // tag::_setStatus(Storage-uint256-BountyStatus)[]
    /**
     * @dev Argumented version of _setStatus to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param status The status to set.
     */
    function _setStatus(Storage storage layoutStruct, uint256 id, BountyStatus status) internal {
        layoutStruct.bounties[id].status = status;
    }

    // end::_setStatus(Storage-uint256-BountyStatus)[]

    // tag::_setStatus(uint256-BountyStatus)[]
    /**
     * @dev Default version of _setStatus binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param status The status to set.
     */
    function _setStatus(uint256 id, BountyStatus status) internal {
        _setStatus(_layoutStruct(), id, status);
    }

    // end::_setStatus(uint256-BountyStatus)[]

    // tag::_setAccess(Storage-uint256-BountyAccess)[]
    /**
     * @dev Argumented version of _setAccess to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param access The access level to set.
     */
    function _setAccess(Storage storage layoutStruct, uint256 id, BountyAccess access) internal {
        layoutStruct.bounties[id].access = access;
    }

    // end::_setAccess(Storage-uint256-BountyAccess)[]

    // tag::_setAccess(uint256-BountyAccess)[]
    /**
     * @dev Default version of _setAccess binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param access The access level to set.
     */
    function _setAccess(uint256 id, BountyAccess access) internal {
        _setAccess(_layoutStruct(), id, access);
    }

    // end::_setAccess(uint256-BountyAccess)[]

    // tag::_getAccess(Storage-uint256)[]
    /**
     * @dev Argumented version of _getAccess to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @return The access level.
     */
    function _getAccess(Storage storage layoutStruct, uint256 id) internal view returns (BountyAccess) {
        return layoutStruct.bounties[id].access;
    }

    // end::_getAccess(Storage-uint256)[]

    // tag::_getAccess(uint256)[]
    /**
     * @dev Default version of _getAccess binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @return The access level.
     */
    function _getAccess(uint256 id) internal view returns (BountyAccess) {
        return _getAccess(_layoutStruct(), id);
    }

    // end::_getAccess(uint256)[]

    // tag::_initializeBounty(Storage-uint256-BountyType-address-address-string-string-uint256-BountyAccess)[]
    /**
     * @dev Argumented version of _initializeBounty to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param bType The bounty type.
     * @param issuer The issuer address.
     * @param funder The funder address.
     * @param specUri URI for the spec.
     * @param encryptionPubKeyUri URI for pub key.
     * @param deadline The deadline timestamp.
     * @param access The access level.
     * @return b The initialized bounty storage reference.
     */
    function _initializeBounty(
        Storage storage layoutStruct,
        uint256 id,
        BountyType bType,
        address issuer,
        address funder,
        string memory specUri,
        string memory encryptionPubKeyUri,
        uint256 deadline,
        BountyAccess access
    ) internal returns (Bounty storage b) {
        b = layoutStruct.bounties[id];
        b.id = id;
        b.bType = bType;
        b.access = access;
        b.issuer = issuer;
        b.funder = funder;
        b.status = BountyStatus.Open;
        b.specUri = specUri;
        b.encryptionPubKeyUri = encryptionPubKeyUri;
        b.createdAt = block.timestamp;
        b.deadline = deadline;
    }

    // end::_initializeBounty(Storage-uint256-BountyType-address-address-string-string-uint256-BountyAccess)[]

    // tag::_initializeBounty(uint256-BountyType-address-address-string-string-uint256-BountyAccess)[]
    /**
     * @dev Default version of _initializeBounty binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param bType The bounty type.
     * @param issuer The issuer address.
     * @param funder The funder address.
     * @param specUri URI for the spec.
     * @param encryptionPubKeyUri URI for pub key.
     * @param deadline The deadline timestamp.
     * @param access The access level.
     * @return b The initialized bounty storage reference.
     */
    function _initializeBounty(
        uint256 id,
        BountyType bType,
        address issuer,
        address funder,
        string memory specUri,
        string memory encryptionPubKeyUri,
        uint256 deadline,
        BountyAccess access
    ) internal returns (Bounty storage b) {
        return _initializeBounty(_layoutStruct(), id, bType, issuer, funder, specUri, encryptionPubKeyUri, deadline, access);
    }

    // end::_initializeBounty(uint256-BountyType-address-address-string-string-uint256-BountyAccess)[]

    // tag::_addContribution(Storage-uint256-address-address-uint256)[]
    /**
     * @dev Argumented version of _addContribution to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @param amount The contribution amount.
     */
    function _addContribution(Storage storage layoutStruct, uint256 id, address contributor, address token, uint256 amount) internal {
        layoutStruct.contributions[id][contributor][token] += amount;
        layoutStruct.totalContributed[id][token] += amount;
    }

    // end::_addContribution(Storage-uint256-address-address-uint256)[]

    // tag::_addContribution(uint256-address-address-uint256)[]
    /**
     * @dev Default version of _addContribution binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @param amount The contribution amount.
     */
    function _addContribution(uint256 id, address contributor, address token, uint256 amount) internal {
        _addContribution(_layoutStruct(), id, contributor, token, amount);
    }

    // end::_addContribution(uint256-address-address-uint256)[]

    // tag::_getContribution(Storage-uint256-address-address)[]
    /**
     * @dev Argumented version of _getContribution to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @return The contributed amount.
     */
    function _getContribution(Storage storage layoutStruct, uint256 id, address contributor, address token) internal view returns (uint256) {
        return layoutStruct.contributions[id][contributor][token];
    }

    // end::_getContribution(Storage-uint256-address-address)[]

    // tag::_getContribution(uint256-address-address)[]
    /**
     * @dev Default version of _getContribution binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @return The contributed amount.
     */
    function _getContribution(uint256 id, address contributor, address token) internal view returns (uint256) {
        return _getContribution(_layoutStruct(), id, contributor, token);
    }

    // end::_getContribution(uint256-address-address)[]

    // tag::_getTotalContributed(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _getTotalContributed to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The total contributed amount.
     */
    function _getTotalContributed(Storage storage layoutStruct, uint256 id, address token) internal view returns (uint256) {
        return layoutStruct.totalContributed[id][token];
    }

    // end::_getTotalContributed(Storage-uint256-address)[]

    // tag::_getTotalContributed(uint256-address)[]
    /**
     * @dev Default version of _getTotalContributed binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The total contributed amount.
     */
    function _getTotalContributed(uint256 id, address token) internal view returns (uint256) {
        return _getTotalContributed(_layoutStruct(), id, token);
    }

    // end::_getTotalContributed(uint256-address)[]

    // tag::_getDisbursed(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _getDisbursed to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The disbursed amount.
     */
    function _getDisbursed(Storage storage layoutStruct, uint256 id, address token) internal view returns (uint256) {
        return layoutStruct.disbursed[id][token];
    }

    // end::_getDisbursed(Storage-uint256-address)[]

    // tag::_getDisbursed(uint256-address)[]
    /**
     * @dev Default version of _getDisbursed binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The disbursed amount.
     */
    function _getDisbursed(uint256 id, address token) internal view returns (uint256) {
        return _getDisbursed(_layoutStruct(), id, token);
    }

    // end::_getDisbursed(uint256-address)[]

    // tag::_getRemaining(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _getRemaining to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The remaining amount.
     */
    function _getRemaining(Storage storage layoutStruct, uint256 id, address token) internal view returns (uint256) {
        uint256 tc = layoutStruct.totalContributed[id][token];
        uint256 d = layoutStruct.disbursed[id][token];
        return tc > d ? tc - d : 0;
    }

    // end::_getRemaining(Storage-uint256-address)[]

    // tag::_getRemaining(uint256-address)[]
    /**
     * @dev Default version of _getRemaining binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param token The token address.
     * @return The remaining amount.
     */
    function _getRemaining(uint256 id, address token) internal view returns (uint256) {
        return _getRemaining(_layoutStruct(), id, token);
    }

    // end::_getRemaining(uint256-address)[]

    // tag::_addDisbursed(Storage-uint256-address-uint256)[]
    /**
     * @dev Argumented version of _addDisbursed to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param token The token address.
     * @param amount The amount disbursed.
     */
    function _addDisbursed(Storage storage layoutStruct, uint256 id, address token, uint256 amount) internal {
        layoutStruct.disbursed[id][token] += amount;
    }

    // end::_addDisbursed(Storage-uint256-address-uint256)[]

    // tag::_addDisbursed(uint256-address-uint256)[]
    /**
     * @dev Default version of _addDisbursed binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param token The token address.
     * @param amount The amount disbursed.
     */
    function _addDisbursed(uint256 id, address token, uint256 amount) internal {
        _addDisbursed(_layoutStruct(), id, token, amount);
    }

    // end::_addDisbursed(uint256-address-uint256)[]

    // tag::_subtractContribution(Storage-uint256-address-address-uint256)[]
    /**
     * @dev Argumented version of _subtractContribution to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @param amount The amount to subtract.
     */
    function _subtractContribution(Storage storage layoutStruct, uint256 id, address contributor, address token, uint256 amount) internal {
        layoutStruct.contributions[id][contributor][token] -= amount;
        layoutStruct.totalContributed[id][token] -= amount;
    }

    // end::_subtractContribution(Storage-uint256-address-address-uint256)[]

    // tag::_subtractContribution(uint256-address-address-uint256)[]
    /**
     * @dev Default version of _subtractContribution binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param contributor The contributor address.
     * @param token The token address.
     * @param amount The amount to subtract.
     */
    function _subtractContribution(uint256 id, address contributor, address token, uint256 amount) internal {
        _subtractContribution(_layoutStruct(), id, contributor, token, amount);
    }

    // end::_subtractContribution(uint256-address-address-uint256)[]

    // tag::_addAllowedSubmitter(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _addAllowedSubmitter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     */
    function _addAllowedSubmitter(Storage storage layoutStruct, uint256 id, address submitter) internal {
        layoutStruct.allowedSubmitters[id][submitter] = true;
    }

    // end::_addAllowedSubmitter(Storage-uint256-address)[]

    // tag::_addAllowedSubmitter(uint256-address)[]
    /**
     * @dev Default version of _addAllowedSubmitter binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     */
    function _addAllowedSubmitter(uint256 id, address submitter) internal {
        _addAllowedSubmitter(_layoutStruct(), id, submitter);
    }

    // end::_addAllowedSubmitter(uint256-address)[]

    // tag::_removeAllowedSubmitter(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _removeAllowedSubmitter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     */
    function _removeAllowedSubmitter(Storage storage layoutStruct, uint256 id, address submitter) internal {
        layoutStruct.allowedSubmitters[id][submitter] = false;
    }

    // end::_removeAllowedSubmitter(Storage-uint256-address)[]

    // tag::_removeAllowedSubmitter(uint256-address)[]
    /**
     * @dev Default version of _removeAllowedSubmitter binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     */
    function _removeAllowedSubmitter(uint256 id, address submitter) internal {
        _removeAllowedSubmitter(_layoutStruct(), id, submitter);
    }

    // end::_removeAllowedSubmitter(uint256-address)[]

    // tag::_isAllowedSubmitter(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _isAllowedSubmitter to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     * @return True if allowed.
     */
    function _isAllowedSubmitter(Storage storage layoutStruct, uint256 id, address submitter) internal view returns (bool) {
        return layoutStruct.allowedSubmitters[id][submitter];
    }

    // end::_isAllowedSubmitter(Storage-uint256-address)[]

    // tag::_isAllowedSubmitter(uint256-address)[]
    /**
     * @dev Default version of _isAllowedSubmitter binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     * @return True if allowed.
     */
    function _isAllowedSubmitter(uint256 id, address submitter) internal view returns (bool) {
        return _isAllowedSubmitter(_layoutStruct(), id, submitter);
    }

    // end::_isAllowedSubmitter(uint256-address)[]

    // tag::_setDisputeInfo(Storage-uint256-DisputeInfo)[]
    /**
     * @dev Argumented version of _setDisputeInfo to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param disputeId The dispute ID.
     * @param info The dispute info.
     */
    function _setDisputeInfo(Storage storage layoutStruct, uint256 disputeId, DisputeInfo memory info) internal {
        layoutStruct.disputes[disputeId] = info;
    }

    // end::_setDisputeInfo(Storage-uint256-DisputeInfo)[]

    // tag::_setDisputeInfo(uint256-DisputeInfo)[]
    /**
     * @dev Default version of _setDisputeInfo binding to the standard STORAGE_SLOT.
     * @param disputeId The dispute ID.
     * @param info The dispute info.
     */
    function _setDisputeInfo(uint256 disputeId, DisputeInfo memory info) internal {
        _setDisputeInfo(_layoutStruct(), disputeId, info);
    }

    // end::_setDisputeInfo(uint256-DisputeInfo)[]

    // tag::_getDisputeInfo(Storage-uint256)[]
    /**
     * @dev Argumented version of _getDisputeInfo to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param disputeId The dispute ID.
     * @return info The dispute info.
     */
    function _getDisputeInfo(Storage storage layoutStruct, uint256 disputeId) internal view returns (DisputeInfo memory info) {
        info = layoutStruct.disputes[disputeId];
    }

    // end::_getDisputeInfo(Storage-uint256)[]

    // tag::_getDisputeInfo(uint256)[]
    /**
     * @dev Default version of _getDisputeInfo binding to the standard STORAGE_SLOT.
     * @param disputeId The dispute ID.
     * @return info The dispute info.
     */
    function _getDisputeInfo(uint256 disputeId) internal view returns (DisputeInfo memory info) {
        return _getDisputeInfo(_layoutStruct(), disputeId);
    }

    // end::_getDisputeInfo(uint256)[]

    // tag::_getBountyIdForDispute(Storage-uint256)[]
    /**
     * @dev Argumented version of _getBountyIdForDispute to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param disputeId The dispute ID.
     * @return The bounty ID for the dispute.
     */
    function _getBountyIdForDispute(Storage storage layoutStruct, uint256 disputeId) internal view returns (uint256) {
        return layoutStruct.disputes[disputeId].bountyId;
    }

    // end::_getBountyIdForDispute(Storage-uint256)[]

    // tag::_getBountyIdForDispute(uint256)[]
    /**
     * @dev Default version of _getBountyIdForDispute binding to the standard STORAGE_SLOT.
     * @param disputeId The dispute ID.
     * @return The bounty ID for the dispute.
     */
    function _getBountyIdForDispute(uint256 disputeId) internal view returns (uint256) {
        return _getBountyIdForDispute(_layoutStruct(), disputeId);
    }

    // end::_getBountyIdForDispute(uint256)[]

    // tag::_setDisputeToBounty(Storage-uint256-uint256)[]
    /**
     * @dev Argumented version of _setDisputeToBounty (legacy) to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param disputeId The dispute ID.
     * @param bountyId The bounty ID.
     */
    // Legacy simple if needed
    function _setDisputeToBounty(Storage storage layoutStruct, uint256 disputeId, uint256 bountyId) internal {
        layoutStruct.disputes[disputeId].bountyId = bountyId;
    }

    // end::_setDisputeToBounty(Storage-uint256-uint256)[]

    // tag::_setDisputeToBounty(uint256-uint256)[]
    /**
     * @dev Default version of _setDisputeToBounty (legacy) binding to the standard STORAGE_SLOT.
     * @param disputeId The dispute ID.
     * @param bountyId The bounty ID.
     */
    function _setDisputeToBounty(uint256 disputeId, uint256 bountyId) internal {
        _setDisputeToBounty(_layoutStruct(), disputeId, bountyId);
    }

    // end::_setDisputeToBounty(uint256-uint256)[]

    // tag::_getBountyForDispute(Storage-uint256)[]
    /**
     * @dev Argumented version of _getBountyForDispute to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param disputeId The dispute ID.
     * @return The bounty ID.
     */
    function _getBountyForDispute(Storage storage layoutStruct, uint256 disputeId) internal view returns (uint256) {
        return layoutStruct.disputes[disputeId].bountyId;
    }

    // end::_getBountyForDispute(Storage-uint256)[]

    // tag::_getBountyForDispute(uint256)[]
    /**
     * @dev Default version of _getBountyForDispute binding to the standard STORAGE_SLOT.
     * @param disputeId The dispute ID.
     * @return The bounty ID.
     */
    function _getBountyForDispute(uint256 disputeId) internal view returns (uint256) {
        return _getBountyForDispute(_layoutStruct(), disputeId);
    }

    // end::_getBountyForDispute(uint256)[]

    // tag::_isSubmitterAllowed(Storage-uint256-address)[]
    /**
     * @dev Argumented version of _isSubmitterAllowed to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     * @return True if submitter is allowed.
     */
    function _isSubmitterAllowed(Storage storage layoutStruct, uint256 id, address submitter) internal view returns (bool) {
        Bounty storage b = layoutStruct.bounties[id];
        if (b.access == BountyAccess.Open) return true;
        if (submitter == b.issuer) return true;
        return layoutStruct.allowedSubmitters[id][submitter];
    }

    // end::_isSubmitterAllowed(Storage-uint256-address)[]

    // tag::_isSubmitterAllowed(uint256-address)[]
    /**
     * @dev Default version of _isSubmitterAllowed binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     * @param submitter The submitter address.
     * @return True if submitter is allowed.
     */
    function _isSubmitterAllowed(uint256 id, address submitter) internal view returns (bool) {
        return _isSubmitterAllowed(_layoutStruct(), id, submitter);
    }

    // end::_isSubmitterAllowed(uint256-address)[]

    // tag::_markClosed(Storage-uint256)[]
    /**
     * @dev Argumented version of _markClosed to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param id The bounty ID.
     */
    function _markClosed(Storage storage layoutStruct, uint256 id) internal {
        layoutStruct.bounties[id].status = BountyStatus.Closed;
    }

    // end::_markClosed(Storage-uint256)[]

    // tag::_markClosed(uint256)[]
    /**
     * @dev Default version of _markClosed binding to the standard STORAGE_SLOT.
     * @param id The bounty ID.
     */
    function _markClosed(uint256 id) internal {
        _markClosed(_layoutStruct(), id);
    }

    // end::_markClosed(uint256)[]
}
// end::BountyRepo[]
