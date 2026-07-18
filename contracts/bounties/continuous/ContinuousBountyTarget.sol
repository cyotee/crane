// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IContinuousBounty} from "@crane/contracts/bounties/continuous/IContinuousBounty.sol";
import {BountyRepo} from "@crane/contracts/bounties/common/BountyRepo.sol";
import {BountyCommonTarget} from "@crane/contracts/bounties/common/BountyCommonTarget.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::ContinuousBountyTarget[]
/**
 * @title ContinuousBountyTarget - Target contract implementing IContinuousBounty.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes continuous/recurring bounty flows (per-delivery payment model) by delegating to shared helpers in BountyCommonTarget + BountyRepo.
 * @dev Follows Facet-Target-Repo. Inherits from BountyCommonTarget (which brings IBountyCommon views/funding/disputes + modifiers). Inherited by ContinuousBountyFacet.
 *      No custom tags (e.g. selector) per CENTRALLY_COMPUTED_NATSPEC_VALUES.md instruction (no entries for IContinuousBounty symbols) - prose only.
 *      Payout on approve uses _recordPayout helper (stubbed in current skeleton).
 */
contract ContinuousBountyTarget is BountyCommonTarget, IContinuousBounty {
    /* ------ IContinuousBounty ------ */

    // tag::createContinuousBounty(string-uint256-uint256-address-uint256-uint8-address[]-uint256[])[]
    /**
     * @inheritdoc IContinuousBounty
     * @dev Delegates record creation to inherited _createBountyRecord using BountyType.Continuous + access mapping; then adds initial funding.
     *      (paymentPerDelivery + submissionTimer accepted per interface but not yet persisted in skeleton; future impl records in BountyRepo.)
     * @custom:emits BountyCreated (via common)
     */
    function createContinuousBounty(
        string memory specUri,
        uint256 paymentPerDelivery,
        uint256 submissionTimer,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId) {
        bountyId = _createBountyRecord(
            BountyRepo.BountyType.Continuous,
            funder,
            specUri,
            "",
            deadline,
            access == 1 ? BountyRepo.BountyAccess.Closed : BountyRepo.BountyAccess.Open
        );
        _addInitialFunding(bountyId, tokens, amounts);
    }

    // end::createContinuousBounty(string-uint256-uint256-address-uint256-uint8-address[]-uint256[])[]

    // tag::submitDelivery(uint256-string[])[]
    /**
     * @inheritdoc IContinuousBounty
     * @dev Validates submitter allowance via BountyRepo (open/closed per bounty), emits via common event. Restricted per IBountyCommon rules.
     * @custom:emits DeliverableSubmitted (via common)
     */
    function submitDelivery(uint256 bountyId, string[] memory deliverableUris) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        require(BountyRepo._isSubmitterAllowed(rs, bountyId, msg.sender), "not allowed");
        emit DeliverableSubmitted(bountyId, msg.sender, deliverableUris);
    }

    // end::submitDelivery(uint256-string[])[]

    // tag::approveDelivery(uint256)[]
    /**
     * @inheritdoc IContinuousBounty
     * @dev Restricted to issuer or owner (via MultiStepOwnableRepo). Triggers payout of paymentPerDelivery (stub: currently just marks closed; real will call _recordPayout).
     * @custom:emits DeliverableApproved (via common); BountyClosed potentially.
     */
    function approveDelivery(uint256 bountyId) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(msg.sender == b.issuer || msg.sender == MultiStepOwnableRepo._owner(), "only issuer");
        // In real would pay paymentPerDelivery here via _recordPayout
        BountyRepo._markClosed(rs, bountyId);
    }
    // end::approveDelivery(uint256)[]
}
// end::ContinuousBountyTarget[]
