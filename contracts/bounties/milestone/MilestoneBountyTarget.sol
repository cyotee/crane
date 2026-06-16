// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IMilestoneBounty} from "@crane/contracts/bounties/milestone/IMilestoneBounty.sol";
import {BountyRepo} from "@crane/contracts/bounties/common/BountyRepo.sol";
import {BountyCommonTarget} from "@crane/contracts/bounties/common/BountyCommonTarget.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::MilestoneBountyTarget[]
/**
 * @title MilestoneBountyTarget - Target contract implementing IMilestoneBounty.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes milestone-based bounty flows (sequential stage deliverables, per-milestone approval model) by delegating to shared helpers in BountyCommonTarget + BountyRepo.
 * @dev Follows Facet-Target-Repo. Inherits from BountyCommonTarget (which brings IBountyCommon views/funding/disputes + modifiers). Inherited by MilestoneBountyFacet.
 *      No custom tags (e.g. selector) per CENTRALLY_COMPUTED_NATSPEC_VALUES.md instruction (no entries for IMilestoneBounty symbols) - prose only.
 *      milestoneIndex in submit/approve provides per-stage semantics; currently skeleton marks closed on any approve (real will advance stages, use _recordPayout per milestone).
 */
contract MilestoneBountyTarget is BountyCommonTarget, IMilestoneBounty {
    /* ------ IMilestoneBounty ------ */

    // tag::createMilestoneBounty(string-string[]-address-uint256-uint8-address[]-uint256[])[]
    /**
     * @inheritdoc IMilestoneBounty
     * @dev Delegates record creation to inherited _createBountyRecord using BountyType.Milestone + access mapping; then adds initial funding.
     *      globalSpecUri + milestonePrdUris (per-milestone PRD/spec uris) captured at creation per interface (persisted offchain or future in Repo).
     * @custom:emits BountyCreated (via common)
     * @custom:emits BountyFunded (via common)
     */
    function createMilestoneBounty(
        string memory globalSpecUri,
        string[] memory milestonePrdUris,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId) {
        bountyId = _createBountyRecord(
            BountyRepo.BountyType.Milestone,
            funder,
            globalSpecUri,
            "",
            deadline,
            access == 1 ? BountyRepo.BountyAccess.Closed : BountyRepo.BountyAccess.Open
        );
        _addInitialFunding(bountyId, tokens, amounts);
        // milestone uris stored off-chain via uri or event in full impl
    }
    // end::createMilestoneBounty(string-string[]-address-uint256-uint8-address[]-uint256[])[]

    // tag::submitMilestone(uint256-uint256-string[])[]
    /**
     * @inheritdoc IMilestoneBounty
     * @dev Validates submitter allowance via BountyRepo (open/closed per bounty), emits via common event. Restricted per IBountyCommon rules. milestoneIndex selects stage.
     * @custom:emits DeliverableSubmitted (via common)
     */
    function submitMilestone(uint256 bountyId, uint256 milestoneIndex, string[] memory deliverableUris) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        require(BountyRepo._isSubmitterAllowed(rs, bountyId, msg.sender), "not allowed");
        emit DeliverableSubmitted(bountyId, msg.sender, deliverableUris);
    }
    // end::submitMilestone(uint256-uint256-string[])[]

    // tag::approveMilestone(uint256-uint256)[]
    /**
     * @inheritdoc IMilestoneBounty
     * @dev Restricted to issuer or owner (via MultiStepOwnableRepo). Marks bounty closed (milestoneIndex for semantics / future staged payouts; skeleton closes fully).
     * @custom:emits BountyClosed (via common)
     */
    function approveMilestone(uint256 bountyId, uint256 milestoneIndex) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(msg.sender == b.issuer || msg.sender == MultiStepOwnableRepo._owner(), "only issuer");
        BountyRepo._markClosed(rs, bountyId);
    }
    // end::approveMilestone(uint256-uint256)[]
}
// end::MilestoneBountyTarget[]
