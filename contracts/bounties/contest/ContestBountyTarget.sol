// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IContestBounty} from "@crane/contracts/bounties/contest/IContestBounty.sol";
import {BountyRepo} from "@crane/contracts/bounties/common/BountyRepo.sol";
import {BountyCommonTarget} from "@crane/contracts/bounties/common/BountyCommonTarget.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::ContestBountyTarget[]
/**
 * @title ContestBountyTarget - Target contract implementing IContestBounty.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes contest-style bounty flows (fixed prize tiers, winner assignment model) by delegating to shared helpers in BountyCommonTarget + BountyRepo.
 * @dev Follows Facet-Target-Repo. Inherits from BountyCommonTarget (which brings IBountyCommon views/funding/disputes + modifiers). Inherited by ContestBountyFacet.
 *      No custom tags (e.g. selector) per CENTRALLY_COMPUTED_NATSPEC_VALUES.md instruction (no entries for IContestBounty symbols) - prose only.
 *      assignPrizes receives winners but marks closed only in current skeleton (prize distribution handled via _recordPayout or off-chain per common).
 */
contract ContestBountyTarget is BountyCommonTarget, IContestBounty {
    /* ------ IContestBounty ------ */

    // tag::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[]
    /**
     * @inheritdoc IContestBounty
     * @dev Delegates record creation to inherited _createBountyRecord using BountyType.Contest + access mapping; then adds initial funding.
     *      prizeAmounts captured at creation per interface (distribution/assignment at assignPrizes time).
     * @custom:emits BountyCreated (via common)
     * @custom:emits BountyFunded (via common)
     */
    function createContestBounty(
        string memory specUri,
        uint256[] memory prizeAmounts,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId) {
        bountyId = _createBountyRecord(
            BountyRepo.BountyType.Contest,
            funder,
            specUri,
            "",
            deadline,
            access == 1 ? BountyRepo.BountyAccess.Closed : BountyRepo.BountyAccess.Open
        );
        _addInitialFunding(bountyId, tokens, amounts);
    }

    // end::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[]

    // tag::submitForContest(uint256-string[])[]
    /**
     * @inheritdoc IContestBounty
     * @dev Validates submitter allowance via BountyRepo (open/closed per bounty), emits via common event. Restricted per IBountyCommon rules.
     * @custom:emits DeliverableSubmitted (via common)
     */
    function submitForContest(uint256 bountyId, string[] memory deliverableUris) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        require(BountyRepo._isSubmitterAllowed(rs, bountyId, msg.sender), "not allowed");
        emit DeliverableSubmitted(bountyId, msg.sender, deliverableUris);
    }

    // end::submitForContest(uint256-string[])[]

    // tag::assignPrizes(uint256-address[])[]
    /**
     * @inheritdoc IContestBounty
     * @dev Restricted to issuer or owner (via MultiStepOwnableRepo). Marks bounty closed (winners array provided for semantics / future payout; no on-chain transfer in skeleton).
     * @custom:emits BountyClosed (via common)
     */
    function assignPrizes(uint256 bountyId, address[] memory winners) external {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(msg.sender == b.issuer || msg.sender == MultiStepOwnableRepo._owner(), "only issuer");
        BountyRepo._markClosed(rs, bountyId);
    }
    // end::assignPrizes(uint256-address[])[]
}
// end::ContestBountyTarget[]
